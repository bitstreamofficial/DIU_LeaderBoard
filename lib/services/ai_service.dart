import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const _huggingFaceApiUrl = 'https://api-inference.huggingface.co/models/google/flan-t5-xxl';
  static const _apiKey = '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'; // Replace with your API key

  static Future<List<Map<String, String>>> getRecommendations(
    String courseTitle,
    String grade,
    double points,
  ) async {
    try {
      final prompt = '''
        As an academic advisor, provide learning recommendations for a student who scored $grade ($points points) in $courseTitle.
        Format your response as:
        COURSE: [name] on [platform] - [description]
        BOOK: [title] by [author] - [description]
        PROJECT: [name] - [description]
      ''';

      final response = await http.post(
        Uri.parse(_huggingFaceApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_length': 500,
            'temperature': 0.7,
            'num_return_sequences': 1,
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final content = responseBody[0]['generated_text'];
        return _parseAIResponse(content, courseTitle);
      } else {
        print('API Error: ${response.body}');
        return _getFallbackRecommendations(courseTitle);
      }
    } catch (e) {
      print('AI Recommendation Error: $e');
      return _getFallbackRecommendations(courseTitle);
    }
  }

  static List<Map<String, String>> _parseAIResponse(String response, String courseTitle) {
    List<Map<String, String>> recommendations = [];
    
    final lines = response.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('COURSE:')) {
        final parts = line.substring(7).split('-');
        final courseParts = parts[0].split('on');
        recommendations.add({
          'type': 'Course',
          'title': courseParts[0].trim(),
          'platform': courseParts[1].trim(),
          'description': parts[1].trim(),
        });
      } else if (line.startsWith('BOOK:')) {
        final parts = line.substring(5).split('-');
        final bookParts = parts[0].split('by');
        recommendations.add({
          'type': 'Book',
          'title': bookParts[0].trim(),
          'author': bookParts[1].trim(),
          'description': parts[1].trim(),
        });
      } else if (line.startsWith('PROJECT:')) {
        final parts = line.substring(8).split('-');
        recommendations.add({
          'type': 'Project',
          'title': parts[0].trim(),
          'description': parts[1].trim(),
        });
      }
    }

    return recommendations.isEmpty ? _getFallbackRecommendations(courseTitle) : recommendations;
  }

  static List<Map<String, String>> _getFallbackRecommendations(String courseTitle) {
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

  static List<Map<String, String>> getRecommendationsForCourse(
    String courseTitle,
    String grade,
    double points,
  ) {
    if (points < 3.0) {
      if (courseTitle.toLowerCase().contains('programming') || 
          courseTitle.toLowerCase().contains('coding')) {
        return [
          {
            'type': 'Course',
            'title': 'Programming Fundamentals Masterclass',
            'platform': 'Coursera',
            'description': 'Strengthen your programming foundations with practical exercises'
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
      
      // Default recommendations
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
    return [];
  }
}