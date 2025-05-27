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

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstStudentIdController =
      TextEditingController();
  final TextEditingController _lastStudentIdController =
      TextEditingController();

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
    _firstStudentIdController.dispose();
    _lastStudentIdController.dispose();
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

  Future<String> _anonymizeName(String name, String studentId, int rank) {
    bool showFullName = _showMePreferences?[studentId] ?? false;

    // Show full name if preference is set or rank is 3 or less
    if (showFullName || rank <= 3) {
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

  // String getBatchCsvPath(String batch) {
  //   switch (batch) {
  //     case '39':
  //       return 'csv/studentRank39NFE.csv';
  //     case '61':
  //       return 'csv/studentRank61CSE.csv';
  //     case '62':
  //       return 'csv/studentRank62CSE.csv';
  //     case '63':
  //       return 'csv/studentRank63CSE.csv';
  //     case '64':
  //       return 'csv/studentRank64CSE.csv';
  //     case '5':
  //       return 'csv/studentRank5ITM.csv';
  //     default:
  //       throw Exception('No CSV file available for batch: $batch');
  //   }
  // }

  // Future<String> loadCsvForBatch(String batch) async {
  //   final String path = getBatchCsvPath(batch);
  //   try {
  //     return await rootBundle.loadString(path);
  //   } catch (e) {
  //     throw Exception('Failed to load CSV for batch $batch: $e');
  //   }
  // }

  // Future<void> loadStudents(String batch) async {
  //   if (!mounted) return;
  //   setState(() {
  //     isLoading = true;
  //   });

  //   try {
  //     final String csvData = await loadCsvForBatch(batch);
  //     List<List<dynamic>> csvTable =
  //         const CsvToListConverter().convert(csvData);
  //     csvTable.removeAt(0);

  //     List<Student> loadedStudents =
  //         csvTable.map((row) => Student.fromCsvRow(row)).toList();

  //     if (!mounted) return;
  //     setState(() {
  //       students = loadedStudents;
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     print('Error loading students: $e');
  //     if (!mounted) return;
  //     setState(() {
  //       isLoading = false;
  //       students = [];
  //     });

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error loading ranking data for batch $batch'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  String _getFirestoreDocumentIdForBatch(String batch) {
    switch (batch) {
      case '39':
        return 'studentRank39NFE';
      case '61':
        return 'studentRank61CSE';
      case '62':
        return 'studentRank62CSE';
      case '63':
        return 'studentRank63CSE';
      case '64':
        return 'studentRank64CSE';
      case '5':
        return 'studentRank5ITM';
      case '8':
        return 'studentRank8ITM';
      case '10':
        return 'studentRank10ITM';
      case '11':
        return 'studentRank11ITM';
      case '12':
        return 'studentRank12ITM';
      default:
        // Fallback or throw an error if the batch mapping is unknown
        // You might want to derive this more dynamically if possible,
        // e.g., if _studentInfo contains program/department info.
        print(
            'Warning: Unknown batch mapping for Firestore document ID: $batch');
        return 'studentRank${batch}UNKNOWN'; // Or handle as an error
    }
  }

  Future<void> loadStudents(String batch) async {
    if (!_mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final String documentId = _getFirestoreDocumentIdForBatch(batch);
      if (documentId.endsWith('UNKNOWN')) {
        throw Exception(
            'Could not determine Firestore document for batch: $batch');
      }

      final DocumentSnapshot docSnapshot =
          await _firestore.collection('ranking_data').doc(documentId).get();

      if (!_mounted) return;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        // The student rankings are in a field named 'rankings' which is a List
        final List<dynamic>? rankingsData = data['rankings'] as List<dynamic>?;

        if (rankingsData != null) {
          List<Student> loadedStudents = rankingsData
              .map((studentData) =>
                  Student.fromMap(studentData as Map<String, dynamic>))
              .toList();

          // Optional: Sort students by rank if not already sorted in Firestore
          // loadedStudents.sort((a, b) => a.rank.compareTo(b.rank));

          setState(() {
            students = loadedStudents;
          });
        } else {
          print(
              'Error: "rankings" field is missing or not a list in document $documentId');
          students = []; // Set to empty list if no ranking data
        }
      } else {
        print(
            'Error: Document $documentId does not exist in ranking_data collection.');
        students = []; // Set to empty list if document not found
      }
    } catch (e) {
      print('Error loading students from Firestore: $e');
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error loading ranking data for batch $batch from Firestore.'),
            backgroundColor: Colors.red,
          ),
        );
        students = []; // Clear students on error
      }
    } finally {
      if (_mounted) {
        setState(() {
          isLoading = false;
        });
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
    String displayName =
        await _anonymizeName(student.name, student.id, student.rank);

    // Use the existing animation controller (initialized in initState)
    return AnimatedBuilder(
      animation: _gradientAnimationController,
      builder: (context, child) {
        final tertiaryColor = Colors.deepPurpleAccent;
        final secondaryColor = Colors.purpleAccent;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            // Ensure opacity is clamped to valid range
            final safeOpacity = value.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, (1 - value) * 50),
              child: Opacity(
                opacity: safeOpacity,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // gradient: LinearGradient(
                    //   colors: [
                    //     tertiaryColor.withOpacity(0.7),
                    //     const Color.fromARGB(255, 150, 40, 40).withOpacity(0.8),
                    //     secondaryColor.withOpacity(0.7),
                    //   ],
                    //   stops: [0, _gradientAnimationController.value, 1],
                    //   begin: Alignment.topLeft,
                    //   end: Alignment.bottomRight,
                    // ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: tertiaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: tertiaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shimmering effect layer
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            // Calculate shimmer position based on animation value
                            // This will make it move only horizontally from left to right
                            final shimmerProgress =
                                (_gradientAnimationController.value * 3) % 2.0;
                            final xPosition = -1.5 + shimmerProgress;

                            return LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              // Keep alignment strictly horizontal
                              begin: Alignment(xPosition, 0.0),
                              end: Alignment(xPosition + 1.0, 0.0),
                              tileMode: TileMode.clamp,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      // Row contents
                      Row(
                        children: [
                          // Position number with pulsing animation
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.8, end: 1.2),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeInOut,
                            builder: (context, scale, _) {
                              return AnimatedBuilder(
                                animation: _gradientAnimationController,
                                builder: (context, _) {
                                  return Transform.scale(
                                    scale: 1.0 +
                                        (scale - 1.0) *
                                            _gradientAnimationController.value,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            tertiaryColor,
                                            secondaryColor,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                tertiaryColor.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${userIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 16),

                          // Avatar with hover effect
                          MouseRegion(
                            onEnter: (_) => _confettiController.play(),
                            onExit: (_) => _confettiController.stop(),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, _) {
                                return Transform.scale(
                                  scale: 0.8 + (value * 0.2),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          Colors.purpleAccent,
                                          Colors.deepPurpleAccent,
                                          Colors.blueAccent,
                                          Colors.purpleAccent,
                                        ],
                                        transform: GradientRotation(
                                            _gradientAnimationController.value *
                                                2 *
                                                pi),
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          Colors.deepPurple.withOpacity(0.9),
                                      child: Text(
                                        displayName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // User info with slide-in animation
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Your Position',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // CGPA with glowing effect
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.elasticOut,
                            builder: (context, value, _) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        tertiaryColor.withOpacity(0.7),
                                        secondaryColor.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: tertiaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    student.cgpa.toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Confetti effect
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirectionality: BlastDirectionality.explosive,
                            shouldLoop: false,
                            emissionFrequency: 0.08,
                            numberOfParticles: 12,
                            maxBlastForce: 10,
                            minBlastForce: 5,
                            gravity: 0.2,
                            particleDrag: 0.05,
                            colors: const [
                              Colors.amber,
                              Colors.purpleAccent,
                              Colors.deepPurpleAccent,
                              Colors.white,
                              Colors.pinkAccent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

  Future<Widget> _buildListItem(Student student, int rank, bool isCurrentUser,
      dynamic searchQuery) async {
    String displayName =
        await _anonymizeName(student.name, student.id, student.rank);
    final bool isMatch = searchQuery.isNotEmpty &&
        student.name.toLowerCase().contains(searchQuery);

// Special styling for students with CGPA >= 3.90
    final bool isSpecialRank = student.cgpa >= 3.90;

    // Generate a gradient for top performers
    List<Color> getGradientColors() {
      if (isSpecialRank) {
        // Consistent gradient for all students with CGPA >= 3.90
        return [
          Colors.deepPurpleAccent
              .withOpacity(0.75), // Feel free to adjust these colors
          Colors.lightBlueAccent.withOpacity(0.75),
        ];
      }
      return []; // Fallback, though not strictly needed if called only when isSpecialRank is true
    }

    return InkWell(
      onTap: () {
        // Show more details when tapped

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The student has choose to hide thier name or not registered yet!',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        key: _studentKeys.putIfAbsent(student.id, () => GlobalKey()),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSpecialRank
              ? LinearGradient(
                  colors: getGradientColors(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSpecialRank
              ? null
              : isMatch
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : isCurrentUser
                      ? Theme.of(context).colorScheme.tertiary.withOpacity(0.15)
                      : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(isSpecialRank ? 16 : 12),
          boxShadow: isSpecialRank
              ? [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
          border: isMatch
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : isCurrentUser
                  ? Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withOpacity(0.3),
                      width: 1,
                    )
                  : isSpecialRank
                      ? Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1.5,
                        )
                      : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSpecialRank
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
                    : null,
                boxShadow: isSpecialRank
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isSpecialRank ? 18 : 16,
                  fontWeight: isSpecialRank ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: isSpecialRank ? 22 : 20,
              backgroundColor: isSpecialRank
                  ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                  : isMatch
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.2)
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.2),
              child: Text(
                displayName[0].toUpperCase(),
                style: TextStyle(
                  color: isSpecialRank
                      ? Theme.of(context).colorScheme.onSurface
                      : isMatch
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  fontSize: isSpecialRank ? 16 : 14,
                  fontWeight:
                      isSpecialRank ? FontWeight.bold : FontWeight.normal,
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
                      color: isSpecialRank
                          ? Theme.of(context).colorScheme.onSurface
                          : isMatch
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                      fontSize: isSpecialRank ? 17 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isSpecialRank)
                    Text(
                      'Top performer',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSpecialRank
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.cgpa.toStringAsFixed(2),
                style: TextStyle(
                  color: isSpecialRank
                      ? Theme.of(context).colorScheme.onSurface
                      : isMatch
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                  fontSize: isSpecialRank ? 17 : 16,
                  fontWeight: isSpecialRank ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Future<void> _loadInitialData() async {
  //   if (!_mounted) return;
  //   setState(() {
  //     isLoading = true;
  //   });

  //   try {
  //     final hasCache = await _loadCachedData(); // You might want to reconsider caching strategy
  //                                            // if Firestore is the source of truth.
  //     if (!hasCache) {
  //       await _fetchStudentData(); // This presumably fetches _studentInfo
  //     }

  //     if (_studentInfo != null) {
  //       final batch = _studentInfo!['batchNo']?.toString();
  //       if (batch != null) {
  //         await loadStudents(batch); // This will now call the Firestore version
  //         await _fetchStudentShowMePreferences(); // This seems okay
  //       } else {
  //         setState(() {
  //           students = [];
  //         });
  //       }
  //     } else {
  //        // If _studentInfo is null, perhaps there's no batch to load.
  //        print("Student info is null, cannot determine batch for loading ranks.");
  //        students = [];
  //     }
  //   } catch (e) {
  //     print('Error loading initial data: $e');
  //     students = [];
  //   } finally {
  //     if (!_mounted) return;
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> _loadInitialData() async {
    if (!_mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final hasCache =
          await _loadCachedData(); // You might want to reconsider caching strategy
      // if Firestore is the source of truth.
      if (!hasCache) {
        await _fetchStudentData(); // This presumably fetches _studentInfo
      }

      if (_studentInfo != null) {
        final batch = _studentInfo!['batchNo']?.toString();
        if (batch != null) {
          await loadStudents(batch); // This will now call the Firestore version
          await _fetchStudentShowMePreferences(); // This seems okay
        } else {
          setState(() {
            students = [];
          });
        }
      } else {
        // If _studentInfo is null, perhaps there's no batch to load.
        print(
            "Student info is null, cannot determine batch for loading ranks.");
        students = [];
      }
    } catch (e) {
      print('Error loading initial data: $e');
      students = [];
    } finally {
      if (!_mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> _handleRefresh() async {
  //   if (_isRefreshing) return; // Prevent multiple refreshes

  //   setState(() {
  //     _isRefreshing = true;
  //   });

  //   try {
  //     await _fetchStudentData();
  //     if (_studentInfo != null) {
  //       final batch = _studentInfo!['batchNo']?.toString();
  //       if (batch != null) {
  //         await loadStudents(batch);
  //         await _fetchStudentShowMePreferences();
  //       } else {
  //         setState(() {
  //           students = [];
  //         });
  //       }
  //     }

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Data refreshed successfully'),
  //           backgroundColor: Colors.green,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error refreshing data: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Failed to refresh data'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isRefreshing = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchStudentData(); // Refreshes _studentInfo
      if (_studentInfo != null) {
        final batch = _studentInfo!['batchNo']?.toString();
        if (batch != null) {
          await loadStudents(batch); // Firestore version
          await _fetchStudentShowMePreferences();
        } else {
          setState(() {
            students = [];
          });
        }
      } else {
        students = [];
      }
      // ... (rest of your refresh logic)
    } catch (e) {
      // ...
    } finally {
      // ...
    }
  }

  Future<void> _submitBatchIds() async {
    if (_formKey.currentState?.validate() ?? false) {
      final firstId = _firstStudentIdController.text.trim();
      final lastId = _lastStudentIdController.text.trim();
      final batchNumber = _studentInfo?['batchNo']?.toString();
      final submittedByUserId = userId; // Current logged-in user's ID

      // Show a loading indicator or disable the button
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitting batch IDs...'),
          backgroundColor: Colors.blue,
        ),
      );

      try {
        await _firestore.collection('batch_id_submissions').add({
          'firstStudentId': firstId,
          'lastStudentId': lastId,
          'batchNo': batchNumber,
          'submittedByUserId': submittedByUserId,
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'pending', // Initial status
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch IDs submitted successfully! Thank you.'),
            backgroundColor: Colors.green,
          ),
        );
        _firstStudentIdController.clear();
        _lastStudentIdController.clear();
      } catch (e) {
        print('Error submitting batch IDs: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit batch IDs. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
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
      future: _anonymizeName(student.name, student.id, student.rank),
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
                // child: Image.asset('assets/crown.png', width: 22, height: 22),
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

            SizedBox(
              height: 5,
            ),

            // Student name
            Text(
              name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 12 : 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // CGPA with medal color
            Text(
              student.cgpa.toStringAsFixed(2),
              style: TextStyle(
                color: medalGradient[0],
                fontWeight: FontWeight.w900,
                fontSize: 14,
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
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight),
                                  alignment: Alignment.center,
                                  child: _buildEmptyStateView(),
                                ),
                              ],
                            );
                          },
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
                                    future: _buildListItem(student, index + 4,
                                        isCurrentUser, _searchQuery),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animation Container with background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Lottie.asset(
                'assets/jsons/portal_down.json',
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.2,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),

            // Main heading
            Text(
              'No Ranking Data Available',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'We couldn\'t find ranking data for your batch. Please try refreshing or help us add your batch information.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(height: 28),

            // Refresh Button
            Container(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isRefreshing ? null : _handleRefresh,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                  shadowColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Divider with improved styling
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Help section card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Help icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Help title
                  Text(
                    'Help us add your batch!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Help description
                  Text(
                    'If you know the first and last student IDs of your batch, please submit them below. This will help us add support for your batch faster.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstStudentIdController,
                          decoration: InputDecoration(
                            labelText: 'First Student ID',
                            hintText: 'e.g., 221-15-1000',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.3),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter the first student ID';
                            return null;
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _lastStudentIdController,
                          decoration: InputDecoration(
                            labelText: 'Last Student ID',
                            hintText: 'e.g., 221-15-1200',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.3),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter the last student ID';
                            return null;
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        Container(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _submitBatchIds,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Submit Batch IDs'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                              elevation: 2,
                              shadowColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
