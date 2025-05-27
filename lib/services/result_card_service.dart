import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';

class ResultCardService {
  static final PdfColor primaryColor = PdfColor.fromHex('#1a237e'); // Deep blue
  static final PdfColor secondaryColor = PdfColor.fromHex('#0277bd'); // Light blue
  static final PdfColor accentColor = PdfColor.fromHex('#4fc3f7'); // Sky blue
  static final PdfColor successColor = PdfColor.fromHex('#43a047'); // Green
  
  static Future<void> generateAndDownloadPDF({
    required Map<String, dynamic>? studentInfo,
    required Map<String, List<dynamic>>? semesterResults,
    required double? overallCGPA,
    required Function(bool) setLoading,
    required BuildContext context,
  }) async {
    try {
      setLoading(true);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header with Institution Name and Logo Area
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: primaryColor, width: 2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                padding: pw.EdgeInsets.all(15),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Academic Result Card',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Academic Transcript',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      width: 100,
                      height: 100,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accentColor),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          studentInfo?['studentName']?.toString().substring(0, 1).toUpperCase() ?? '?',
                          style: pw.TextStyle(
                            fontSize: 48,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Student Information Section
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: secondaryColor),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                padding: pw.EdgeInsets.all(15),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Name', studentInfo?['studentName'] ?? 'N/A'),
                            pw.SizedBox(height: 5),
                            _buildInfoRow('Student ID', studentInfo?['studentId'] ?? 'N/A'),
                          ],
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: successColor,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'Overall CGPA',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 12,
                                ),
                              ),
                              pw.Text(
                                overallCGPA?.toStringAsFixed(2) ?? 'N/A',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Semester Results
              if (semesterResults != null) ...semesterResults.entries.map((entry) {
                final semester = entry.key;
                final results = entry.value;
                if (results.isEmpty) return pw.Container();

                final firstResult = results[0] as Map<String, dynamic>;
                
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: secondaryColor),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: pw.BoxDecoration(
                          color: secondaryColor,
                          borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${firstResult['semesterName']} ${firstResult['semesterYear']}',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Semester CGPA: ${firstResult['cgpa']?.toString() ?? 'N/A'}',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Table.fromTextArray(
                        context: context,
                        headerDecoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        headerHeight: 40,
                        cellHeight: 30,
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                        cellStyle: pw.TextStyle(
                          fontSize: 12,
                        ),
                        cellAlignment: pw.Alignment.center,
                        headers: ['Course Code', 'Course Title', 'Grade'],
                        data: results.map<List<String>>((course) => [
                          course['customCourseId'] ?? 'N/A',
                          course['courseTitle'] ?? 'N/A',
                          course['gradeLetter'] ?? 'N/A',
                        ]).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Footer
              pw.Padding(
                padding: pw.EdgeInsets.only(top: 20),
                child: pw.Center(
                  child: pw.Text(
                    'Generated on ${DateTime.now()}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${studentInfo?['studentId'] ?? 'result'}_academic_transcript.pdf';
      final file = File('${directory.path}/$fileName');

      // Save the PDF
      await file.writeAsBytes(await pdf.save());

      // Open the PDF
      await OpenFile.open(file.path);

      setLoading(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result card downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            color: PdfColors.grey700,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}