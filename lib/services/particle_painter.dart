// Add this custom painter to create animated floating particles
import 'dart:math';

import 'package:flutter/material.dart';

class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final Random random = Random();
  final List<Offset> particles = [];
  final List<double> sizes = [];

  ParticlesPainter({required this.animation, required this.color}) {
    // Create random particle positions
    for (int i = 0; i < 15; i++) {
      particles.add(Offset(
        random.nextDouble(),
        random.nextDouble(),
      ));
      sizes.add(random.nextDouble() * 3 + 1); // Random size between 1-4
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      // Calculate position with animation
      final offset = Offset(
        particles[i].dx * size.width,
        particles[i].dy * size.height +
            sin((animation.value * 2 * pi) + i) * 5, // Gentle floating effect
      );

      // Draw the particle
      canvas.drawCircle(offset, sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}
