import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../../models/semester_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../../services/student_data_service.dart';

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
    '2025',
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
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Year Dropdown

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align items to the top
                children: <Widget>[
                  // Academic Year Dropdown
                  Expanded(
                    // Use Expanded to allow the dropdown to take available space
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedYear,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        decoration: InputDecoration(
                          labelText: 'Academic Year',
                          labelStyle: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        items: _years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
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
                    ),
                  ),
                  const SizedBox(width: 16), // Spacing between the dropdowns

                  // Semester Dropdown
                  Expanded(
                    // Use Expanded for the second dropdown as well
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSemester,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        decoration: InputDecoration(
                          labelText: 'Semester',
                          labelStyle: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.school,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        items: _semesters.map((semester) {
                          return DropdownMenuItem(
                            value: semester,
                            child: Text(
                              semester,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
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
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Student ID Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: TextFormField(
                  controller: _studentIdController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student ID';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Search Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fetchResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Show Results',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
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
