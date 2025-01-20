class StudentInfo {
  final String? studentId;
  final String? studentName;
  final String? programName;
  final String? departmentName;
  final String? batchNo;
  final String? shift;

  StudentInfo({
    this.studentId,
    this.studentName,
    this.programName,
    this.departmentName,
    this.batchNo,
    this.shift,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    // Handle potential nested data structure
    final data = json['data'] ?? json;
    
    return StudentInfo(
      studentId: data['studentId']?.toString() ?? '',
      studentName: data['studentName']?.toString() ?? '',
      programName: data['programName']?.toString() ?? '',
      departmentName: data['departmentName']?.toString() ?? '',
      batchNo: data['batchNo']?.toString() ?? '',
      shift: data['shift']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'StudentInfo(studentId: $studentId, studentName: $studentName, programName: $programName, departmentName: $departmentName, batchNo: $batchNo, shift: $shift)';
  }
} 