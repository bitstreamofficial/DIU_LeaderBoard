import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_first/Screens/nav/main_navigation.dart';
import 'package:flutter_first/services/auth_service.dart';
import 'package:flutter_first/Screens/main_screens/home.dart';
import 'package:logger/logger.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:flutter_first/services/student_data_service.dart';

class SignupProgressPage extends StatefulWidget {
  final String studentId;
  final String email;
  final String password;

  const SignupProgressPage({
    Key? key,
    required this.studentId,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  _SignupProgressPageState createState() => _SignupProgressPageState();
}

class _SignupProgressPageState extends State<SignupProgressPage> {
  final _studentDataService = StudentDataService();
  final _auth = AuthService();
  final _logger = Logger();
  final int _verificationTimeout = 300; 

  SignupStep _currentStep = SignupStep.fetchingStudentInfo;
  Map<String, dynamic>? _studentInfo;
  Map<String, List<dynamic>> _semesterResults = {};
  double? _overallCGPA;
  bool isEmailVerified = false;
  String? _errorMessage;
  String? _userId;
  bool _isVerified = false;
  int _resendCounter = 0;
  int _verificationTimeLeft = 300;
  Timer? _resendTimer;
  Timer? _verificationCheckTimer;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  @override
  void dispose() {
    _cleanupTimers();
    super.dispose();
  }

  void _cleanupTimers() {
    _resendTimer?.cancel();
    _verificationCheckTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _startProcessing() async {
    if (!await _checkConnectivity()) {
      _handleError(
          'No internet connection. Please check your connection and try again.');
      return;
    }

    try {
      setState(() {
        _currentStep = SignupStep.fetchingStudentInfo;
        _errorMessage = null;
      });

      // Fetch student info
      _studentInfo =
          await _studentDataService.fetchStudentInfo(widget.studentId);
      if (!mounted) return;

      setState(() => _currentStep = SignupStep.fetchingResults);
      _semesterResults =
          await _studentDataService.fetchResults(widget.studentId);
      if (!mounted) return;

      setState(() {
        _currentStep = SignupStep.calculatingCGPA;
        _overallCGPA =
            _studentDataService.calculateOverallCGPA(_semesterResults);
      });
    } catch (e) {
      _handleError('Error during data fetching: ${e.toString()}');
    }
  }

  void _handleError(String error) {
    _logger.e('Error in SignupProgressPage: $error');
    if (mounted) {
      setState(() {
        _errorMessage = error;
        _currentStep = SignupStep.error;
      });
    }
  }

  Future<void> _retryProcess() async {
    setState(() {
      _currentStep = SignupStep.fetchingStudentInfo;
      _errorMessage = null;
      _semesterResults.clear();
      _overallCGPA = null;
    });
    await _startProcessing();
  }

  Future<void> _confirmAndCreateAccount() async {
    if (!await _checkConnectivity()) {
      _handleError('No internet connection');
      return;
    }

    try {
      setState(() {
        _currentStep = SignupStep.creatingAccount;
        _errorMessage = null;
      });

      // Create Firebase account
      final user = await _auth.createUserWithEmailAndPassword(
        widget.email,
        widget.password,
        context,
      );

      if (user == null) throw 'Failed to create account';
      _userId = user.uid;

      setState(() => _currentStep = SignupStep.storingData);

      // Store user data in Firestore using a transaction
      await _studentDataService.storeUserData(
        userId: _userId!,
        studentId: widget.studentId,
        email: widget.email,
        studentInfo: _studentInfo!,
        cgpa: _overallCGPA!,
      );

      // Send verification email
      await _auth.sendEmailVerification(context);
      _startVerificationCheck();
      _startResendCounter();
      _startVerificationTimeout();

      setState(() {
        _currentStep = SignupStep.awaitingVerification;
      });
    } catch (e) {
      if (_userId != null) {
        try {
          await _auth.deleteUser();
        } catch (deleteError) {
          _logger.e('Error deleting user: $deleteError');
        }
      }
      _handleError(e.toString());
    }
  }

  void _startVerificationTimeout() {
    _timeoutTimer?.cancel();
    _verificationTimeLeft = _verificationTimeout;
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_verificationTimeLeft > 0) {
          _verificationTimeLeft--;
        } else {
          _handleError('Email verification timeout. Please try again.');
          timer.cancel();
        }
      });
    });
  }

  void _startResendCounter() {
    setState(() => _resendCounter = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendCounter > 0) {
          _resendCounter--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _startVerificationCheck() {
    _verificationCheckTimer?.cancel();
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => checkEmailVerified(),
    );
  }

  Future<void> checkEmailVerified() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final verified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      if (mounted && verified) {
        setState(() {
          isEmailVerified = true;
          _isVerified = true;
          _currentStep = SignupStep.completed;
        });
        _cleanupTimers();
      }
    } catch (e) {
      _logger.e('Error checking email verification: $e');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCounter > 0) return;

    try {
      await _auth.sendEmailVerification(context);
      _startResendCounter();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending verification email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {}
  }

  Widget _buildTimelineTile(SignupStep step, String title,
      {bool isFirst = false, bool isLast = false}) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep.index > step.index ||
        (_currentStep == SignupStep.completed && step == SignupStep.completed);

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(
        color: isCompleted ? Colors.green : Colors.grey,
      ),
      afterLineStyle: LineStyle(
        color: isCompleted ? Colors.green : Colors.grey,
      ),
      indicatorStyle: IndicatorStyle(
        width: 30,
        height: 30,
        indicator: Container(
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                    ? Colors.orange
                    : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : isActive
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : null,
        ),
      ),
      endChild: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey,
                fontSize: 16,
              ),
            ),
            if (isActive && _errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    if (_currentStep != SignupStep.calculatingCGPA || _studentInfo == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Name',
              value: _studentInfo!['studentName'] ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.badge,
              label: 'Student ID',
              value: _studentInfo!['studentId'] ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.school,
              label: 'Program',
              value: _studentInfo!['progShortName'] ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.groups,
              label: 'Batch',
              value: '${_studentInfo!['batchNo'] ?? 'N/A'}',
            ),
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: widget.email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_currentStep != SignupStep.calculatingCGPA ||
        _semesterResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Academic Performance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Overall CGPA: ${_overallCGPA?.toStringAsFixed(2) ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _semesterResults.length,
            itemBuilder: (context, index) {
              String semester = _semesterResults.keys.elementAt(index);
              List<dynamic> results = _semesterResults[semester] ?? [];

              if (results.isNotEmpty) {
                var firstResult = results[0] as Map<String, dynamic>;
                var semesterName = firstResult['semesterName'];
                var semesterYear = firstResult['semesterYear'];
                var semesterCGPA = firstResult['cgpa']?.toString() ?? 'N/A';

                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(255, 89, 86, 86)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$semesterName $semesterYear',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Semester CGPA',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                semesterCGPA,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: results.length,
                            itemBuilder: (context, idx) {
                              var course = results[idx] as Map<String, dynamic>;
                              String grade = course['gradeLetter'] ?? 'N/A';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: idx != results.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course['courseTitle'] ??
                                                'Unknown Course',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              course['customCourseId'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Credits',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '${course['totalCredit']?.toString() ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getGradeColor(grade)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Grade',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              grade,
                                              style: TextStyle(
                                                color: _getGradeColor(grade),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retryProcess,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _confirmAndCreateAccount();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return Colors.green.shade700;
      case 'A':
        return Colors.green.shade600;
      case 'A-':
        return Colors.green.shade500;
      case 'B+':
        return Colors.blue.shade600;
      case 'B':
        return Colors.blue.shade500;
      case 'B-':
        return Colors.blue.shade400;
      case 'C+':
        return Colors.orange.shade600;
      case 'C':
        return Colors.orange.shade500;
      case 'D':
        return Colors.red.shade500;
      case 'F':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildVerificationSection() {
    // Only show verification section when awaiting verification
    if (_currentStep == SignupStep.awaitingVerification) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                _isVerified ? Icons.check_circle_outline : Icons.mail_outline,
                color: _isVerified ? Colors.green : Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _isVerified ? 'Email Verified!' : 'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isVerified
                    ? 'Your account setup is complete'
                    : 'Please check your email and click the verification link',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _resendCounter > 0 ? null : _resendVerificationEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _resendCounter > 0
                            ? 'Resend Email (${_resendCounter}s)'
                            : 'Resend Verification Email',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for verification...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (_currentStep == SignupStep.completed) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                _isVerified ? Icons.check_circle_outline : Icons.mail_outline,
                color: _isVerified ? Colors.green : Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _isVerified ? 'Email Verified!' : 'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isVerified
                    ? 'Your account setup is complete'
                    : 'Please check your email and click the verification link',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigation(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Homepage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink(); // Fallback widget for other states
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account Setup'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTimelineTile(
                        SignupStep.fetchingStudentInfo,
                        'Fetching Student Information...',
                        isFirst: true,
                      ),
                      _buildTimelineTile(
                        SignupStep.fetchingResults,
                        'Fetching Academic Results...',
                      ),
                      _buildTimelineTile(
                        SignupStep.calculatingCGPA,
                        'Waiting For Your Verification',
                      ),
                      _buildTimelineTile(
                        SignupStep.creatingAccount,
                        'Creating Account...',
                      ),
                      _buildTimelineTile(
                        SignupStep.storingData,
                        'Storing Information...',
                      ),
                      _buildTimelineTile(
                        SignupStep.awaitingVerification,
                        'Email Verification...',
                      ),
                      _buildTimelineTile(
                        SignupStep.completed,
                        'Setup Complete!',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                _buildStudentInfoSection(),
                _buildResultsSection(),
                _buildVerificationSection(),
              ],
            ),
            // if (_isLoading)
            //   Container(
            //     color: Colors.black.withOpacity(0.5),
            //     child: const Center(
            //       child: CircularProgressIndicator(),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Future<bool> _handleBackPress() async {
    if (_currentStep.index >= SignupStep.creatingAccount.index) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Setup?'),
          content:
              const Text('This will cancel your account creation. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldPop ?? false) {
        _cleanupTimers();
        if (_userId != null) {
          try {
            await _auth.deleteUser();
          } catch (e) {
            _logger.e('Error deleting user during cancellation: $e');
          }
        }
      }
      return shouldPop ?? false;
    }
    return true;
  }
}

enum SignupStep {
  fetchingStudentInfo,
  fetchingResults,
  calculatingCGPA,
  creatingAccount,
  storingData,
  awaitingVerification,
  completed,
  error,
}
