import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/student_data_service.dart';
import '../services/gemini_service.dart';

class AIRecommendationsPage extends StatefulWidget {
  final String userId;

  const AIRecommendationsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AIRecommendationsPage> createState() => _AIRecommendationsPageState();
}

class _AIRecommendationsPageState extends State<AIRecommendationsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> recommendations = [];
  List<Map<String, dynamic>> retakeSuggestions = [];
  final StudentDataService _studentDataService = StudentDataService();
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _analyzeStudentResults();
  }

  Future<void> _analyzeStudentResults() async {
    try {
      // Get user data to fetch student ID
      final userData = await _studentDataService.getUserData(widget.userId);
      if (userData == null) {
        setState(() => isLoading = false);
        return;
      }

      final studentId = userData['studentId'];

      // Fetch semester results
      final semesterResults = await _studentDataService.fetchResults(studentId);
      
      // Calculate current CGPA
      final currentCGPA = _studentDataService.calculateOverallCGPA(semesterResults);
      
      List<Map<String, dynamic>> tempRecommendations = [];
      List<Map<String, dynamic>> tempRetakeSuggestions = [];

      // Iterate through semester results
      for (var entry in semesterResults.entries) {
        for (var course in entry.value) {
          double pointEquivalent = double.parse(course['pointEquivalent']?.toString() ?? '0.0');
          
          // Check for courses below passing grade
          if (pointEquivalent < 3.0) {
            // Existing recommendations logic
            final courseRecommendations = await _geminiService.getRecommendationsForCourse(
              course['courseTitle'],
              course['gradeLetter'],
              pointEquivalent,
            );

            if (courseRecommendations.isNotEmpty) {
              // Calculate CGPA projection for retake
              final cgpaProjection = await _calculateCGPARetakePotential(
                studentId, 
                course['customCourseId'], 
                course['gradeLetter']
              );

              tempRetakeSuggestions.add({
                'courseTitle': course['courseTitle'],
                'courseCode': course['customCourseId'],
                'currentGrade': course['gradeLetter'],
                'currentPoints': pointEquivalent,
                'currentCGPA': currentCGPA,
                'cgpaProjection': cgpaProjection,
                'recommendations': courseRecommendations,
              });

              tempRecommendations.add({
                'courseTitle': course['courseTitle'],
                'courseCode': course['customCourseId'],
                'grade': course['gradeLetter'],
                'point': pointEquivalent,
                'recommendations': courseRecommendations,
                'retakeSuggestion': cgpaProjection,
              });
            }
          }
        }
      }

      setState(() {
        recommendations = tempRecommendations;
        retakeSuggestions = tempRetakeSuggestions;
        isLoading = false;
      });
    } catch (e) {
      print('Error analyzing results: $e');
      setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _calculateCGPARetakePotential(
    String studentId,
    String courseCode,
    String currentGrade
  ) async {
    try {
      // Fetch all semester results
      final semesterResults = await _studentDataService.fetchResults(studentId);
      
      // Calculate current CGPA
      final currentCGPA = _studentDataService.calculateOverallCGPA(semesterResults);

      // Grade point mapping
      Map<String, double> gradePoints = {
        'A+': 4.0, 'A': 3.75, 'A-': 3.50,
        'B+': 3.25, 'B': 3.0, 'B-': 2.75,
        'C+': 2.50, 'C': 2.25,
        'D': 2.0, 'F': 0.0
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
        double newCGPA = _studentDataService.calculateOverallCGPA(modifiedResults);

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/ai_loading.json',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'AI is analyzing your performance...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Recommendations Section
                  if (recommendations.isNotEmpty) ...[
                    const Text(
                      'Recommendations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...recommendations.map((recommendation) => _buildRecommendationCard(recommendation)),
                  ] else ...[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/achievement.json',
                            width: 200,
                            height: 200,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Great job! No improvements needed.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Course Retakes Section
                  if (retakeSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Course Retake Suggestions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...retakeSuggestions.map((retakeSuggestion) => _buildRetakeSuggestionCard(retakeSuggestion)),
                  ] else ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/success.json',
                            width: 200,
                            height: 200,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Recommended Course Retakes',
                            style: TextStyle(
                              color: Colors.white,
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

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2B2E4A),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation['courseTitle'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recommendation['courseCode'],
                    style: const TextStyle(
                      color: Colors.blue,
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
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Grade: ${recommendation['grade']}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Recommendations',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...recommendation['recommendations']
                    .map<Widget>((rec) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
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
                                  : Icons.book,
                              color: Colors.yellow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rec['type'],
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rec['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
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

  Widget _buildRetakeSuggestionCard(Map<String, dynamic> retakeSuggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2B2E4A),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              retakeSuggestion['courseTitle'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    retakeSuggestion['courseCode'],
                    style: const TextStyle(
                      color: Colors.blue,
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
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current Grade: ${retakeSuggestion['currentGrade']}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
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
                    color: Colors.yellowAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Current CGPA: ${retakeSuggestion['currentCGPA'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                // CGPA Projection Cards
                ...retakeSuggestion['cgpaProjection']['projections'].entries.map((projectionEntry) {
                  final grade = projectionEntry.key;
                  final projection = projectionEntry.value;
                  return Card(
                    color: Colors.deepPurple[800],
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'If you achieve Grade $grade',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Projected CGPA: ${projection['projectedCGPA'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'CGPA Improvement: +${projection['cgpaImprovement'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: projection['cgpaImprovement'] > 0 
                                ? Colors.green 
                                : Colors.red
                            ),
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