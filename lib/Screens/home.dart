// lib/home.dart
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';
import '../services/auth_service.dart';
import '../services/student_data_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final backgroundColor = const Color(0xFF1A1A1A);
  final cardColor = const Color(0xFF262626);
  final selectedItemColor = const Color(0xFF2E4F3A);
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
  List<Student> _filteredStudents = [];
  String _searchQuery = '';
  final Map<String, GlobalKey> _studentKeys = {};
  bool _isScrolling = false;
  Map<String, bool>? _showMePreferences;

  @override
  void initState() {
    super.initState();
    userId = _auth.getCurrentUserId();
    _loadUserPreferences();
    _initializeData();

    _scrollController.addListener(() {
      final showScrollToTop = _scrollController.offset > 200;
      if (showScrollToTop != _showScrollToTop) {
        setState(() {
          _showScrollToTop = showScrollToTop;
        });
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      if (_searchQuery.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToMatchingStudent();
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentShowMePreferences() async {
    try {
      final batch = _studentInfo?['batchNo'].toString();
      if (batch == null) return;

      final showMePreferences = await Future.wait(
        students.map((student) async {
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
        })
      );

      final showMeMap = showMePreferences.fold<Map<String, bool>>(
        {}, (acc, current) => acc..addAll(current.cast<String, bool>())
      );

      setState(() {
        _showMePreferences = showMeMap;
      });
    } catch (e) {
      print('Error in _fetchStudentShowMePreferences: $e');
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (userId != null) {
      try {
        final userDoc = await _firestore.collection('students').doc(userId).get();
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
        return Future.value(
          '${nameParts[0][0]} ' + 
          nameParts.sublist(1).map((part) => '*' * part.length).join(' ')
        );
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  Future<void> _initializeData() async {
    setState(() {});

    final hasCache = await _loadCachedData();
    if (!hasCache) {
      await _fetchStudentData();
    }

    if (_studentInfo != null) {
      print('Student info: $_studentInfo');
      final batch = _studentInfo!['batchNo'].toString();
      await loadStudents(batch);
      await _fetchStudentShowMePreferences();
    }

    setState(() {});
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
        return 'assets/studentRank39NFE.csv';
      case '61':
        return 'assets/studentRank61CSE.csv';
      case '62':
        return 'assets/studentRank62CSE.csv';
      case '63':
        return 'assets/studentRank63CSE.csv';
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
    setState(() {
      isLoading = true;
    });

    try {
      final String csvData = await loadCsvForBatch(batch);
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      csvTable.removeAt(0); // Remove header row

      List<Student> loadedStudents = csvTable.map((row) => Student.fromCsvRow(row)).toList();

      setState(() {
        students = loadedStudents;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        isLoading = false;
        students = []; // Clear students list on error
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
            backgroundColor: cardColor,
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
      double currentUserHeight = _buildCurrentUserRank().toString() != 'SizedBox.shrink' ? 76 : 0;
      double spacingHeight = 20;
      double itemHeight = 72;
      
      offset = podiumHeight + currentUserHeight + spacingHeight + 
               ((matchIndex - 3) * itemHeight);
    }

    // Perform the scroll with a slight offset for better visibility
    _scrollController.animateTo(
      max(0, offset - 100), // Subtract 100 to show some content above
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    ).then((_) {
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
    String? currentUserId = _studentInfo?['studentId'] as String?;
    currentUserId ??= userId;
    bool canSeeFullName = _studentInfo?['showMe'] ?? false;

    if (currentUserId == null) return const SizedBox.shrink();

    // Find the current user's position
    int userIndex =
        students.indexWhere((student) => student.id == currentUserId);
    if (userIndex < 0 || userIndex < 3) return const SizedBox.shrink();

    final student = students[userIndex];
    String displayName = await _anonymizeName(student.name, student.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selectedItemColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${userIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[800],
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text('Your Position',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            student.cgpa.toStringAsFixed(2),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildPodiumItem(Student student, int rank) async {
    Color getMedalColor(int rank) {
      switch (rank) {
        case 1:
          return const Color(0xFFFFD700); // Gold
        case 2:
          return const Color(0xFFC0C0C0); // Silver
        case 3:
          return const Color(0xFFCD7F32); // Bronze
        default:
          return Colors.grey[400]!;
      }
    }

    String displayName = await _anonymizeName(student.name, student.id);

    final bool isMatch = _searchQuery.isNotEmpty &&
        student.name.toLowerCase().contains(_searchQuery);
    
    final bool isCurrentUser = student.id == (_studentInfo?['studentId'] as String? ?? userId);

    return Container(
      key: _studentKeys.putIfAbsent(student.id, () => GlobalKey()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1)
            Transform.translate(
              offset: const Offset(0, 10),
              child: Image.asset(
                'assets/crown.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCurrentUser) 
                Container(
                  width: rank == 1 ? 100 : 80,
                  height: rank == 1 ? 100 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      for (var i = 0; i < 3; i++)
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3 - i * 0.1),
                          spreadRadius: (i + 1) * 4,
                          blurRadius: (i + 1) * 4,
                        ),
                    ],
                  ),
                ),
              CircleAvatar(
                radius: rank == 1 ? 40 : 30,
                backgroundColor: isMatch 
                  ? Colors.amber 
                  : isCurrentUser 
                    ? Colors.green 
                    : getMedalColor(rank),
                child: Text(
                  displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: isMatch || isCurrentUser ? Colors.black : Colors.white,
                    fontSize: rank == 1 ? 24 : 20,
                  ),
                ),
              ),
              if (rank <= 3)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[600]!,
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: TextStyle(
              color: isMatch 
                ? Colors.amber 
                : isCurrentUser 
                  ? Colors.green 
                  : Colors.white,
              fontSize: rank == 1 ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            student.cgpa.toStringAsFixed(2),
            style: TextStyle(
              color: isMatch 
                ? Colors.amber 
                : isCurrentUser 
                  ? Colors.green 
                  : getMedalColor(rank),
              fontSize: rank == 1 ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildListItem(Student student, int rank, bool isCurrentUser) async {
    String displayName = await _anonymizeName(student.name, student.id);

    final bool isMatch = _searchQuery.isNotEmpty &&
        student.name.toLowerCase().contains(_searchQuery);

    return Container(
      key: _studentKeys.putIfAbsent(student.id, () => GlobalKey()),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isMatch
            ? Colors.amber.withOpacity(0.3)
            : (isCurrentUser ? selectedItemColor : cardColor),
        borderRadius: BorderRadius.circular(12),
        border: isMatch ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: isMatch ? Colors.amber : Colors.grey[800],
            child: Text(
              displayName[0].toUpperCase(),
              style: TextStyle(
                color: isMatch ? Colors.black : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                color: isMatch ? Colors.amber : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            student.cgpa.toStringAsFixed(2),
            style: TextStyle(
              color: isMatch ? Colors.amber : Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId = _studentInfo?['studentId'] as String?;
    currentUserId ??= userId;
    final batch = _studentInfo?['batchNo'].toString();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                    const Text(
                      'DIU Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Batch ${batch}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
          centerTitle: true,
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: _toggleSearch,
                )
              : null,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.clear : Icons.search),
              onPressed: _toggleSearch,
              color: Colors.white,
            ),
          ],
          backgroundColor: backgroundColor,
        ),
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
                  ? const Center(
                      child: Text('No data available',
                          style: TextStyle(color: Colors.white)))
                  : CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Top 3 Podium
                        if (students.length >= 3)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SizedBox(
                                height: 200,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                        child:
                                            FutureBuilder<Widget>(
                                              future: _buildPodiumItem(students[1], 2),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return const Icon(Icons.error);
                                                } else {
                                                  return snapshot.data!;
                                                }
                                              },
                                            )),
                                    Expanded(
                                        flex: 2,
                                        child: FutureBuilder<Widget>(
                                          future: _buildPodiumItem(students[0], 1),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return const Icon(Icons.error);
                                            } else {
                                              return snapshot.data!;
                                            }
                                          },
                                        )),
                                    Expanded(
                                        child:
                                            FutureBuilder<Widget>(
                                              future: _buildPodiumItem(students[2], 3),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return const Icon(Icons.error);
                                                } else {
                                                  return snapshot.data!;
                                                }
                                              },
                                            )),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Current User's Rank (if not in top 3)
                        SliverToBoxAdapter(
                          child: FutureBuilder<Widget>(
                            future: _buildCurrentUserRank(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return const Icon(Icons.error);
                              } else {
                                return snapshot.data ?? const SizedBox.shrink();
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
                              final isCurrentUser = student.id == currentUserId;
                              return FutureBuilder<Widget>(
                                future: _buildListItem(student, index + 4, isCurrentUser),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return const Icon(Icons.error);
                                  } else {
                                    return snapshot.data ?? const SizedBox.shrink();
                                  }
                                },
                              );
                            },
                            childCount:
                                students.length > 3 ? students.length - 3 : 0,
                          ),
                        ),
                      ],
                    ),
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _showScrollToTop && !_isSearching ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward, color: Colors.yellowAccent),
            backgroundColor: cardColor,
            elevation: 1,
          ),
        ),
      ),
    );
  }
}