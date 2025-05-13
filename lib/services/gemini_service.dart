import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:diuleaderboard/services/api_constant.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  Future<List<Map<String, dynamic>>> getRecommendationsForCourse(
    String courseTitle,
    String currentGrade,
    double pointEquivalent,
  ) async {
    try {
      final prompt = '''
      As an academic advisor AI, provide specific recommendations for a student studying $courseTitle who received a grade of $currentGrade (GPA: $pointEquivalent).
      
      Provide 4-5 highly specific recommendations including:
      1. Online courses from Coursera, edX, or Udemy related to $courseTitle
      2. YouTube video tutorials with actual channel names
      3. Specific textbooks or online reading materials with links
      4. Practice websites or resources specific to $courseTitle
      
      For each recommendation, provide:
      - Type (use: "Course", "Video", "Book", "Resource")
      - Specific title
      - Brief, helpful description
      - Actual working link (use real URLs for Coursera, YouTube, etc.)
      
      Format in JSON like:
      [
        {
          "type": "Course",
          "title": "Actual Course Title",
          "description": "Specific description",
          "link": "actual_url"
        }
      ]
      
      Focus on practical, accessible resources that will help improve understanding of $courseTitle.
      Only respond with the JSON array of recommendations and nothing else.
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _getDefaultCourseRecommendations(courseTitle);
      }

      final jsonString = _extractJsonFromText(responseText);
      List<dynamic> parsedJson = [];
      try {
        parsedJson = await compute(_parseJson, jsonString);
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        return _getDefaultCourseRecommendations(courseTitle);
      }

      return parsedJson
          .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      return _getDefaultCourseRecommendations(courseTitle);
    }
  }

  List<Map<String, dynamic>> _getDefaultCourseRecommendations(
      String courseTitle) {
    return [
      {
        "type": "Course",
        "title": "Introduction to $courseTitle",
        "description":
            "Comprehensive Coursera course covering fundamentals of $courseTitle",
        "link":
            "https://www.coursera.org/search?query=${Uri.encodeComponent(courseTitle)}"
      },
      {
        "type": "Video",
        "title": "$courseTitle Fundamentals",
        "description": "Clear explanations of core concepts by freeCodeCamp",
        "link":
            "https://www.youtube.com/results?search_query=${Uri.encodeComponent('$courseTitle tutorial freeCodeCamp')}"
      },
      {
        "type": "Book",
        "title": "Essential $courseTitle Guide",
        "description": "Comprehensive textbook covering all major topics",
        "link":
            "https://www.amazon.com/s?k=${Uri.encodeComponent('$courseTitle textbook')}"
      },
      {
        "type": "Resource",
        "title": "Practice Problems",
        "description": "Interactive exercises and problem sets",
        "link":
            "https://www.khanacademy.org/search?search_again=1&page_search_query=${Uri.encodeComponent(courseTitle)}"
      }
    ];
  }

  Future<List<Map<String, dynamic>>> getRecommendationsForLowCGPA(double cgpa,
      {String? major, int? year, List<String>? weakCourses}) async {
    try {
      // Create a detailed prompt for the AI based on CGPA and optional context
      String contextInfo = '';
      if (major != null) {
        contextInfo += 'Major: $major\n';
      }
      if (year != null) {
        contextInfo += 'Year of study: $year\n';
      }
      if (weakCourses != null && weakCourses.isNotEmpty) {
        contextInfo +=
            'Courses with lower performance: ${weakCourses.join(', ')}\n';
      }

      final prompt = '''
      As an academic advisor AI, provide comprehensive recommendations for a student with a CGPA of $cgpa, which is below the 3.00 target threshold.
      
      Additional student context:
      $contextInfo
      
      Provide 10-12 resources across the following categories to help the student improve their overall academic performance:
      
      1. Study Skills Resources (2-3 recommendations):
         - Time management techniques
         - Effective study methods
         - Note-taking strategies
         - Exam preparation techniques
      
      2. Online Courses (2-3 recommendations):
         - Skill development courses
         - Academic foundations
         - Subject-specific courses
      
      3. Learning Resources (2-3 recommendations):
         - Books for academic improvement
         - Websites for additional learning
         - Self-paced tutorials
      
      4. Support Services (2-3 recommendations):
         - Academic counseling
         - Tutoring services
         - Study groups
         - Learning centers
      
      5. Videos & Podcasts (2-3 recommendations):
         - Educational videos
         - Motivational content
         - Subject explanations
      
      For each recommendation, provide:
      - The type (use one of: "Study Skill", "Course", "Resource", "Support", "Video")
      - A specific title or name
      - A brief description (1-2 sentences)
      - A link if applicable (or 'N/A')
      
      Format each recommendation in JSON format like this:
      {"type": "Study Skill", "title": "Title", "description": "Description", "link": "URL or N/A"}
      
      Only respond with the JSON array of recommendations and nothing else.
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        // If no response, return fallback recommendations
        return _getFallbackRecommendations();
      }

      // Parse the JSON response
      final jsonString = _extractJsonFromText(responseText);

      List<dynamic> parsedJson = [];
      try {
        parsedJson = await compute(_parseJson, jsonString);
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        return _getFallbackRecommendations();
      }

      // Convert to the expected format
      return parsedJson
          .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting CGPA recommendations: $e');
      return _getFallbackRecommendations();
    }
  }

  // Helper method to extract JSON from text (which might be wrapped in markdown code blocks)
  String _extractJsonFromText(String text) {
    // Check if the response is wrapped in a code block
    final codeBlockRegExp = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlockRegExp.firstMatch(text);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }

    // If not in a code block, return the original text
    return text.trim();
  }

  // This method will be run in a separate isolate to parse JSON
  static List<dynamic> _parseJson(String jsonString) {
    return jsonDecode(jsonString) as List<dynamic>;
  }

  // Fallback recommendations in case the AI service fails
  List<Map<String, dynamic>> _getFallbackRecommendations() {
    return [
      {
        "type": "Study Skill",
        "title": "Pomodoro Technique",
        "description":
            "A time management method that uses 25-minute focused work sessions followed by 5-minute breaks to improve concentration and productivity.",
        "link": "N/A"
      },
      {
        "type": "Study Skill",
        "title": "Active Recall",
        "description":
            "A study technique that involves actively stimulating memory during the learning process, rather than passively reviewing material.",
        "link": "N/A"
      },
      {
        "type": "Course",
        "title": "Learning How to Learn",
        "description":
            "A highly-rated online course that teaches scientifically-proven learning techniques to help students improve their study habits.",
        "link": "https://www.coursera.org/learn/learning-how-to-learn"
      },
      {
        "type": "Resource",
        "title": "Anki Flashcards",
        "description":
            "A digital flashcard program that uses spaced repetition to help you memorize information more efficiently.",
        "link": "https://apps.ankiweb.net/"
      },
      {
        "type": "Video",
        "title": "How to Study Effectively for School or College",
        "description":
            "A comprehensive video guide on effective study techniques backed by cognitive science research.",
        "link": "https://www.youtube.com/watch?v=IlU-zDU6aQ0"
      },
      {
        "type": "Support",
        "title": "Academic Advising Office",
        "description":
            "Schedule a meeting with an academic advisor who can help create a personalized study plan and connect you with university resources.",
        "link": "N/A"
      }
    ];
  }
}
