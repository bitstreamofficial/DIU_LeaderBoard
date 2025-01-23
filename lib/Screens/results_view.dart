import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'dart:math';

import '../models/semester_model.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';

class ResultsView extends StatefulWidget {
  const ResultsView({super.key});

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Results',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchForm(),
            if (_isLoading)
              Lottie.asset(
                'assets/loading.json', 
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
      ),
    );
  }

  Widget _buildSearchForm() {
    return Form(
      key: _formKey,
      child: Card(
        color: const Color(0xFF1A1A1A),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedYear,
                dropdownColor: const Color(0xFF1A1A1A), // Dropdown background
                decoration: const InputDecoration(
                  labelText: 'Year',
                  labelStyle:
                      TextStyle(color: Colors.white), // Label text color
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Border color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white), // Enabled border color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.yellowAccent), // Highlighted border color
                  ),
                ),
                items: _years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(
                      year,
                      style: const TextStyle(
                          color: Colors.white), // Text color in the dropdown
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
                dropdownColor: const Color(0xFF1A1A1A),
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellowAccent),
                  ),
                ),
                items: _semesters.map((semester) {
                  return DropdownMenuItem(
                    value: semester,
                    child: Text(semester,
                        style: const TextStyle(color: Colors.white)),
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellowAccent),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  _studentInfo?.studentName ?? 'N/A',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${_studentInfo?.studentId ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                Text(
                  'Batch: ${_studentInfo?.batchNo ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
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
                        color: Colors.white.withOpacity(0.9),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Course')),
            DataColumn(label: Text('Credits')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Points')),
          ],
          rows: _semesterResults?.map((course) {
                return DataRow(
                  cells: [
                    DataCell(Text(course.courseTitle)),
                    DataCell(Text(course.totalCredit.toString())),
                    DataCell(Text(course.gradeLetter)),
                    DataCell(Text(course.pointEquivalent.toString())),
                  ],
                );
              }).toList() ??
              [],
        ),
      ),
    );
  }
}
