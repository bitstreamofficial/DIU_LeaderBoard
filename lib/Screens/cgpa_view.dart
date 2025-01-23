import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

import '../models/semester_model.dart';
import '../services/student_data_service.dart';

class CGPAView extends StatefulWidget {
  const CGPAView({super.key});

  @override
  State<CGPAView> createState() => _CGPAViewState();
}

class _CGPAViewState extends State<CGPAView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _studentDataService = StudentDataService();

  bool _isLoading = false;
  CGPAResult? _result;
  late AnimationController _gradientController;
  double _animationValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: SingleChildScrollView(
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
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                  ].map((color) => color.withOpacity(0.8)).toList(),
                  stops: const [0.0, 0.5, 1.0],
                  transform: GradientRotation(_animationValue * 4 * pi),
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
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 1),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'SGPA: ${semester.sgpa.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
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
    // TODO: Implement chart using fl_chart package
    return Container();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _studentIdController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Student ID',
              hintText: 'Enter your student ID',
              labelStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.yellowAccent.withOpacity(0.7),
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
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _calculateCGPA,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
              child: Text(
                _isLoading ? 'Calculating...' : 'Calculate CGPA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
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
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'SGPA: ${semester.sgpa.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Credits: ${semester.credits.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                'Credits: ${course.totalCredit}',
                                style: const TextStyle(color: Colors.grey),
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
                                  style: const TextStyle(
                                    color: Colors.white,
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
      'assets/loading.json', 
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
