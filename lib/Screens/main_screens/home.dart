import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/student.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Student> students = [];
  bool isLoading = true;
  final _auth = AuthService();
  final _studentDataService = StudentDataService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _studentInfo;
  Map<String, List<dynamic>>? _semesterResults;
  double? _overallCGPA;
  String? userId;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  final Map<String, GlobalKey> _studentKeys = {};
  Map<String, bool>? _showMePreferences;
  bool _mounted = true;
  bool _isRefreshing = false;
  late ConfettiController _confettiController;
  late AnimationController _gradientAnimationController;

  @override
  void initState() {
    super.initState();

    _gradientAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();
    userId = _auth.getCurrentUserId();
    _loadInitialData();

    _scrollController.addListener(() {
      if (!mounted) return;
      final showScrollToTop = _scrollController.offset > 200;
      if (showScrollToTop != _showScrollToTop) {
        setState(() {
          _showScrollToTop = showScrollToTop;
        });
      }
    });

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      if (_searchQuery.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToMatchingStudent();
        });
      }
    });
  }

  @override
  void dispose() {
    _gradientAnimationController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _mounted = false;
    super.dispose();
  }

  Future<void> _fetchStudentShowMePreferences() async {
    if (!mounted) return;
    try {
      final batch = _studentInfo?['batchNo']?.toString();
      if (batch == null) return;

      final showMePreferences = await Future.wait(students.map((student) async {
        try {
          final studentDoc = await _firestore
              .collection('students')
              .where('studentId', isEqualTo: student.id)
              .get();

          if (studentDoc.docs.isNotEmpty) {
            return {
              student.id: studentDoc.docs.first.data()['showMe'] ?? false
            };
          }
          return {student.id: false};
        } catch (e) {
          print('Error fetching showMe for ${student.name}: $e');
          return {student.id: false};
        }
      }));

      if (!mounted) return;
      final showMeMap = showMePreferences.fold<Map<String, bool>>(
          {}, (acc, current) => acc..addAll(current.cast<String, bool>()));

      setState(() {
        _showMePreferences = showMeMap;
      });
    } catch (e) {
      print('Error in _fetchStudentShowMePreferences: $e');
    }
  }

  Future<void> _loadUserPreferences() async {
    if (!mounted) return;

    if (userId != null) {
      try {
        final userDoc =
            await _firestore.collection('students').doc(userId).get();
        if (!mounted) return;
        bool showFullName = userDoc.data()?['showMe'] ?? false;

        setState(() {
          _studentInfo ??= {};
          _studentInfo!['showMe'] = showFullName;
        });
      } catch (e) {
        print('Error fetching showMe preference: $e');
      }
    }
  }

  Future<String> _anonymizeName(String name, String studentId) {
    bool showFullName = _showMePreferences?[studentId] ?? false;

    if (showFullName) {
      return Future.value(name);
    } else {
      var nameParts = name.split(' ');
      if (nameParts.length > 1) {
        return Future.value('${nameParts[0][0]} ' +
            nameParts.sublist(1).map((part) => '*' * part.length).join(' '));
      }
      return Future.value(name);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    final hasCache = await _loadCachedData();
    if (!hasCache) {
      await _fetchStudentData();
    }

    if (_studentInfo != null) {
      print('Student info: $_studentInfo');
      final batch = _studentInfo!['batchNo']?.toString();
      if (batch != null) {
        await loadStudents(batch);
        await _fetchStudentShowMePreferences();
      }
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<bool> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentInfoString = prefs.getString('studentInfo');
      final semesterResultsString = prefs.getString('semesterResults');
      final cgpa = prefs.getDouble('overallCGPA');

      if (studentInfoString != null) {
        setState(() {
          _studentInfo = json.decode(studentInfoString);
          _semesterResults = semesterResultsString != null
              ? Map<String, List<dynamic>>.from(json
                  .decode(semesterResultsString)
                  .map(
                      (key, value) => MapEntry(key, List<dynamic>.from(value))))
              : null;
          _overallCGPA = cgpa;
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error loading cached data: $e');
      return false;
    }
  }

  Future<void> _saveDataToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_studentInfo != null) {
        await prefs.setString('studentInfo', json.encode(_studentInfo));
      }
      if (_semesterResults != null) {
        await prefs.setString('semesterResults', json.encode(_semesterResults));
      }
      if (_overallCGPA != null) {
        await prefs.setDouble('overallCGPA', _overallCGPA!);
      }
    } catch (e) {
      print('Error saving data to cache: $e');
    }
  }

  String getBatchCsvPath(String batch) {
    switch (batch) {
      case '39':
        return 'csv/studentRank39NFE.csv';
      case '61':
        return 'csv/studentRank61CSE.csv';
      case '62':
        return 'csv/studentRank62CSE.csv';
      case '63':
        return 'csv/studentRank63CSE.csv';
      case '64':
        return 'csv/studentRank64CSE.csv';
      case '5':
        return 'csv/studentRank5ITM.csv';
      default:
        throw Exception('No CSV file available for batch: $batch');
    }
  }

  Future<String> loadCsvForBatch(String batch) async {
    final String path = getBatchCsvPath(batch);
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      throw Exception('Failed to load CSV for batch $batch: $e');
    }
  }

  Future<void> loadStudents(String batch) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final String csvData = await loadCsvForBatch(batch);
      List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvData);
      csvTable.removeAt(0);

      List<Student> loadedStudents =
          csvTable.map((row) => Student.fromCsvRow(row)).toList();

      if (!mounted) return;
      setState(() {
        students = loadedStudents;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        students = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ranking data for batch $batch'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchStudentData() async {
    try {
      // Get current user's student ID from Firebase
      final userId = _auth.getCurrentUserId();
      if (userId == null) throw Exception('User not found');

      // Fetch student info from Firestore
      final userData = await _studentDataService.getUserData(userId);
      if (userData == null) throw Exception('User data not found');

      final studentId = userData['studentId'];

      // Fetch detailed student info and results
      _studentInfo = await _studentDataService.fetchStudentInfo(studentId);
      _semesterResults = await _studentDataService.fetchResults(studentId);
      _overallCGPA =
          _studentDataService.calculateOverallCGPA(_semesterResults!);

      // Save to cache
      await _saveDataToCache();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (_studentInfo == null) {
        setState(() {
          _studentInfo = null;
          _semesterResults = null;
          _overallCGPA = null;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title:
                const Text('Exit App', style: TextStyle(color: Colors.white)),
            content: const Text('Do you want to exit the app?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child:
                    const Text('No', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Yes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _scrollToMatchingStudent() {
    if (_searchQuery.isEmpty) return;

    // Find all matching students
    List<int> matchingIndices = [];

    // Check all students, including podium
    for (int i = 0; i < students.length; i++) {
      if (students[i].name.toLowerCase().contains(_searchQuery)) {
        matchingIndices.add(i);
      }
    }

    if (matchingIndices.isEmpty) return;

    // Get the first match
    int matchIndex = matchingIndices[0];
    Student matchingStudent = students[matchIndex];

    // Calculate the scroll offset based on position
    double offset;
    if (matchIndex < 3) {
      // For podium positions (0, 1, 2), scroll to top
      offset = 0;
    } else {
      double podiumHeight = 200;
      double currentUserHeight = 76;
      double spacingHeight = 20;
      double itemHeight = 72;

      offset = podiumHeight +
          currentUserHeight +
          spacingHeight +
          ((matchIndex - 3) * itemHeight);
    }

    // Perform the scroll with a slight offset for better visibility
    _scrollController
        .animateTo(
      max(0, offset - 100), // Subtract 100 to show some content above
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    )
        .then((_) {
      // After main scroll, ensure the specific item is fully visible
      if (_studentKeys[matchingStudent.id]?.currentContext != null) {
        Scrollable.ensureVisible(
          _studentKeys[matchingStudent.id]!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3, // Align towards the top third of the screen
        );
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  Future<Widget> _buildCurrentUserRank() async {
    String? currentUserId = _studentInfo?['studentId'] as String? ?? userId;
    if (currentUserId == null) return const SizedBox.shrink();

    // Find current user's rank
    int userIndex =
        students.indexWhere((student) => student.id == currentUserId);
    if (userIndex < 0 || userIndex < 3) return const SizedBox.shrink();

    final student = students[userIndex];
    String displayName = await _anonymizeName(student.name, student.id);

    // Use the existing animation controller (initialized in initState)
    return AnimatedBuilder(
      animation: _gradientAnimationController,
      builder: (context, child) {
        final tertiaryColor = Theme.of(context).colorScheme.tertiary;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tertiaryColor.withOpacity(0.15),
                Colors.white.withOpacity(0.4),
                tertiaryColor.withOpacity(0.15),
              ],
              stops: [0, _gradientAnimationController.value, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tertiaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Row contents
              Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${userIndex + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.2),
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Your Position',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    student.cgpa.toStringAsFixed(2),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // 🎉 Confetti inside the card
              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: true,
                    emissionFrequency: 0.08,
                    numberOfParticles: 6,
                    maxBlastForce: 8,
                    minBlastForce: 4,
                    gravity: 0.3,
                    colors: const [
                      Colors.amber,
                      Colors.purple,
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Future<Widget> _buildPodiumItem(Student student, int rank) async {
  //   Color getMedalColor(int rank) {
  //     switch (rank) {
  //       case 1:
  //         return const Color(0xFFFFD700); // Gold
  //       case 2:
  //         return const Color(0xFFC0C0C0); // Silver
  //       case 3:
  //         return const Color(0xFFCD7F32); // Bronze
  //       default:
  //         return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  //     }
  //   }

  //   String displayName = await _anonymizeName(student.name, student.id);
  //   final bool isMatch = _searchQuery.isNotEmpty &&
  //       student.name.toLowerCase().contains(_searchQuery);
  //   final bool isCurrentUser =
  //       student.id == (_studentInfo?['studentId'] as String? ?? userId);

  //   return Container(
  //     key: _studentKeys.putIfAbsent(student.id, () => GlobalKey()),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment: MainAxisAlignment.end,
  //       children: [
  //         if (rank == 1)
  //           Transform.translate(
  //             offset: const Offset(0, 10),
  //             child: Image.asset(
  //               'assets/crown.png',
  //               width: 50,
  //               height: 50,
  //               fit: BoxFit.contain,
  //             ),
  //           ),
  //         Stack(
  //           alignment: Alignment.center,
  //           children: [
  //             if (isCurrentUser)
  //               Container(
  //                 width: rank == 1 ? 100 : 80,
  //                 height: rank == 1 ? 100 : 80,
  //                 decoration: BoxDecoration(
  //                   shape: BoxShape.circle,
  //                   boxShadow: [
  //                     for (var i = 0; i < 3; i++)
  //                       BoxShadow(
  //                         color: Theme.of(context)
  //                             .colorScheme
  //                             .tertiary
  //                             .withOpacity(0.3 - i * 0.1),
  //                         spreadRadius: (i + 1) * 4,
  //                         blurRadius: (i + 1) * 4,
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             CircleAvatar(
  //               radius: rank == 1 ? 40 : 30,
  //               backgroundColor: isMatch
  //                   ? Theme.of(context).colorScheme.primary
  //                   : isCurrentUser
  //                       ? Theme.of(context).colorScheme.tertiary
  //                       : getMedalColor(rank),
  //               child: Text(
  //                 displayName[0].toUpperCase(),
  //                 style: TextStyle(
  //                   color: isMatch || isCurrentUser
  //                       ? Theme.of(context).colorScheme.onPrimary
  //                       : Theme.of(context).colorScheme.onSurface,
  //                   fontSize: rank == 1 ? 24 : 20,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           displayName,
  //           style: TextStyle(
  //             color: isMatch
  //                 ? Theme.of(context).colorScheme.primary
  //                 : isCurrentUser
  //                     ? Theme.of(context).colorScheme.tertiary
  //                     : Theme.of(context).colorScheme.onSurface,
  //             fontSize: rank == 1 ? 16 : 14,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         Text(
  //           student.cgpa.toStringAsFixed(2),
  //           style: TextStyle(
  //             color: isMatch
  //                 ? Theme.of(context).colorScheme.primary
  //                 : isCurrentUser
  //                     ? Theme.of(context).colorScheme.tertiary
  //                     : getMedalColor(rank),
  //             fontSize: rank == 1 ? 16 : 14,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<Widget> _buildListItem(
      Student student, int rank, bool isCurrentUser) async {
    String displayName = await _anonymizeName(student.name, student.id);
    final bool isMatch = _searchQuery.isNotEmpty &&
        student.name.toLowerCase().contains(_searchQuery);

    return Container(
      key: _studentKeys.putIfAbsent(student.id, () => GlobalKey()),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isMatch
            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
            : isCurrentUser
                ? Theme.of(context).colorScheme.tertiary.withOpacity(0.15)
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isMatch
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : isCurrentUser
                ? Border.all(
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                    width: 1,
                  )
                : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$rank',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: isMatch
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            child: Text(
              displayName[0].toUpperCase(),
              style: TextStyle(
                color: isMatch
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                color: isMatch
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            student.cgpa.toStringAsFixed(2),
            style: TextStyle(
              color: isMatch
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final hasCache = await _loadCachedData();
      if (!hasCache) {
        await _fetchStudentData();
      }

      if (_studentInfo != null) {
        final batch = _studentInfo!['batchNo']?.toString();
        if (batch != null) {
          await loadStudents(batch);
          await _fetchStudentShowMePreferences();
        } else {
          // If batch is null, make sure students list is empty
          setState(() {
            students = [];
          });
        }
      }
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return; // Prevent multiple refreshes

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchStudentData();
      if (_studentInfo != null) {
        final batch = _studentInfo!['batchNo']?.toString();
        if (batch != null) {
          await loadStudents(batch);
          await _fetchStudentShowMePreferences();
        } else {
          setState(() {
            students = [];
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildPodiumColumn(Student student, int rank) {
    // Dynamic sizing based on rank - reduced heights to prevent overflow
    final double height = rank == 1
        ? 120
        : rank == 2
            ? 100
            : 80;
    final double avatarRadius = rank == 1
        ? 32
        : rank == 2
            ? 28
            : 24;
    final double fontSize = rank == 1
        ? 20
        : rank == 2
            ? 18
            : 14;

    // Medal colors with richer gradients
    final List<Color> medalGradient = rank == 1
        ? [const Color(0xFFFFDD00), const Color(0xFFFFC700)]
        : rank == 2
            ? [const Color(0xFF00CFFF), const Color(0xFF0099CC)]
            : [const Color(0xFFFF7F50), const Color(0xFFFF5722)];

    // Trophy icons by rank
    final IconData trophyIcon = rank == 1
        ? Icons.emoji_events
        : rank == 2
            ? Icons.workspace_premium
            : Icons.military_tech;

    return FutureBuilder<String>(
      future: _anonymizeName(student.name, student.id),
      builder: (context, snapshot) {
        final name = snapshot.data ?? '...';

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Crown for first place only
            if (rank == 1)
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [Color(0xFFFFD700), Color(0xFFFFA000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Image.asset('assets/crown.png', width: 22, height: 22),
              ),

            // Trophy/Medal icon
            Icon(
              trophyIcon,
              size: rank == 1 ? 26 : 22,
              color: medalGradient[0],
            ),

            const SizedBox(height: 2),

            // Avatar with glowing effect
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: medalGradient[0].withOpacity(0.7),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey[850],
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: medalGradient[0],
                      width: rank == 1 ? 3 : 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: avatarRadius - (rank == 1 ? 3 : 2),
                    backgroundColor: Colors.transparent,
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Student name
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 14 : 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // CGPA with medal color
            Text(
              student.cgpa.toStringAsFixed(2),
              style: TextStyle(
                color: medalGradient[0],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 4),

            // Podium column with animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, double value, child) {
                return Container(
                  width: 60,
                  height: height * value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medalGradient[0],
                        medalGradient[1],
                        Colors.black26,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: medalGradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: rank == 1 ? 16 : 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        floatingActionButton: AnimatedOpacity(
          opacity: _showScrollToTop && !_isSearching ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward, color: Colors.yellowAccent),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            elevation: 1,
          ),
        ),
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                  ),
                )
              : Column(
                  children: [
                    Text(
                      'DIU Leaderboard',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_studentInfo != null &&
                        _studentInfo!['batchNo'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Batch ${_studentInfo!['batchNo'].toString()}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
          centerTitle: true,
          // actions: [
          //   IconButton(
          //     icon: Icon(_isSearching ? Icons.clear : Icons.search),
          //     onPressed: _toggleSearch,
          //     color: Colors.white,
          //   ),
          // ],
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Theme.of(context).colorScheme.tertiary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: students.isEmpty
                      ? ListView(
                          // Replace SingleChildScrollView with ListView for empty state
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.7, // Add height to ensure scrollable
                              child: _buildEmptyStateView(),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Top 3 Podium
                            if (students.length >= 3)
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 300,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildPodiumColumn(students[1], 2),
                                          _buildPodiumColumn(students[0], 1),
                                          _buildPodiumColumn(students[2], 3),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Current User's Rank
                            SliverToBoxAdapter(
                              child: FutureBuilder<Widget>(
                                future: _buildCurrentUserRank(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return const Icon(Icons.error);
                                  } else {
                                    return snapshot.data ??
                                        const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 20),
                            ),

                            // Remaining Rankings
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final student = students[index + 3];
                                  final isCurrentUser = student.id == userId;
                                  return FutureBuilder<Widget>(
                                    future: _buildListItem(
                                        student, index + 4, isCurrentUser),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return const Icon(Icons.error);
                                      } else {
                                        return snapshot.data ??
                                            const SizedBox.shrink();
                                      }
                                    },
                                  );
                                },
                                childCount: students.length > 3
                                    ? students.length - 3
                                    : 0,
                              ),
                            ),
                          ],
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/jsons/portal_down.json',
          ),
          const SizedBox(height: 20),
          Text(
            'No Ranking Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We couldn\'t find ranking data for your batch. Please try refreshing or contact support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _handleRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
