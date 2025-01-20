import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_model.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static Future<StudentInfo> getStudentInfo(String studentId) async {
    try {
      debugPrint('Fetching student info for ID: $studentId');
      final response = await http.get(
        Uri.parse('http://software.diu.edu.bd:8006/result/studentInfo?studentId=$studentId'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout. Please try again.'),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }

        try {
          final jsonData = json.decode(response.body);
          if (jsonData == null) {
            throw Exception('Null response from server');
          }

          // Log the structure of the response
          debugPrint('JSON data structure: ${jsonData.runtimeType}');
          debugPrint('JSON data keys: ${jsonData is Map ? jsonData.keys.toString() : 'Not a map'}');

          final studentInfo = StudentInfo.fromJson(jsonData);
          
          // Validate essential fields
          if (studentInfo.studentId?.isEmpty ?? true) {
            throw Exception('Invalid student data received');
          }

          return studentInfo;
        } catch (e) {
          debugPrint('JSON parsing error: $e');
          throw Exception('Invalid response format: ${e.toString()}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Student not found');
      } else {
        throw Exception('Server error (${response.statusCode}). Please try again later.');
      }
    } catch (e) {
      debugPrint('API Error: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection');
      }
      rethrow;
    }
  }

  static final List<Map<String, String>> semestersList = [
    {"semesterId": "244", "semesterYear": "2024", "semesterName": "Short"},
    {"semesterId": "243", "semesterYear": "2024", "semesterName": "Fall"},
    {"semesterId": "242", "semesterYear": "2024", "semesterName": "Summer"},
    {"semesterId": "241", "semesterYear": "2024", "semesterName": "Spring"},
    {"semesterId": "233", "semesterYear": "2023", "semesterName": "Fall"},
    {"semesterId": "232", "semesterYear": "2023", "semesterName": "Summer"},
    {"semesterId": "231", "semesterYear": "2023", "semesterName": "Spring"},
    {"semesterId": "223", "semesterYear": "2022", "semesterName": "Fall"},
    {"semesterId": "222", "semesterYear": "2022", "semesterName": "Summer"},
    {"semesterId": "221", "semesterYear": "2022", "semesterName": "Spring"},
    {"semesterId": "213", "semesterYear": "2021", "semesterName": "Fall"},
    {"semesterId": "212", "semesterYear": "2021", "semesterName": "Summer"},
    {"semesterId": "211", "semesterYear": "2021", "semesterName": "Spring"},
    {"semesterId": "203", "semesterYear": "2020", "semesterName": "Fall"},
    {"semesterId": "202", "semesterYear": "2020", "semesterName": "Summer"},
    {"semesterId": "201", "semesterYear": "2020", "semesterName": "Spring"},
    {"semesterId": "193", "semesterYear": "2019", "semesterName": "Fall"},
    {"semesterId": "192", "semesterYear": "2019", "semesterName": "Summer"},
    {"semesterId": "191", "semesterYear": "2019", "semesterName": "Spring"},
    {"semesterId": "183", "semesterYear": "2018", "semesterName": "Fall"},
    {"semesterId": "182", "semesterYear": "2018", "semesterName": "Summer"},
    {"semesterId": "181", "semesterYear": "2018", "semesterName": "Spring"},
    {"semesterId": "173", "semesterYear": "2017", "semesterName": "Fall"},
    {"semesterId": "172", "semesterYear": "2017", "semesterName": "Summer"},
    {"semesterId": "171", "semesterYear": "2017", "semesterName": "Spring"},
    {"semesterId": "163", "semesterYear": "2016", "semesterName": "Fall"},
    {"semesterId": "162", "semesterYear": "2016", "semesterName": "Summer"},
    {"semesterId": "161", "semesterYear": "2016", "semesterName": "Spring"},
    {"semesterId": "153", "semesterYear": "2015", "semesterName": "Fall"},
    {"semesterId": "152", "semesterYear": "2015", "semesterName": "Summer"},
    {"semesterId": "151", "semesterYear": "2015", "semesterName": "Spring"},
    {"semesterId": "143", "semesterYear": "2014", "semesterName": "Fall"},
    {"semesterId": "142", "semesterYear": "2014", "semesterName": "Summer"},
    {"semesterId": "141", "semesterYear": "2014", "semesterName": "Spring"},
    {"semesterId": "133", "semesterYear": "2013", "semesterName": "Fall"},
    {"semesterId": "132", "semesterYear": "2013", "semesterName": "Summer"},
    {"semesterId": "131", "semesterYear": "2013", "semesterName": "Spring"},
    {"semesterId": "123", "semesterYear": "2012", "semesterName": "Fall"},
    {"semesterId": "122", "semesterYear": "2012", "semesterName": "Summer"},
    {"semesterId": "121", "semesterYear": "2012", "semesterName": "Spring"},
    {"semesterId": "113", "semesterYear": "2011", "semesterName": "Fall"},
    {"semesterId": "112", "semesterYear": "2011", "semesterName": "Summer"},
    {"semesterId": "111", "semesterYear": "2011", "semesterName": "Spring"},
    {"semesterId": "103", "semesterYear": "2010", "semesterName": "Fall"},
    {"semesterId": "102", "semesterYear": "2010", "semesterName": "Summer"},
    {"semesterId": "101", "semesterYear": "2010", "semesterName": "Spring"},
    {"semesterId": "093", "semesterYear": "2009", "semesterName": "Fall"},
    {"semesterId": "092", "semesterYear": "2009", "semesterName": "Summer"},
    {"semesterId": "091", "semesterYear": "2009", "semesterName": "Spring"},
    {"semesterId": "083", "semesterYear": "2008", "semesterName": "Fall"},
  ];

  static Future<List<Map<String, dynamic>>> getSemesterResults(String studentId, String semesterId) async {
    try {
      debugPrint('Fetching results for semester: $semesterId');
      final response = await http.get(
        Uri.parse('http://software.diu.edu.bd:8006/result?grecaptcha=&semesterId=$semesterId&studentId=$studentId'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('Found ${data.length} courses for semester $semesterId');
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching semester $semesterId: $e');
      return [];
    }
  }
} 