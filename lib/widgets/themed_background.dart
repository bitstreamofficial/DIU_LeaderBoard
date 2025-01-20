import 'package:flutter/material.dart';
import 'dart:async';

class ThemedBackground extends StatefulWidget {
  final Widget child;
  
  const ThemedBackground({super.key, required this.child});

  @override
  State<ThemedBackground> createState() => _ThemedBackgroundState();
}

class _ThemedBackgroundState extends State<ThemedBackground> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _getGradientColors(),
        ),
      ),
      child: Stack(
        children: [
          _buildDecorations(),
          widget.child,
        ],
      ),
    );
  }

  Widget _buildDecorations() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return _buildMorningDecorations();
    } else if (hour < 17) {
      return _buildAfternoonDecorations();
    } else {
      return _buildEveningDecorations();
    }
  }

  List<Color> _getGradientColors() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return [
        const Color(0xFFFFC988), // Warm orange
        const Color(0xFFFFE4B5), // Light peach
      ];
    } else if (hour < 17) {
      return [
        const Color(0xFF87CEEB), // Sky blue
        const Color(0xFFE0FFFF), // Light cyan
      ];
    } else {
      return [
        const Color(0xFF1A237E), // Deep blue
        const Color(0xFF000051), // Dark blue
      ];
    }
  }

  Widget _buildMorningDecorations() {
    return Positioned(
      top: 0,
      left: 16,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFB74D),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFFE082),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfternoonDecorations() {
    return Positioned(
      top: 0,
      left: 16,
      child: Icon(
        Icons.wb_sunny,
        size: 30,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildEveningDecorations() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(left: index * 20.0 + 16),
          child: const Icon(
            Icons.star,
            color: Colors.white70,
            size: 12,
          ),
        ),
      ),
    );
  }
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.35,
      size.width,
      size.height * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 