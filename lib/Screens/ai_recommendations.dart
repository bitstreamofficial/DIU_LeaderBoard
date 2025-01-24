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
      
      List<Map<String, dynamic>> tempRecommendations = [];

      // Iterate through semester results
      for (var entry in semesterResults.entries) {
        for (var course in entry.value) {
          double pointEquivalent = double.parse(course['pointEquivalent']?.toString() ?? '0.0');
          
          // Check for courses below passing grade
          if (pointEquivalent < 3.0) {
            final courseRecommendations = await _geminiService.getRecommendationsForCourse(
              course['courseTitle'],
              course['gradeLetter'],
              pointEquivalent,
            );

            if (courseRecommendations.isNotEmpty) {
              tempRecommendations.add({
                'courseTitle': course['courseTitle'],
                'courseCode': course['customCourseId'],
                'grade': course['gradeLetter'],
                'point': pointEquivalent,
                'recommendations': courseRecommendations,
              });
            }
          }
        }
      }

      setState(() {
        recommendations = tempRecommendations;
        isLoading = false;
      });
    } catch (e) {
      print('Error analyzing results: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Existing build method from previous implementation
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
            : recommendations.isEmpty
                ? Center(
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
                        const SizedBox(height: 10),
                        const Text(
                          'Keep up the excellent work!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final recommendation = recommendations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: const Color(0xFF2B2E4A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.all(16),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          if (rec['platform'] != null)
                                            Text(
                                              'Platform: ${rec['platform']}',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14,
                                              ),
                                            ),
                                          if (rec['author'] != null)
                                            Text(
                                              'Author: ${rec['author']}',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14,
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
                    },
                  ),
      ),
    );
  }
}