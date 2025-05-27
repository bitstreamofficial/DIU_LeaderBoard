import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  // 1. Update to Gemini API endpoint and model
  static const String _geminiApiModel =
      'gemini-1.5-flash-latest'; // Or 'gemini-pro'
  static const String _apiKey = 'AIzaSyAXT0R6A3fOr8V7IMiCF3JyZPFAVRJIsg';

  // Construct the Gemini API URL
  static String get _geminiApiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiApiModel:generateContent?key=$_apiKey';

  static Future<List<Map<String, String>>> getRecommendations(
    String courseTitle,
    String grade,
    double points,
  ) async {
    try {
      final prompt = '''
        As an academic advisor, provide learning recommendations for a student who scored $grade ($points points) in $courseTitle.
        Format your response strictly as:
        COURSE: [name] on [platform] - [description]
        BOOK: [title] by [author] - [description]
        PROJECT: [name] - [description]
        Provide at least one of each if possible. If you cannot find a specific item, omit that line.
      ''';

      // 2. Modify the request body for Gemini API
      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 500, // Max tokens for the generated output
          'candidateCount': 1, // Number of generated responses to return
        }
      });

      final response = await http.post(
        Uri.parse(_geminiApiUrl), // Use the new Gemini API URL
        headers: {
          'Content-Type': 'application/json',
          // Note: The API key is in the URL. If you prefer a header:
          // 'x-goog-api-key': _apiKey, // (and remove it from _geminiApiUrl)
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // 3. Adjust response parsing for Gemini API
        // Check if candidates exist and have content
        if (responseBody['candidates'] != null &&
            responseBody['candidates'].isNotEmpty &&
            responseBody['candidates'][0]['content'] != null &&
            responseBody['candidates'][0]['content']['parts'] != null &&
            responseBody['candidates'][0]['content']['parts'].isNotEmpty &&
            responseBody['candidates'][0]['content']['parts'][0]['text'] !=
                null) {
          final content =
              responseBody['candidates'][0]['content']['parts'][0]['text'];
          return _parseAIResponse(content, courseTitle);
        } else {
          print(
              'API Error: Unexpected response format from Gemini - ${response.body}');
          return _getFallbackRecommendations(courseTitle);
        }
      } else {
        print('API Error: ${response.statusCode} ${response.body}');
        return _getFallbackRecommendations(courseTitle);
      }
    } catch (e) {
      print('AI Recommendation Error: $e');
      return _getFallbackRecommendations(courseTitle);
    }
  }

  // _parseAIResponse remains largely the same if the Gemini model follows the prompt format.
  // Added robustness for parsing.
  static List<Map<String, String>> _parseAIResponse(
      String response, String courseTitle) {
    List<Map<String, String>> recommendations = [];
    final lines = response.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      try {
        if (line.startsWith('COURSE:')) {
          final content = line.substring('COURSE:'.length).trim();
          final parts = content.split(' - ');
          if (parts.length >= 2) {
            final courseAndPlatform = parts[0].split(' on ');
            if (courseAndPlatform.length >= 2) {
              recommendations.add({
                'type': 'Course',
                'title': courseAndPlatform[0].trim(),
                'platform': courseAndPlatform[1].trim(),
                'description': parts
                    .sublist(1)
                    .join(' - ')
                    .trim(), // Handle cases where description might contain '-'
              });
            }
          }
        } else if (line.startsWith('BOOK:')) {
          final content = line.substring('BOOK:'.length).trim();
          final parts = content.split(' - ');
          if (parts.length >= 2) {
            final titleAndAuthor = parts[0].split(' by ');
            if (titleAndAuthor.length >= 2) {
              recommendations.add({
                'type': 'Book',
                'title': titleAndAuthor[0].trim(),
                'author': titleAndAuthor[1].trim(),
                'description': parts.sublist(1).join(' - ').trim(),
              });
            }
          }
        } else if (line.startsWith('PROJECT:')) {
          final content = line.substring('PROJECT:'.length).trim();
          final parts = content.split(' - ');
          if (parts.length >= 2) {
            recommendations.add({
              'type': 'Project',
              'title': parts[0].trim(),
              'description': parts.sublist(1).join(' - ').trim(),
            });
          }
        }
      } catch (e) {
        print("Error parsing line: '$line'. Error: $e");
        // Optionally, skip this line or handle the error as appropriate
      }
    }
    return recommendations.isEmpty
        ? _getFallbackRecommendations(courseTitle)
        : recommendations;
  }

  // _getFallbackRecommendations remains unchanged
  static List<Map<String, String>> _getFallbackRecommendations(
      String courseTitle) {
    // ... (your existing fallback logic)
    return [
      {
        'type': 'Course',
        'title': 'Comprehensive $courseTitle',
        'platform': 'Coursera',
        'description': 'Master the fundamentals and advanced concepts'
      },
      {
        'type': 'Book',
        'title': 'Essential Guide to $courseTitle',
        'author': 'Field Experts',
        'description': 'Detailed coverage with practical examples'
      },
      {
        'type': 'Project',
        'title': 'Applied $courseTitle Project',
        'description': 'Hands-on project to reinforce your learning'
      }
    ];
  }

  // getRecommendationsForCourse remains unchanged as it's hardcoded logic
  static List<Map<String, String>> getRecommendationsForCourse(
    String courseTitle,
    String grade,
    double points,
  ) {
    // ... (your existing conditional logic)
    if (points < 3.0) {
      if (courseTitle.toLowerCase().contains('programming') ||
          courseTitle.toLowerCase().contains('coding')) {
        return [
          {
            'type': 'Course',
            'title': 'Programming Fundamentals Masterclass',
            'platform': 'Coursera',
            'description':
                'Strengthen your programming foundations with practical exercises'
          },
          {
            'type': 'Book',
            'title': 'Clean Code: A Handbook of Agile Software',
            'author': 'Robert C. Martin',
            'description': 'Learn industry-standard coding practices'
          },
          {
            'type': 'Practice',
            'title': 'Coding Practice Platforms',
            'description': 'Practice on LeetCode, HackerRank, and CodeForces'
          }
        ];
      } else if (courseTitle.toLowerCase().contains('algorithm')) {
        return [
          {
            'type': 'Course',
            'title': 'Algorithms Specialization',
            'platform': 'Stanford Online',
            'description': 'Master algorithmic techniques and problem solving'
          },
          {
            'type': 'Book',
            'title': 'Introduction to Algorithms',
            'author': 'CLRS',
            'description': 'Comprehensive guide to algorithm design'
          },
          {
            'type': 'Practice',
            'title': 'Algorithm Visualization',
            'description': 'Use VisuAlgo to understand algorithm behavior'
          }
        ];
      } else if (courseTitle.toLowerCase().contains('database')) {
        return [
          {
            'type': 'Course',
            'title': 'Database Management Essentials',
            'platform': 'Coursera',
            'description': 'Learn database design and SQL optimization'
          },
          {
            'type': 'Book',
            'title': 'Database System Concepts',
            'author': 'Silberschatz',
            'description': 'In-depth coverage of database principles'
          },
          {
            'type': 'Practice',
            'title': 'SQL Practice',
            'description': 'Practice on SQLZoo and HackerRank SQL challenges'
          }
        ];
      } else if (courseTitle.toLowerCase().contains('math')) {
        return [
          {
            'type': 'Course',
            'title': 'Mathematics for Computer Science',
            'platform': 'MIT OpenCourseWare',
            'description': 'Strengthen mathematical foundations'
          },
          {
            'type': 'Book',
            'title': 'Discrete Mathematics and Its Applications',
            'author': 'Kenneth Rosen',
            'description': 'Clear explanations with examples'
          },
          {
            'type': 'Practice',
            'title': 'Problem Solving',
            'description': 'Practice on Project Euler and Math Exchange'
          }
        ];
      }

      // Default recommendations for points < 3.0
      return [
        {
          'type': 'Course',
          'title': 'Comprehensive Guide to $courseTitle',
          'platform': 'Coursera',
          'description': 'Master core concepts and practical applications'
        },
        {
          'type': 'Book',
          'title': 'Essential $courseTitle Guide',
          'author': 'Field Experts',
          'description': 'In-depth coverage with examples'
        },
        {
          'type': 'Practice',
          'title': 'Regular Practice Sessions',
          'description': 'Dedicate 2-3 hours daily for practice and revision'
        }
      ];
    }
    // If points >= 3.0, the original code returned [],
    // implying that getRecommendations (the LLM call) should be used.
    // If you want to provide hardcoded recommendations for high scores too,
    // add them here. Otherwise, returning [] is fine if the intent is to
    // always call the LLM for scores >= 3.0.
    // For clarity, let's explicitly return an empty list if the intent is that
    // no specific hardcoded recommendations are given for higher scores,
    // and the LLM should be the primary source.
    // However, the current structure calls getRecommendations and then
    // this getRecommendationsForCourse. It seems getRecommendationsForCourse
    // is meant for specific overrides or additions.
    // The original logic would try the LLM first, and if that fails or for specific cases,
    // this method might be called. Let's assume the intent of getRecommendationsForCourse
    // is to provide specific hardcoded sets based on courseTitle IF points < 3.0.
    // If points >= 3.0, no specific hardcoded sets are returned by *this* particular method.
    return [];
  }
}
