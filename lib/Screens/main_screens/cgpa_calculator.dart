// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'dart:math';
// import 'package:fl_chart/fl_chart.dart';
// import '../../models/semester_model.dart';
// import '../../models/student_model.dart';
// import '../../services/api_service.dart';
// import '../../services/student_data_service.dart';
// import '../../models/semester_model.dart';

// // CGPA Calculator Tab
// class CGPACalculatorTab extends StatefulWidget {
//   const CGPACalculatorTab({super.key});

//   @override
//   State<CGPACalculatorTab> createState() => _CGPACalculatorTabState();
// }

// class _CGPACalculatorTabState extends State<CGPACalculatorTab>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _studentIdController = TextEditingController();
//   final _studentDataService = StudentDataService();
//   bool _isLoading = false;
//   CGPAResult? _result;
//   late AnimationController _gradientController;
//   double _animationValue = 0.0;

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildCalculatorForm(),
//           if (_isLoading)
//             const LoadingAnimation()
//           else if (_result != null)
//             _buildResults(_result!),
//         ],
//       ),
//     );
//   }

//   Widget _buildResults(CGPAResult result) {
//     return Column(
//       children: [
//         const SizedBox(height: 24),
//         Container(
//           width: double.infinity,
//           constraints: const BoxConstraints(
//             maxWidth: 500,
//           ),
//           child: Card(
//             elevation: 4,
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Color(0xFFC33764),
//                     Color(0xFF6E388F),
//                     Color(0xFF1D2671),
//                   ].map((color) => color.withOpacity(0.8)).toList(),
//                   stops: const [0.0, 0.5, 1.0],
//                   transform: GradientRotation(_animationValue * 2 * pi),
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                     vertical: 24.0, horizontal: 20.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (result.studentName != null)
//                       Text(
//                         result.studentName!,
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 22,
//                             ),
//                         textAlign: TextAlign.center,
//                       ),
//                     if (result.programName != null) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         result.programName!,
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 16,
//                             ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                     if (result.batchNo != null) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         'Batch: ${result.batchNo}',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 16,
//                             ),
//                       ),
//                     ],
//                     const SizedBox(height: 20),
//                     Text(
//                       result.cgpa.toStringAsFixed(2),
//                       style: Theme.of(context).textTheme.displayLarge?.copyWith(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 48,
//                           ),
//                     ),
//                     Text(
//                       'CGPA',
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             color: Colors.white.withOpacity(0.9),
//                             fontSize: 18,
//                           ),
//                     ),
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.15),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         'Total Credits: ${result.totalCredits}',
//                         style:
//                             Theme.of(context).textTheme.titleMedium?.copyWith(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 32),

//         // Performance Summary Card
//         _buildPerformanceSummary(result),

//         const SizedBox(height: 24),
//         _buildSemestersList(result.semesters),
//         const SizedBox(height: 16),
//         _buildCGPAChart(result.semesters),
//       ],
//     );
//   }

//   Widget _buildInfoChip({
//     required IconData icon,
//     required String label,
//     required String value,
//     required BuildContext context,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             color: Colors.white,
//             size: 20,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//           ),
//           Text(
//             label,
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: Colors.white.withOpacity(0.8),
//                   fontSize: 12,
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPerformanceSummary(CGPAResult result) {
//     final performance = _analyzePerformance(result.cgpa);

//     return Container(
//       width: double.infinity,
//       constraints: const BoxConstraints(maxWidth: 500),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: performance['color'].withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       performance['icon'],
//                       color: performance['color'],
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Academic Performance',
//                           style:
//                               Theme.of(context).textTheme.titleMedium?.copyWith(
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                         ),
//                         Text(
//                           performance['status'],
//                           style:
//                               Theme.of(context).textTheme.bodyMedium?.copyWith(
//                                     color: performance['color'],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               LinearProgressIndicator(
//                 value: result.cgpa / 4.0,
//                 backgroundColor:
//                     Theme.of(context).colorScheme.outline.withOpacity(0.2),
//                 valueColor: AlwaysStoppedAnimation<Color>(performance['color']),
//                 minHeight: 6,
//                 borderRadius: BorderRadius.circular(3),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 performance['message'],
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurfaceVariant,
//                       height: 1.4,
//                     ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _getGrade(double cgpa) {
//     if (cgpa >= 4.0) return 'A+';
//     if (cgpa >= 3.75) return 'A';
//     if (cgpa >= 3.50) return 'A-';
//     if (cgpa >= 3.25) return 'B+';
//     if (cgpa >= 3.0) return 'B';
//     if (cgpa >= 2.75) return 'B-';
//     if (cgpa >= 2.50) return 'C+';
//     if (cgpa >= 2.25) return 'C-';
//     if (cgpa >= 2.00) return 'D';
//     return 'F';
//   }

