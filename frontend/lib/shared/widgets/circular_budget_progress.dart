import 'dart:math';
import 'package:flutter/material.dart';
import 'package:moneyguard/core/theme/app_colors.dart';

class CircularBudgetProgress extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;

  const CircularBudgetProgress({
    super.key,
    required this.percentage,
    this.size = 150,
    this.strokeWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          percentage: percentage.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'spent',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.percentage,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = AppColors.backgroundTertiary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accentStart, AppColors.accentEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percentage,
      false,
      progressPaint,
    );
    
    // Optional: Draw a small indicator circle at the end of the arc
    if (percentage > 0) {
      final angle = -pi / 2 + 2 * pi * percentage;
      final indicatorX = center.dx + radius * cos(angle);
      final indicatorY = center.dy + radius * sin(angle);
      
      final indicatorPaint = Paint()
        ..color = AppColors.accentEnd
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(Offset(indicatorX, indicatorY), strokeWidth / 2, indicatorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
