class CourseResult {
  final String courseTitle;
  final double totalCredit;
  final String gradeLetter;
  final double pointEquivalent;

  CourseResult({
    required this.courseTitle,
    required this.totalCredit,
    required this.gradeLetter,
    required this.pointEquivalent,
  });

  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'courseTitle': courseTitle,
      'totalCredit': totalCredit,
      'gradeLetter': gradeLetter,
      'pointEquivalent': pointEquivalent,
    };
  }

  // Create from Map for deserialization
  factory CourseResult.fromMap(Map<String, dynamic> map) {
    return CourseResult(
      courseTitle: map['courseTitle'] as String,
      totalCredit: double.parse(map['totalCredit'].toString()),
      gradeLetter: map['gradeLetter'] as String,
      pointEquivalent: double.parse(map['pointEquivalent'].toString()),
    );
  }
}

class SemesterResult {
  final String name;
  final int year;
  final double credits;
  final double sgpa;
  final List<CourseResult> courses;

  SemesterResult({
    required this.name,
    required this.year,
    required this.credits,
    required this.sgpa,
    required this.courses,
  });

  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'year': year,
      'credits': credits,
      'sgpa': sgpa,
      'courses': courses.map((course) => course.toMap()).toList(),
    };
  }

  // Create from Map for deserialization
  factory SemesterResult.fromMap(Map<String, dynamic> map) {
    return SemesterResult(
      name: map['name'] as String,
      year: map['year'] as int,
      credits: double.parse(map['credits'].toString()),
      sgpa: double.parse(map['sgpa'].toString()),
      courses: (map['courses'] as List)
          .map((course) => CourseResult.fromMap(course as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CGPAResult {
  final double cgpa;
  final int totalCredits;
  final List<SemesterResult> semesters;
  final String? studentName;
  final String? programName;
  final String? batchNo;

  CGPAResult({
    required this.cgpa,
    required this.totalCredits,
    required this.semesters,
    this.studentName,
    this.programName,
    this.batchNo,
  });

  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'cgpa': cgpa,
      'totalCredits': totalCredits,
      'semesters': semesters.map((semester) => semester.toMap()).toList(),
    };
  }

  // Create from Map for deserialization
  factory CGPAResult.fromMap(Map<String, dynamic> map) {
    return CGPAResult(
      cgpa: double.parse(map['cgpa'].toString()),
      totalCredits: map['totalCredits'] as int,
      semesters: (map['semesters'] as List)
          .map((semester) => SemesterResult.fromMap(semester as Map<String, dynamic>))
          .toList(),
    );
  }
} 