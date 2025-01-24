import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Use the free API key
  static const String _apiKey = 'AIzaSyAXT0R6A3_fOr8V7IMiCF3JyZPFAVRJIsg';

  Future<List<Map<String, dynamic>>> getRecommendationsForCourse(
    String courseTitle, 
    String gradeLetter, 
    double pointEquivalent
  ) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.0-pro',
        apiKey: _apiKey,
      );

      final prompt = '''
      Course: $courseTitle
      Grade: $gradeLetter
      Point Equivalent: $pointEquivalent

      Provide 3-4 specific learning recommendations. 
      For each, include:
      - Type (Course/Book/Resource)
      - Title 
      - Platform (if applicable)
      - Author (if applicable)

      Respond strictly in this JSON format:
      [
        {
          "type": "Course/Book/Resource",
          "title": "Recommendation",
          "platform": "Platform Name",
          "author": "Author Name"
        }
      ]
      ''';

      final response = await model.generateContent([
        Content.text(prompt)
      ]);

      // Parse the JSON response
      List<Map<String, dynamic>> recommendations = 
        (jsonDecode(response.text ?? '[]') as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

      return recommendations;
    } catch (e) {
      print('Gemini API Error: $e');
      return [];
    }
  }
}