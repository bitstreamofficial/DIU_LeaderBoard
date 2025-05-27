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
    _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: 0); // Starts with "Semester Results"
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
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _studentDataService = StudentDataService();
  bool _isLoading = false;
  CGPAResult? _result;
  late AnimationController _gradientController;
  double _animationValue = 0.0;

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

        const SizedBox(height: 32),

        // Performance Summary Card
        _buildPerformanceSummary(result),

        const SizedBox(height: 24),
        _buildSemestersList(result.semesters),
        const SizedBox(height: 16),
        _buildCGPAChart(result.semesters),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary(CGPAResult result) {
    final performance = _analyzePerformance(result.cgpa);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: performance['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      performance['icon'],
                      color: performance['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Academic Performance',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          performance['status'],
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: performance['color'],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: result.cgpa / 4.0,
                backgroundColor:
                    Theme.of(context).colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(performance['color']),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 12),
              Text(
                performance['message'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGrade(double cgpa) {
    if (cgpa >= 4.0) return 'A+';
    if (cgpa >= 3.75) return 'A';
    if (cgpa >= 3.50) return 'A-';
    if (cgpa >= 3.25) return 'B+';
    if (cgpa >= 3.0) return 'B';
    if (cgpa >= 2.75) return 'B-';
    if (cgpa >= 2.50) return 'C+';
    if (cgpa >= 2.25) return 'C-';
    if (cgpa >= 2.00) return 'D';
    return 'F';
  }

  Map<String, dynamic> _analyzePerformance(double cgpa) {
    if (cgpa >= 3.5) {
      return {
        'status': 'Excellent Performance',
        'color': Colors.green,
        'icon': Icons.emoji_events,
        'message':
            'Outstanding academic achievement! You\'re performing exceptionally well and maintaining high standards.',
      };
    } else if (cgpa >= 3.0) {
      return {
        'status': 'Good Performance',
        'color': Colors.blue,
        'icon': Icons.trending_up,
        'message':
            'Good academic performance! You\'re on the right track. Keep up the consistent effort.',
      };
    } else if (cgpa >= 2.5) {
      return {
        'status': 'Satisfactory Performance',
        'color': Colors.orange,
        'icon': Icons.timeline,
        'message':
            'Satisfactory performance with room for improvement. Consider focusing on challenging subjects.',
      };
    } else {
      return {
        'status': 'Needs Improvement',
        'color': Colors.red,
        'icon': Icons.trending_down,
        'message':
            'There\'s room for improvement. Consider seeking additional support and developing better study strategies.',
      };
    }
  }

  Widget _buildSemestersList(List<SemesterResult> semesters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.calendar_view_month_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Semester Performance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Semesters List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: semesters.length,
          itemBuilder: (context, index) {
            final semester = semesters[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 3,
                shadowColor:
                    Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _showSemesterDetails(semester),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${semester.name} ${semester.year}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Semester ${semesters.length - index}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // SGPA Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getSGPAColor(semester.sgpa),
                                      _getSGPAColor(semester.sgpa)
                                          .withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getSGPAColor(semester.sgpa)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'SGPA ${semester.sgpa.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Stats Row
                          Row(
                            children: [
                              _buildStatChip(
                                icon: Icons.credit_card_rounded,
                                label: 'Credits',
                                value: semester.credits.toStringAsFixed(1),
                                color: Theme.of(context).colorScheme.primary,
                                context: context,
                              ),
                              const SizedBox(width: 12),
                              _buildStatChip(
                                icon: Icons.book_rounded,
                                label: 'Courses',
                                value: '${semester.courses.length}',
                                color: Theme.of(context).colorScheme.secondary,
                                context: context,
                              ),
                              const Spacer(),
                              // Performance Indicator
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getSGPAColor(semester.sgpa)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getPerformanceIcon(semester.sgpa),
                                  color: _getSGPAColor(semester.sgpa),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Performance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  Text(
                                    _getPerformanceLabel(semester.sgpa),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: _getSGPAColor(semester.sgpa),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: semester.sgpa / 4.0,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getSGPAColor(semester.sgpa)),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Tap hint
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Tap to view details',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSGPAColor(double sgpa) {
    if (sgpa >= 3.5) return Colors.green;
    if (sgpa >= 3.0) return Colors.blue;
    if (sgpa >= 2.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getPerformanceIcon(double sgpa) {
    if (sgpa >= 3.5) return Icons.emoji_events_rounded;
    if (sgpa >= 3.0) return Icons.trending_up_rounded;
    if (sgpa >= 2.5) return Icons.timeline_rounded;
    return Icons.trending_down_rounded;
  }

  String _getPerformanceLabel(double sgpa) {
    if (sgpa >= 3.5) return 'Excellent';
    if (sgpa >= 3.0) return 'Good';
    if (sgpa >= 2.5) return 'Average';
    return 'Needs Improvement';
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
                  color: Colors.white),
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
                            style: TextStyle(fontSize: 10, color: Colors.white),
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
                            style: TextStyle(fontSize: 10, color: Colors.white),
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
                        return FlSpot(
                          entry.key.toDouble(),
                          double.parse(entry.value.sgpa.toStringAsFixed(2)),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.tertiary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Theme.of(context).colorScheme.tertiary,
                            strokeWidth: 2,
                            strokeColor:
                                Theme.of(context).colorScheme.onSurface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.3),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withOpacity(0.3),
                            Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withOpacity(0.1),
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
              const SizedBox(height: 16),
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
                  onPressed: _isLoading ? null : _calculateCGPA,
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
                          labelText: 'Year',
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
    final ThemeData theme = Theme.of(context);
    final Color onSurfaceColor = theme.colorScheme.onSurface;
    final TextTheme textTheme = theme.textTheme;

    // Simple local map for grade colors for self-containment
    Map<String, Color> gradeColors = {
      'A+': Colors.green.shade700,
      'A': Colors.green.shade600,
      'A-': Colors.green.shade500,
      'B+': Colors.blue.shade700,
      'B': Colors.blue.shade600,
      'B-': Colors.blue.shade500,
      'C+': Colors.orange.shade700,
      'C': Colors.orange.shade600,
      'C-': Colors.orange.shade500, // Assuming C- exists
      'D': Colors.amber.shade700,
      'F': Colors.red.shade600,
      'DEFAULT': Colors.grey.shade600,
    };

    Color getGradeColor(String grade) {
      return gradeColors[grade.toUpperCase()] ?? gradeColors['DEFAULT']!;
    }

    return Card(
      elevation: 3, // Slightly increased elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface,
      clipBehavior:
          Clip.antiAlias, // Ensures DataTable respects card's border radius
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => theme.colorScheme.primaryContainer,
          ),
          headingTextStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
          columnSpacing: 22, // Adjusted column spacing
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: [
            DataColumn(
              label: Text('Course'), // Style inherited from headingTextStyle
            ),
            DataColumn(
              label: Text('Credits'),
              numeric: true,
            ),
            DataColumn(
              label: Text('Grade'),
            ),
            DataColumn(
              label: Text('Points'),
              numeric: true,
            ),
          ],
          rows: _semesterResults?.map((course) {
                final Color gradeColor = getGradeColor(course.gradeLetter);
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 160, // Give more space for course title
                        child: Text(
                          course.courseTitle,
                          overflow: TextOverflow.ellipsis, // Handle long titles
                          style: textTheme.bodyMedium
                              ?.copyWith(color: onSurfaceColor),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        course.totalCredit.toStringAsFixed(1), // Format credits
                        style: textTheme.bodyMedium
                            ?.copyWith(color: onSurfaceColor),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: gradeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          course.gradeLetter,
                          style: textTheme.labelLarge?.copyWith(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        course.pointEquivalent
                            .toStringAsFixed(2), // Format points
                        style: textTheme.bodyMedium
                            ?.copyWith(color: onSurfaceColor),
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
