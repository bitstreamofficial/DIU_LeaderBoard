class Student {
  final int rank;
  final String id;
  final String name;
  final String program;
  final String department;
  final String batch;
  final double cgpa;

  Student({
    required this.rank,
    required this.id,
    required this.name,
    required this.program,
    required this.department,
    required this.batch,
    required this.cgpa,
  });

  //Local CSV
  // factory Student.fromCsvRow(List<dynamic> row) {
  //   return Student(
  //     rank: int.parse(row[0].toString()),
  //     id: row[1].toString(),
  //     name: row[2].toString(),
  //     program: row[3].toString(),
  //     department: row[4].toString(),
  //     batch: row[5].toString(),
  //     cgpa: double.parse(row[6].toString()),
  //   );
  // }

  factory Student.fromMap(Map<String, dynamic> data) {
    return Student(
      // Ensure the keys match exactly what's in your Firestore documents
      // (which are the headers from your CSV)
      rank: int.tryParse(data['Rank']?.toString() ?? '0') ?? 0,
      id: data['Student ID']?.toString() ?? '',
      name: data['Name']?.toString() ?? 'Unknown',
      program: data['Program']?.toString() ?? '',
      department: data['Department']?.toString() ?? '',
      batch: data['Batch']?.toString() ?? '',
      cgpa: double.tryParse(data['Overall CGPA']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}
