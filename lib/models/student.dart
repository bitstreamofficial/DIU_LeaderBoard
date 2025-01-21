
class Student {
  final String id;
  final String name;
  final String program;
  final String department;
  final String batch;
  final double cgpa;
  final int rank;

  Student({
    required this.id,
    required this.name,
    required this.program,
    required this.department,
    required this.batch,
    required this.cgpa,
    required this.rank,
  });

  factory Student.fromCsvRow(List<dynamic> row) {
    return Student(
      rank: int.parse(row[0].toString()),
      id: row[1].toString(),
      name: row[2].toString(),
      program: row[3].toString(),
      department: row[4].toString(),
      batch: row[5].toString(),
      cgpa: double.parse(row[6].toString()),
    );
  }
}