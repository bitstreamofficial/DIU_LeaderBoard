import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../services/student_data_service.dart';
import '../../services/gemini_service.dart';

class AIRecommendationsPage extends StatefulWidget {
  final String userId;

  const AIRecommendationsPage({Key? key, required this.userId})
      : super(key: key);

  @override
  State<AIRecommendationsPage> createState() => _AIRecommendationsPageState();
}

class _AIRecommendationsPageState extends State<AIRecommendationsPage>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  bool _mounted = true;
  List<Map<String, dynamic>> recommendations = [];
  List<Map<String, dynamic>> retakeSuggestions = [];
  List<Map<String, dynamic>> lowCgpaRecommendations = [];
  double? studentCGPA;
  final StudentDataService _studentDataService = StudentDataService();
  final GeminiService _geminiService = GeminiService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _analyzeStudentResults();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Map<String, dynamic> _categorizeCourseUrgency(double pointEquivalent) {
    if (pointEquivalent < 2.0) {
      return {
        'urgency': 'Critical',
        'color': Colors.red,
        'message':
            'Immediate attention required. Consider retaking this course.'
      };
    } else if (pointEquivalent < 2.5) {
      return {
        'urgency': 'High',
        'color': Colors.orange,
        'message': 'Strong improvement needed. Focus on this course.'
      };
    } else {
      return {
        'urgency': 'Moderate',
        'color': Colors.amber,
        'message': 'Improvement recommended for better CGPA.'
      };
    }
  }

  Future<void> _analyzeStudentResults() async {
    if (!_mounted) return;

    try {
      final userData = await _studentDataService.getUserData(widget.userId);
      if (!_mounted) return;

      if (userData == null) {
        if (_mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final studentId = userData['studentId'];
      final semesterResults = await _studentDataService.fetchResults(studentId);
      final currentCGPA =
          _studentDataService.calculateOverallCGPA(semesterResults);
      studentCGPA = currentCGPA;

      List<Map<String, dynamic>> tempRecommendations = [];
      List<Map<String, dynamic>> tempRetakeSuggestions = [];
      List<Map<String, dynamic>> tempLowCgpaRecommendations = [];

      // Analyze each semester's courses
      for (var entry in semesterResults.entries) {
        String semester = entry.key;
        List<dynamic> courses = entry.value;

        for (var course in courses) {
          double pointEquivalent =
              double.parse(course['pointEquivalent']?.toString() ?? '0.0');

          // Check if course CGPA is below 3.00
          if (pointEquivalent < 3.00) {
            // Get recommendations for this specific course
            final courseRecommendations =
                await _geminiService.getRecommendationsForCourse(
              course['courseTitle'],
              course['gradeLetter'],
              pointEquivalent,
            );

            if (courseRecommendations.isNotEmpty) {
              // Calculate CGPA projection for retake
              final cgpaProjection = await _calculateCGPARetakePotential(
                studentId,
                course['customCourseId'],
                course['gradeLetter'],
              );

              // Get urgency categorization
              final urgencyInfo = _categorizeCourseUrgency(pointEquivalent);

              // Add to retake suggestions
              tempRetakeSuggestions.add({
                'semester': semester,
                'courseTitle': course['courseTitle'],
                'courseCode': course['customCourseId'],
                'currentGrade': course['gradeLetter'],
                'currentPoints': pointEquivalent,
                'currentCGPA': currentCGPA,
                'cgpaProjection': cgpaProjection,
                'recommendations': courseRecommendations,
                'urgency': urgencyInfo['urgency'],
                'urgencyColor': urgencyInfo['color'],
                'urgencyMessage': urgencyInfo['message'],
              });

              // Add to main recommendations
              tempRecommendations.add({
                'semester': semester,
                'courseTitle': course['courseTitle'],
                'courseCode': course['customCourseId'],
                'grade': course['gradeLetter'],
                'point': pointEquivalent,
                'recommendations': courseRecommendations,
                'retakeSuggestion': cgpaProjection,
                'urgency': urgencyInfo['urgency'],
                'urgencyColor': urgencyInfo['color'],
                'urgencyMessage': urgencyInfo['message'],
              });
            }
          }
        }
      }

      // Sort recommendations by urgency
      tempRecommendations.sort((a, b) {
        final urgencyOrder = {'Critical': 0, 'High': 1, 'Moderate': 2};
        return urgencyOrder[a['urgency']]!
            .compareTo(urgencyOrder[b['urgency']]!);
      });

      if (_mounted) {
        setState(() {
          recommendations = tempRecommendations;
          retakeSuggestions = tempRetakeSuggestions;
          lowCgpaRecommendations = tempLowCgpaRecommendations;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error analyzing results: $e');
      if (_mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _calculateCGPARetakePotential(
      String studentId, String courseCode, String currentGrade) async {
    try {
      // Fetch all semester results
      final semesterResults = await _studentDataService.fetchResults(studentId);

      // Calculate current CGPA
      final currentCGPA =
          _studentDataService.calculateOverallCGPA(semesterResults);

      // Grade point mapping
      Map<String, double> gradePoints = {
        'A+': 4.0,
        'A': 3.75,
        'A-': 3.50,
        'B+': 3.25,
        'B': 3.0,
        'B-': 2.75,
        'C+': 2.50,
        'C': 2.25,
        'D': 2.0,
        'F': 0.0
      };

      // Possible retake grade scenarios
      List<String> potentialGrades = ['A+', 'A', 'A-', 'B+', 'B'];

      Map<String, dynamic> projections = {};

      // Calculate projection for each potential grade
      for (String grade in potentialGrades) {
        // Clone the existing semester results to avoid modifying original
        var modifiedResults = Map<String, List<dynamic>>.from(semesterResults);

        // Find and update the specific course's grade
        modifiedResults.forEach((semester, courses) {
          for (var course in courses) {
            if (course['customCourseId'] == courseCode) {
              // Update the point equivalent based on new grade
              course['pointEquivalent'] = gradePoints[grade];
            }
          }
        });

        // Calculate new CGPA with modified results
        double newCGPA =
            _studentDataService.calculateOverallCGPA(modifiedResults);

        projections[grade] = {
          'projectedCGPA': newCGPA,
          'cgpaImprovement': newCGPA - currentCGPA
        };
      }

      return {
        'currentCGPA': currentCGPA,
        'courseCode': courseCode,
        'projections': projections
      };
    } catch (e) {
      print('Error in CGPA projection: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/jsons/ai_loading.json',
                      width: size.width * 0.5, // 50% of screen width
                      height: size.height * 0.3, // 30% of screen height
                    ),
                    SizedBox(height: size.height * 0.02), // 2% of screen height
                    Text(
                      'AI is analyzing your performance...',
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: size.width * 0.04, // Responsive font size
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding:
                    EdgeInsets.all(size.width * 0.04), // Responsive padding
                children: [
                  // Display CGPA status with responsive sizing
                  if (studentCGPA != null) ...[
                    _buildCGPADisplay(
                        studentCGPA!, colorScheme, textTheme, size),
                    SizedBox(height: size.height * 0.03),
                  ],

                  // CGPA-based recommendations (only shown if CGPA < 3.00)
                  if (lowCgpaRecommendations.isNotEmpty) ...[
                    Text(
                      'Recommended Resources for CGPA Improvement',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLowCGPARecommendationsSection(
                        lowCgpaRecommendations, colorScheme, textTheme),
                    const SizedBox(height: 32),
                  ],

                  // Course-specific recommendations
                  if (recommendations.isNotEmpty) ...[
                    Text(
                      'Course-Specific Recommendations',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...recommendations.map((recommendation) =>
                        _buildRecommendationCard(
                            recommendation, colorScheme, textTheme)),
                  ] else if (lowCgpaRecommendations.isEmpty) ...[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/jsons/achievement.json',
                            width: 200,
                            height: 200,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Great job! No improvements needed.',
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Retake suggestions section
                  if (retakeSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Course Retake Suggestions',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...retakeSuggestions.map((retakeSuggestion) =>
                        _buildRetakeSuggestionCard(
                            retakeSuggestion, colorScheme, textTheme)),
                  ] else if (lowCgpaRecommendations.isEmpty) ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'No Recommended Course Retakes',
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildCGPADisplay(
    double cgpa,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Size size,
  ) {
    Color statusColor = cgpa < 3.0 ? colorScheme.error : Colors.green;
    String statusText = cgpa < 3.0 ? 'Needs Improvement' : 'Good Standing';

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current CGPA',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.045,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.height * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.035,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            Center(
              child: Text(
                cgpa.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: size.width * 0.09, // Large, responsive font size
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            if (cgpa < 3.0) ...[
              SizedBox(height: size.height * 0.02),
              Text(
                'Your CGPA is below 3.00. Explore the AI recommendations below to improve your academic performance.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: size.width * 0.035,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLowCGPARecommendationsSection(
    List<Map<String, dynamic>> recommendations,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Group recommendations by type
    Map<String, List<Map<String, dynamic>>> groupedRecs = {};

    for (var rec in recommendations) {
      String type = rec['type'] ?? 'General';
      if (!groupedRecs.containsKey(type)) {
        groupedRecs[type] = [];
      }
      groupedRecs[type]!.add(rec);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groupedRecs.entries.map((entry) {
          String type = entry.key;
          List<Map<String, dynamic>> typeRecs = entry.value;

          IconData typeIcon;
          switch (type.toLowerCase()) {
            case 'course':
              typeIcon = Icons.school;
              break;
            case 'video':
              typeIcon = Icons.video_library;
              break;
            case 'resource':
              typeIcon = Icons.article;
              break;
            case 'book':
              typeIcon = Icons.book;
              break;
            default:
              typeIcon = Icons.info;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(typeIcon, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$type Recommendations',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...typeRecs.map(
                  (rec) => _buildResourceCard(rec, colorScheme, textTheme)),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildResourceCard(
    Map<String, dynamic> resource,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    IconData typeIcon;
    switch (resource['type'].toString().toLowerCase()) {
      case 'course':
        typeIcon = Icons.school;
        break;
      case 'video':
        typeIcon = Icons.video_library;
        break;
      case 'resource':
        typeIcon = Icons.article;
        break;
      case 'book':
        typeIcon = Icons.book;
        break;
      default:
        typeIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.2),
          child: Icon(typeIcon, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          resource['title'],
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          resource['description'] ?? '',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing:
            resource['link'] != null && resource['link'].toString().isNotEmpty
                ? Icon(Icons.open_in_new, color: colorScheme.primary)
                : null,
        onTap: () {
          // Handle resource link opening
          if (resource['link'] != null &&
              resource['link'].toString().isNotEmpty) {
            // You can implement a URL launcher here
            print('Opening link: ${resource['link']}');
          }
        },
      ),
    );
  }

  Widget _buildRecommendationCard(
    Map<String, dynamic> recommendation,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recommendation['courseTitle'],
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (recommendation.containsKey('urgency'))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: recommendation['urgencyColor'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recommendation['urgency'],
                      style: TextStyle(
                        color: recommendation['urgencyColor'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recommendation['courseCode'],
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Grade: ${recommendation['grade']}',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (recommendation.containsKey('urgencyMessage')) ...[
              const SizedBox(height: 8),
              Text(
                recommendation['urgencyMessage'],
                style: TextStyle(
                  color: recommendation['urgencyColor'],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Recommendations',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...recommendation['recommendations'].map<Widget>((rec) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              rec['type'] == 'Course'
                                  ? Icons.school
                                  : rec['type'] == 'Video'
                                      ? Icons.video_library
                                      : rec['type'] == 'Book'
                                          ? Icons.book
                                          : Icons.article,
                              color: colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rec['type'],
                              style: TextStyle(
                                color: colorScheme.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rec['title'],
                          style: textTheme.bodyMedium,
                        ),
                        if (rec['description'] != null &&
                            rec['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            rec['description'],
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                        if (rec['link'] != null &&
                            rec['link'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              // Handle link opening logic here
                              print('Opening link: ${rec['link']}');
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Open Resource',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetakeSuggestionCard(
    Map<String, dynamic> retakeSuggestion,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    retakeSuggestion['courseTitle'],
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (retakeSuggestion.containsKey('urgency'))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: retakeSuggestion['urgencyColor'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      retakeSuggestion['urgency'],
                      style: TextStyle(
                        color: retakeSuggestion['urgencyColor'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    retakeSuggestion['courseCode'],
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current Grade: ${retakeSuggestion['currentGrade']}',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (retakeSuggestion.containsKey('urgencyMessage')) ...[
              const SizedBox(height: 8),
              Text(
                retakeSuggestion['urgencyMessage'],
                style: TextStyle(
                  color: retakeSuggestion['urgencyColor'],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CGPA Projection Scenarios',
                  style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Current CGPA: ${retakeSuggestion['currentCGPA'].toStringAsFixed(2)}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                ...retakeSuggestion['cgpaProjection']['projections']
                    .entries
                    .map((projectionEntry) {
                  final grade = projectionEntry.key;
                  final projection = projectionEntry.value;
                  return Card(
                    color: colorScheme.surface,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'If you achieve Grade $grade',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Projected CGPA: ${projection['projectedCGPA'].toStringAsFixed(2)}',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          Text(
                            'CGPA Improvement: +${projection['cgpaImprovement'].toStringAsFixed(2)}',
                            style: TextStyle(
                                color: projection['cgpaImprovement'] > 0
                                    ? Colors.green
                                    : Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
