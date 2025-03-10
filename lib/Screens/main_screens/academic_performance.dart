import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../../models/semester_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../../services/student_data_service.dart';

class AcademicPerformancePage extends StatefulWidget {
  const AcademicPerformancePage({super.key});

  @override
  State<AcademicPerformancePage> createState() =>
      _AcademicPerformancePageState();
}

class _AcademicPerformancePageState extends State<AcademicPerformancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Academic Performance',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'CGPA Calculator'),
            Tab(text: 'Semester Results'),
          ],
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: TabBarView(
          controller: _tabController,
          children: const [
            CGPACalculatorTab(),
            SemesterResultsTab(),
          ],
        ),
      ),
    );
  }
}

// CGPA Calculator Tab
class CGPACalculatorTab extends StatefulWidget {
  const CGPACalculatorTab({super.key});

  @override
  State<CGPACalculatorTab> createState() => _CGPACalculatorTabState();
}

class _CGPACalculatorTabState extends State<CGPACalculatorTab>
    with SingleTickerProviderStateMixin {
  // Copy all the state variables and methods from _CGPAViewState
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _studentDataService = StudentDataService();
  bool _isLoading = false;
  CGPAResult? _result;
  late AnimationController _gradientController;
  double _animationValue = 0.0;

  // Copy all the methods from _CGPAViewState
  // ... (copy all methods from CGPAView)

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCalculatorForm(),
          if (_isLoading)
            const _LoadingAnimation()
          else if (_result != null)
            _buildResults(_result!),
        ],
      ),
    );
  }

  Widget _buildResults(CGPAResult result) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: Card(
            
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFC33764),
                    Color(0xFF6E388F),
                    Color(0xFF1D2671),
                  ].map((color) => color.withOpacity(0.8)).toList(),
                  stops: const [0.0, 0.5, 1.0],
                  transform: GradientRotation(_animationValue * 2 * pi),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (result.studentName != null)
                      Text(
                        result.studentName!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    if (result.programName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.programName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (result.batchNo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Batch: ${result.batchNo}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      result.cgpa.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                    ),
                    Text(
                      'CGPA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total Credits: ${result.totalCredits}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSemestersList(result.semesters),
        const SizedBox(height: 16),
        _buildCGPAChart(result.semesters),
      ],
    );
  }

  Widget _buildSemestersList(List<SemesterResult> semesters) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: semesters.length,
      itemBuilder: (context, index) {
        final semester = semesters[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface, width: 1),
          ),
          child: InkWell(
            onTap: () => _showSemesterDetails(semester),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${semester.name} ${semester.year}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'SGPA: ${semester.sgpa.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Credits: ${semester.credits.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Courses: ${semester.courses.length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSemesterDetails(SemesterResult semester) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SemesterDetailsSheet(semester: semester),
    );
  }

  Widget _buildCGPAChart(List<SemesterResult> semesters) {
    if (semesters == null || semesters.isEmpty) {
      return Container(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No CGPA Data Available',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final validSemesters = semesters
        .where((s) =>
            s.sgpa != null && s.sgpa.isFinite && s.sgpa >= 0 && s.sgpa <= 4.0)
        .toList();

    if (validSemesters.isEmpty) {
      return Container(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Unable to Generate CGPA Chart',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CGPA Progression',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= validSemesters.length)
                            return Container();
                          final semester = validSemesters[index];
                          return Text(
                            '${semester.name}\n${semester.year}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[700]),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: validSemesters.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.sgpa);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.3),
                            Theme.of(context).primaryColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: validSemesters.length.toDouble() - 1,
                  minY: 0,
                  maxY: 4.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _calculateCGPA() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final studentId = _studentIdController.text;

        // Fetch student info
        final studentInfo =
            await _studentDataService.fetchStudentInfo(studentId);

        // Fetch semester results
        final semesterResults =
            await _studentDataService.fetchResults(studentId);
        print(semesterResults);

        // Calculate overall CGPA
        final cgpa = _studentDataService.calculateOverallCGPA(semesterResults);

        // Prepare semester results
        final allSemesters = <SemesterResult>[];

        semesterResults.forEach((semesterId, results) {
          // Calculate semester SGPA
          final sgpa = _studentDataService.calculateSemesterCGPA(results);

          // Prepare courses for this semester
          final courses = results
              .map((course) => CourseResult(
                    courseTitle: course['courseTitle'],
                    totalCredit: double.parse(course['totalCredit'].toString()),
                    gradeLetter: course['gradeLetter'],
                    pointEquivalent:
                        double.parse(course['pointEquivalent'].toString()),
                  ))
              .toList();

          // Determine semester name and year from semesterId
          final semesterName = _getSemesterName(semesterId);
          final semesterYear = _getSemesterYear(semesterId);

          allSemesters.add(SemesterResult(
            name: semesterName,
            year: semesterYear,
            credits:
                courses.fold(0.0, (sum, course) => sum + course.totalCredit),
            sgpa: sgpa,
            courses: courses,
          ));
        });

        // Sort semesters chronologically
        allSemesters.sort((a, b) {
          if (a.year != b.year) {
            return b.year - a.year;
          }
          final seasonOrder = {'Spring': 1, 'Summer': 2, 'Fall': 3, 'Short': 4};
          final aOrder = seasonOrder[a.name] ?? 0;
          final bOrder = seasonOrder[b.name] ?? 0;
          return bOrder - aOrder;
        });

        setState(() {
          _result = CGPAResult(
            cgpa: cgpa,
            totalCredits: allSemesters.fold(
                0, (sum, semester) => sum + semester.credits.toInt()),
            semesters: allSemesters,
            studentName: studentInfo['studentName'] ?? 'Unknown Student',
            programName: studentInfo['programName'] ?? 'Unknown Program',
            batchNo: studentInfo['batchNo']?.toString() ?? 'Unknown Batch',
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper methods to parse semester ID
  String _getSemesterName(String semesterId) {
    final lastDigit = semesterId[semesterId.length - 1];
    switch (lastDigit) {
      case '1':
        return 'Spring';
      case '2':
        return 'Summer';
      case '3':
        return 'Fall';
      default:
        return 'Unknown';
    }
  }

  int _getSemesterYear(String semesterId) {
    final yearPrefix = semesterId.substring(0, semesterId.length - 1);
    return int.parse('20$yearPrefix');
  }

  Widget _buildCalculatorForm() {
    return Form(
      key: _formKey,
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _studentIdController,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  labelStyle:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _calculateCGPA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_isLoading ? 'Calculating...' : 'Calculate CGPA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _gradientController.addListener(() {
      setState(() {
        _animationValue = _gradientController.value;
      });
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }
}

class _SemesterDetailsSheet extends StatelessWidget {
  final SemesterResult semester;

  const _SemesterDetailsSheet({required this.semester});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      snap: true,
      snapSizes: const [0.5, 0.8, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${semester.name} ${semester.year}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'SGPA: ${semester.sgpa.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Credits: ${semester.credits.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: semester.courses.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final course = semester.courses[index];
                            return ListTile(
                              title: Text(
                                course.courseTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'Credits: ${course.totalCredit}',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGradeColor(course.gradeLetter),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${course.gradeLetter} (${course.pointEquivalent})',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
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
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'A-':
      case 'B+':
        return Colors.blue;
      case 'B':
      case 'B-':
        return Colors.orange;
      case 'C+':
      case 'C':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}

class _LoadingAnimation extends StatelessWidget {
  const _LoadingAnimation();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/jsons/loading.json',
      width: 400,
      height: 400,
      fit: BoxFit.fill,
    );
  }
}

class _BouncingBall extends StatefulWidget {
  final Duration delay;

  const _BouncingBall({required this.delay});

  @override
  State<_BouncingBall> createState() => _BouncingBallState();
}

class _BouncingBallState extends State<_BouncingBall>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(widget.delay, () {
      _controller.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _animation.value),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.yellowAccent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Semester Results Tab
class SemesterResultsTab extends StatefulWidget {
  const SemesterResultsTab({super.key});

  @override
  State<SemesterResultsTab> createState() => _SemesterResultsTabState();
}

class _SemesterResultsTabState extends State<SemesterResultsTab>
    with SingleTickerProviderStateMixin {
  // Copy all the state variables and methods from _ResultsViewState
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  String? _selectedYear;
  String? _selectedSemester;
  StudentInfo? _studentInfo;
  List<CourseResult>? _semesterResults;
  double? _sgpa;
  late AnimationController _gradientController;
  double _animationValue = 0.0;

  final List<String> _years = [
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2017',
    '2016',
    '2015',
  ];

  final List<String> _semesters = ['Spring', 'Summer', 'Fall', 'Short'];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _gradientController.addListener(() {
      setState(() {
        _animationValue = _gradientController.value;
      });
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    if (!_formKey.currentState!.validate() ||
        _selectedYear == null ||
        _selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final studentId = _studentIdController.text;

      // Fetch student info
      _studentInfo = await ApiService.getStudentInfo(studentId);
      if (_studentInfo?.studentId == null) {
        throw Exception('Invalid Student ID');
      }

      // Find semester ID
      final semesterId = ApiService.semestersList.firstWhere(
        (s) =>
            s['semesterYear'] == _selectedYear &&
            s['semesterName'] == _selectedSemester,
        orElse: () => throw Exception('Semester not found'),
      )['semesterId']!;

      // Fetch semester results
      final results =
          await ApiService.getSemesterResults(studentId, semesterId);

      if (results.isEmpty) {
        throw Exception('No results found for this semester');
      }

      double totalPoints = 0;
      double totalCredits = 0;
      final courses = <CourseResult>[];

      for (final course in results) {
        if (course['gradeLetter'] != 'F') {
          final credit = double.parse(course['totalCredit'].toString());
          final point = double.parse(course['pointEquivalent'].toString());

          totalPoints += credit * point;
          totalCredits += credit;

          courses.add(CourseResult(
            courseTitle: course['courseTitle'],
            totalCredit: credit,
            gradeLetter: course['gradeLetter'],
            pointEquivalent: point,
          ));
        }
      }

      setState(() {
        _semesterResults = courses;
        _sgpa = totalPoints / totalCredits;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() {
        _studentInfo = null;
        _semesterResults = null;
        _sgpa = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchForm(),
          if (_isLoading)
            Lottie.asset(
              'assets/jsons/loading.json',
              width: 400,
              height: 400,
              fit: BoxFit.fill,
            )
          else if (_studentInfo != null && _sgpa != null)
            Column(
              children: [
                const SizedBox(height: 20),
                _buildResultCard(),
                const SizedBox(height: 20),
                _buildResultsTable(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Form(
      key: _formKey,
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedYear,
                dropdownColor: Theme.of(context)
                    .colorScheme
                    .surface, // Dropdown background
                decoration: InputDecoration(
                  labelText: 'Year',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ), // Label text color
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ), // Border color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ), // Enabled border color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ), // Highlighted border color
                  ),
                ),
                items: _years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(
                      year,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ), // Text color in the dropdown
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a year';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  labelText: 'Semester',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                items: _semesters.map((semester) {
                  return DropdownMenuItem(
                    value: semester,
                    child: Text(
                      semester,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a semester';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                      )
                    : const Text('Show Results'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      child: Card(
        elevation: 4,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFC33764),
                    Color(0xFF6E388F),
                    Color(0xFF1D2671),
                  ].map((color) => color.withOpacity(0.8)).toList(),
                  stops: const [0.0, 0.5, 1.0],
                  transform: GradientRotation(_animationValue * 2 * pi),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  _studentInfo?.studentName ?? 'N/A',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${_studentInfo?.studentId ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Text(
                  'Batch: ${_studentInfo?.batchNo ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_selectedSemester $_selectedYear',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _sgpa?.toStringAsFixed(2) ?? 'N/A',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'SGPA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Text(
                'Course',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            DataColumn(
              label: Text(
                'Credits',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            DataColumn(
              label: Text(
                'Grade',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            DataColumn(
              label: Text(
                'Points',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
          rows: _semesterResults?.map((course) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        course.courseTitle,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    DataCell(
                      Text(
                        course.totalCredit.toString(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    DataCell(
                      Text(
                        course.gradeLetter,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    DataCell(
                      Text(
                        course.pointEquivalent.toString(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ],
                );
              }).toList() ??
              [],
        ),
      ),
    );
  }
}

// Loading Animation Widget
class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/jsons/loading.json',
        width: 400,
        height: 400,
        fit: BoxFit.fill,
      ),
    );
  }
}
