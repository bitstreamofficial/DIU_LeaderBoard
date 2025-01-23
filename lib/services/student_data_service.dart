// student_data_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDataService {
  // Singleton pattern
  static final StudentDataService _instance = StudentDataService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  factory StudentDataService() {
    return _instance;
  }

  StudentDataService._internal();
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('students').doc(userId).get();
      print(docSnapshot);

      if (!docSnapshot.exists) {
        throw Exception('User data not found2');
      }

      return docSnapshot.data();
    } catch (e) {
      print('Error fetching user data: $e');
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<Map<String, dynamic>> fetchStudentInfo(String studentId) async {
    try {
      final infoUrl = Uri.parse(
        'http://software.diu.edu.bd:8006/result/studentInfo?studentId=$studentId',
      );
      final infoResponse = await http.get(infoUrl);

      if (infoResponse.statusCode != 200) {
        throw 'Failed to fetch student information';
      }

      return json.decode(infoResponse.body);
    } catch (e) {
      throw 'Error fetching student info: ${e.toString()}';
    }
  }

Future<Map<String, List<dynamic>>> fetchResults(String studentId) async {
  try {
    // List of valid semester IDs
    List<String> validSemesterIds = [
      "244", "243", "242", "241", "233", "232", "231", "223", "222", "221",
      "213", "212", "211", "203", "202", "201", "193", "192", "191", "183",
      "182", "181", "173", "172", "171", "163", "162", "161", "153", "152",
      "151", "143", "142", "141", "133", "132", "131", "123", "122", "121",
      "113", "112", "111", "103", "102", "101", "093", "092", "091", "083"
    ];

    final startSemester = studentId.split('-')[0];
    final currentSemester = '244'; // Update this as needed

    List<String> semesterIdsInRange = validSemesterIds.where((semesterId) {
      return int.parse(semesterId) >= int.parse(startSemester) &&
          int.parse(semesterId) <= int.parse(currentSemester);
    }).toList().reversed.toList();

    print(semesterIdsInRange);

    Map<String, List<dynamic>> semesterResults = {};
    Map<String, String> latestSemesterForCourse = {};

    for (final semesterId in semesterIdsInRange) {
      final resultUrl = Uri.parse(
        'http://software.diu.edu.bd:8006/result?grecaptcha=&semesterId=$semesterId&studentId=$studentId',
      );

      try {
        final resultResponse = await http.get(resultUrl);
        if (resultResponse.statusCode == 200) {
          final results = json.decode(resultResponse.body);
          if (results is List && results.isNotEmpty) {
            for (var result in results) {
              String customCourseId = result['customCourseId'];

              if (latestSemesterForCourse.containsKey(customCourseId)) {
                String previousSemester = latestSemesterForCourse[customCourseId]!;
                semesterResults[previousSemester]?.removeWhere(
                  (course) => course['customCourseId'] == customCourseId,
                );
              }

              latestSemesterForCourse[customCourseId] = semesterId;

              if (!semesterResults.containsKey(semesterId)) {
                semesterResults[semesterId] = [];
              }
              semesterResults[semesterId]!.add(result);
            }
          }
        }
      } catch (e) {
        print('Error fetching semester $semesterId: $e');
      }
    }

    if (semesterResults.isEmpty) {
      throw 'No results found for any semester';
    }

    return semesterResults;
  } catch (e) {
    throw 'Error fetching results: ${e.toString()}';
  }
}



  double calculateOverallCGPA(Map<String, List<dynamic>> semesterResults) {
    try {
      double totalPoints = 0;
      double totalCredits = 0;

      semesterResults.forEach((_, results) {
        for (var result in results) {
          double credit =
              double.parse(result['totalCredit']?.toString() ?? '0');
          double points =
              double.parse(result['pointEquivalent']?.toString() ?? '0');

          totalPoints += (credit * points);
          totalCredits += credit;
        }
      });

      return totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;
    } catch (e) {
      throw 'Error calculating CGPA: ${e.toString()}';
    }
  }

  double calculateSemesterCGPA(List<dynamic> results) {
    try {
      double totalPoints = 0;
      double totalCredits = 0;

      for (var result in results) {
        double credit = double.parse(result['totalCredit']?.toString() ?? '0');
        double points =
            double.parse(result['pointEquivalent']?.toString() ?? '0');

        totalPoints += (credit * points);
        totalCredits += credit;
      }

      return totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;
    } catch (e) {
      throw 'Error calculating semester CGPA: ${e.toString()}';
    }
  }

  Future<void> storeUserData({
    required String userId,
    required String studentId,
    required String email,
    required Map<String, dynamic> studentInfo,
    required double cgpa,
  }) async {
    try {
      final department = studentInfo['deptShortName'];
      final batch = studentInfo['batchNo'].toString();

      // Generate dept_batch field
      final deptBatch = '${department}_${batch}';

      await FirebaseFirestore.instance.collection('students').doc(userId).set({
        'studentId': studentId,
        'email': email,
        'department': department,
        'batch': batch,
        'program': studentInfo['programName'],
        'cgpa': cgpa,
        'name': studentInfo['studentName'],
        'dept_batch': deptBatch,
        'createdAt': FieldValue.serverTimestamp(),
        'showMe': true,
      });
    } catch (e) {
      throw 'Error storing user data: ${e.toString()}';
    }
  }
}