//   Map<String, dynamic> _analyzePerformance(double cgpa) {
//     if (cgpa >= 3.5) {
//       return {
//         'status': 'Excellent Performance',
//         'color': Colors.green,
//         'icon': Icons.emoji_events,
//         'message':
//             'Outstanding academic achievement! You\'re performing exceptionally well and maintaining high standards.',
//       };
//     } else if (cgpa >= 3.0) {
//       return {
//         'status': 'Good Performance',
//         'color': Colors.blue,
//         'icon': Icons.trending_up,
//         'message':
//             'Good academic performance! You\'re on the right track. Keep up the consistent effort.',
//       };
//     } else if (cgpa >= 2.5) {
//       return {
//         'status': 'Satisfactory Performance',
//         'color': Colors.orange,
//         'icon': Icons.timeline,
//         'message':
//             'Satisfactory performance with room for improvement. Consider focusing on challenging subjects.',
//       };
//     } else {
//       return {
//         'status': 'Needs Improvement',
//         'color': Colors.red,
//         'icon': Icons.trending_down,
//         'message':
//             'There\'s room for improvement. Consider seeking additional support and developing better study strategies.',
//       };
//     }
//   }

//   Widget _buildSemestersList(List<SemesterResult> semesters) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section Header
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.calendar_view_month_rounded,
//                 color: Theme.of(context).colorScheme.primary,
//                 size: 24,
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 'Semester Performance',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: Theme.of(context).colorScheme.onBackground,
//                     ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),

//         // Semesters List
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: semesters.length,
//           itemBuilder: (context, index) {
//             final semester = semesters[index];
//             return Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               child: Card(
//                 elevation: 3,
//                 shadowColor:
//                     Theme.of(context).colorScheme.shadow.withOpacity(0.1),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: InkWell(
//                   onTap: () => _showSemesterDetails(semester),
//                   borderRadius: BorderRadius.circular(16),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       gradient: LinearGradient(
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                         colors: [
//                           Theme.of(context).colorScheme.surface,
//                           Theme.of(context)
//                               .colorScheme
//                               .surface
//                               .withOpacity(0.7),
//                         ],
//                       ),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Header Row
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       '${semester.name} ${semester.year}',
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .titleLarge
//                                           ?.copyWith(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.w600,
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .onSurface,
//                                           ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       'Semester ${index + 1}',
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .bodyMedium
//                                           ?.copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .onSurfaceVariant,
//                                             fontSize: 14,
//                                           ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               // SGPA Badge
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 8,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       _getSGPAColor(semester.sgpa),
//                                       _getSGPAColor(semester.sgpa)
//                                           .withOpacity(0.8),
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(20),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: _getSGPAColor(semester.sgpa)
//                                           .withOpacity(0.3),
//                                       blurRadius: 8,
//                                       offset: const Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Text(
//                                   'SGPA ${semester.sgpa.toStringAsFixed(2)}',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 16),

//                           // Stats Row
//                           Row(
//                             children: [
//                               _buildStatChip(
//                                 icon: Icons.credit_card_rounded,
//                                 label: 'Credits',
//                                 value: semester.credits.toStringAsFixed(1),
//                                 color: Theme.of(context).colorScheme.primary,
//                                 context: context,
//                               ),
//                               const SizedBox(width: 12),
//                               _buildStatChip(
//                                 icon: Icons.book_rounded,
//                                 label: 'Courses',
//                                 value: '${semester.courses.length}',
//                                 color: Theme.of(context).colorScheme.secondary,
//                                 context: context,
//                               ),
//                               const Spacer(),
//                               // Performance Indicator
//                               Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: _getSGPAColor(semester.sgpa)
//                                       .withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Icon(
//                                   _getPerformanceIcon(semester.sgpa),
//                                   color: _getSGPAColor(semester.sgpa),
//                                   size: 20,
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 12),

//                           // Progress Bar
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     'Performance',
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall
//                                         ?.copyWith(
//                                           color: Theme.of(context)
//                                               .colorScheme
//                                               .onSurfaceVariant,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                   ),
//                                   Text(
//                                     _getPerformanceLabel(semester.sgpa),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall
//                                         ?.copyWith(
//                                           color: _getSGPAColor(semester.sgpa),
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 6),
//                               LinearProgressIndicator(
//                                 value: semester.sgpa / 4.0,
//                                 backgroundColor: Theme.of(context)
//                                     .colorScheme
//                                     .outline
//                                     .withOpacity(0.2),
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                     _getSGPAColor(semester.sgpa)),
//                                 minHeight: 4,
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 8),

//                           // Tap hint
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               Text(
//                                 'Tap to view details',
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .bodySmall
//                                     ?.copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .onSurfaceVariant
//                                           .withOpacity(0.6),
//                                       fontSize: 12,
//                                     ),
//                               ),
//                               const SizedBox(width: 4),
//                               Icon(
//                                 Icons.arrow_forward_ios_rounded,
//                                 size: 12,
//                                 color: Theme.of(context)
//                                     .colorScheme
//                                     .onSurfaceVariant
//                                     .withOpacity(0.6),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildStatChip({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//     required BuildContext context,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: color.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             color: color,
//             size: 16,
//           ),
//           const SizedBox(width: 6),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 value,
//                 style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                       color: color,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//               ),
//               Text(
//                 label,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurfaceVariant,
//                       fontSize: 11,
//                     ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getSGPAColor(double sgpa) {
//     if (sgpa >= 3.5) return Colors.green;
//     if (sgpa >= 3.0) return Colors.blue;
//     if (sgpa >= 2.5) return Colors.orange;
//     return Colors.red;
//   }

//   IconData _getPerformanceIcon(double sgpa) {
//     if (sgpa >= 3.5) return Icons.emoji_events_rounded;
//     if (sgpa >= 3.0) return Icons.trending_up_rounded;
//     if (sgpa >= 2.5) return Icons.timeline_rounded;
//     return Icons.trending_down_rounded;
//   }

//   String _getPerformanceLabel(double sgpa) {
//     if (sgpa >= 3.5) return 'Excellent';
//     if (sgpa >= 3.0) return 'Good';
//     if (sgpa >= 2.5) return 'Average';
//     return 'Needs Improvement';
//   }

//   void _showSemesterDetails(SemesterResult semester) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => _SemesterDetailsSheet(semester: semester),
//     );
//   }

//   Widget _buildCGPAChart(List<SemesterResult> semesters) {
//     if (semesters == null || semesters.isEmpty) {
//       return Container(
//         height: 250,
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
//               SizedBox(height: 16),
//               Text(
//                 'No CGPA Data Available',
//                 style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final validSemesters = semesters
//         .where((s) =>
//             s.sgpa != null && s.sgpa.isFinite && s.sgpa >= 0 && s.sgpa <= 4.0)
//         .toList();

//     if (validSemesters.isEmpty) {
//       return Container(
//         height: 250,
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, size: 64, color: Colors.red),
//               SizedBox(height: 16),
//               Text(
//                 'Unable to Generate CGPA Chart',
//                 style: TextStyle(
//                     color: Colors.red,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'CGPA Progression',
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white),
//             ),
//             SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               width: double.infinity,
//               child: LineChart(
//                 LineChartData(
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: false,
//                     horizontalInterval: 0.5,
//                     getDrawingHorizontalLine: (value) => FlLine(
//                       color: Colors.grey.withOpacity(0.2),
//                       strokeWidth: 1,
//                     ),
//                   ),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 40,
//                         getTitlesWidget: (value, meta) {
//                           final index = value.toInt();
//                           if (index < 0 || index >= validSemesters.length)
//                             return Container();
//                           final semester = validSemesters[index];
//                           return Text(
//                             '${semester.name}\n${semester.year}',
//                             style: TextStyle(fontSize: 10, color: Colors.white),
//                             textAlign: TextAlign.center,
//                           );
//                         },
//                         interval: 1,
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           return Text(
//                             value.toStringAsFixed(1),
//                             style: TextStyle(fontSize: 10, color: Colors.white),
//                           );
//                         },
//                       ),
//                     ),
//                     topTitles:
//                         AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles:
//                         AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   borderData: FlBorderData(show: false),
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: validSemesters.asMap().entries.map((entry) {
//                         return FlSpot(
//                           entry.key.toDouble(),
//                           double.parse(entry.value.sgpa.toStringAsFixed(2)),
//                         );
//                       }).toList(),
//                       isCurved: true,
//                       color: Theme.of(context).colorScheme.tertiary,
//                       barWidth: 3,
//                       dotData: FlDotData(
//                         show: true,
//                         getDotPainter: (spot, percent, barData, index) {
//                           return FlDotCirclePainter(
//                             radius: 5,
//                             color: Theme.of(context).colorScheme.tertiary,
//                             strokeWidth: 2,
//                             strokeColor:
//                                 Theme.of(context).colorScheme.onSurface,
//                           );
//                         },
//                       ),
//                       belowBarData: BarAreaData(
//                         show: true,
//                         color: Theme.of(context)
//                             .colorScheme
//                             .tertiary
//                             .withOpacity(0.3),
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Theme.of(context)
//                                 .colorScheme
//                                 .tertiary
//                                 .withOpacity(0.3),
//                             Theme.of(context)
//                                 .colorScheme
//                                 .tertiary
//                                 .withOpacity(0.1),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                   minX: 0,
//                   maxX: validSemesters.length.toDouble() - 1,
//                   minY: 0,
//                   maxY: 4.0,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _calculateCGPA() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
//       try {
//         final studentId = _studentIdController.text;

//         // Fetch student info
//         final studentInfo =
//             await _studentDataService.fetchStudentInfo(studentId);

//         // Fetch semester results
//         final semesterResults =
//             await _studentDataService.fetchResults(studentId);
//         print(semesterResults);

//         // Calculate overall CGPA
//         final cgpa = _studentDataService.calculateOverallCGPA(semesterResults);

//         // Prepare semester results
//         final allSemesters = <SemesterResult>[];

//         semesterResults.forEach((semesterId, results) {
//           // Calculate semester SGPA
//           final sgpa = _studentDataService.calculateSemesterCGPA(results);

//           // Prepare courses for this semester
//           final courses = results
//               .map((course) => CourseResult(
//                     courseTitle: course['courseTitle'],
//                     totalCredit: double.parse(course['totalCredit'].toString()),
//                     gradeLetter: course['gradeLetter'],
//                     pointEquivalent:
//                         double.parse(course['pointEquivalent'].toString()),
//                   ))
//               .toList();

//           // Determine semester name and year from semesterId
//           final semesterName = _getSemesterName(semesterId);
//           final semesterYear = _getSemesterYear(semesterId);

//           allSemesters.add(SemesterResult(
//             name: semesterName,
//             year: semesterYear,
//             credits:
//                 courses.fold(0.0, (sum, course) => sum + course.totalCredit),
//             sgpa: sgpa,
//             courses: courses,
//           ));
//         });

//         // Sort semesters chronologically
//         allSemesters.sort((a, b) {
//           if (a.year != b.year) {
//             return b.year - a.year;
//           }
//           final seasonOrder = {'Spring': 1, 'Summer': 2, 'Fall': 3, 'Short': 4};
//           final aOrder = seasonOrder[a.name] ?? 0;
//           final bOrder = seasonOrder[b.name] ?? 0;
//           return bOrder - aOrder;
//         });

//         setState(() {
//           _result = CGPAResult(
//             cgpa: cgpa,
//             totalCredits: allSemesters.fold(
//                 0, (sum, semester) => sum + semester.credits.toInt()),
//             semesters: allSemesters,
//             studentName: studentInfo['studentName'] ?? 'Unknown Student',
//             programName: studentInfo['programName'] ?? 'Unknown Program',
//             batchNo: studentInfo['batchNo']?.toString() ?? 'Unknown Batch',
//           );
//         });
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   // Helper methods to parse semester ID
//   String _getSemesterName(String semesterId) {
//     final lastDigit = semesterId[semesterId.length - 1];
//     switch (lastDigit) {
//       case '1':
//         return 'Spring';
//       case '2':
//         return 'Summer';
//       case '3':
//         return 'Fall';
//       default:
//         return 'Unknown';
//     }
//   }

//   int _getSemesterYear(String semesterId) {
//     final yearPrefix = semesterId.substring(0, semesterId.length - 1);
//     return int.parse('20$yearPrefix');
//   }

//   Widget _buildCalculatorForm() {
//     return Form(
//       key: _formKey,
//       child: Card(
//         color: Theme.of(context).colorScheme.surface,
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextFormField(
//                 controller: _studentIdController,
//                 style:
//                     TextStyle(color: Theme.of(context).colorScheme.onSurface),
//                 decoration: InputDecoration(
//                   labelText: 'Student ID',
//                   labelStyle:
//                       TextStyle(color: Theme.of(context).colorScheme.onSurface),
//                   border: const OutlineInputBorder(),
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: BorderSide(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .onSurface
//                             .withOpacity(0.6)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(
//                         color: Theme.of(context).colorScheme.secondary),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter student ID';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _calculateCGPA,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).colorScheme.secondary,
//                   foregroundColor: Theme.of(context).colorScheme.onSecondary,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: Text(_isLoading ? 'Calculating...' : 'Calculate CGPA'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _gradientController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 5),
//     )..repeat();
//     _gradientController.addListener(() {
//       setState(() {
//         _animationValue = _gradientController.value;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _gradientController.dispose();
//     _studentIdController.dispose();
//     super.dispose();
//   }
// }



// // Loading Animation Widget
// class LoadingAnimation extends StatelessWidget {
//   const LoadingAnimation();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Lottie.asset(
//         'assets/jsons/loading.json',
//         width: 400,
//         height: 400,
//         fit: BoxFit.fill,
//       ),
//     );
//   }
// }
