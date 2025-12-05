import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/trip_model.dart';

/// Analog speedometer-style trip progress widget (Student B #4)
class TripProgressWidget extends StatelessWidget {
  final Trip trip;
  final double size;

  const TripProgressWidget({
    Key? key,
    required this.trip,
    this.size = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = trip.getProgress();
    final completedDays = _getCompletedDays();
    final completedActivities = _getCompletedActivities();

    return Container(
      width: size,
      height: size,
      child: Column(
        children: [
          // Speedometer gauge
          CustomPaint(
            size: Size(size * 0.8, size * 0.8),
            painter: SpeedometerPainter(
              progress: progress,
              primaryColor: const Color(0xFF2E7D32),
              secondaryColor: const Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: size * 0.05),
          // Progress stats
          _buildProgressStats(
            completedDays,
            trip.durationDays,
            completedActivities,
            trip.totalActivities,
          ),
        ],
      ),
    );
  }

  int _getCompletedDays() {
    final now = DateTime.now();
    if (now.isBefore(trip.startDate)) return 0;
    if (now.isAfter(trip.endDate)) return trip.durationDays;
    return now.difference(trip.startDate).inDays + 1;
  }

  int _getCompletedActivities() {
    final completedDays = _getCompletedDays();
    int completed = 0;
    for (int i = 0; i < completedDays && i < trip.itinerary.length; i++) {
      completed += trip.itinerary[i].activities.length;
    }
    return completed;
  }

  Widget _buildProgressStats(
    int completedDays,
    int totalDays,
    int completedActivities,
    int totalActivities,
  ) {
    return Column(
      children: [
        Text(
          'Day $completedDays of $totalDays',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$completedActivities / $totalActivities Activities',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for analog speedometer gauge
class SpeedometerPainter extends CustomPainter {
  final double progress; // 0-100
  final Color primaryColor;
  final Color secondaryColor;

  SpeedometerPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw background arc
    _drawBackgroundArc(canvas, center, radius);

    // Draw progress arc
    _drawProgressArc(canvas, center, radius);

    // Draw tick marks
    _drawTickMarks(canvas, center, radius);

    // Draw center circle
    _drawCenterCircle(canvas, center, radius);

    // Draw needle
    _drawNeedle(canvas, center, radius);

    // Draw progress text
    _drawProgressText(canvas, center);
  }

  void _drawBackgroundArc(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75; // Start at bottom-left
    const sweepAngle = math.pi * 1.5; // 270 degrees

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawProgressArc(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75;
    final sweepAngle = (math.pi * 1.5) * (progress / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2;

    const numTicks = 10;
    const startAngle = math.pi * 0.75;
    const totalAngle = math.pi * 1.5;

    for (int i = 0; i <= numTicks; i++) {
      final angle = startAngle + (totalAngle * i / numTicks);
      final startPoint = Offset(
        center.dx + (radius - 25) * math.cos(angle),
        center.dy + (radius - 25) * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void _drawCenterCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.15, paint);

    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius * 0.15, borderPaint);
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    const startAngle = math.pi * 0.75;
    const totalAngle = math.pi * 1.5;
    final needleAngle = startAngle + (totalAngle * progress / 100);

    final needleEnd = Offset(
      center.dx + (radius - 30) * math.cos(needleAngle),
      center.dy + (radius - 30) * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Draw needle tip circle
    final tipPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(needleEnd, 6, tipPaint);
  }

  void _drawProgressText(Canvas canvas, Offset center) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${progress.toStringAsFixed(0)}%',
        style: TextStyle(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Compact trip progress indicator
class CompactProgressIndicator extends StatelessWidget {
  final Trip trip;

  const CompactProgressIndicator({Key? key, required this.trip})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = trip.getProgress();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2E7D32),
                  ),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '${progress.toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_getCompletedDays()} of ${trip.durationDays} days',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getCompletedDays() {
    final now = DateTime.now();
    if (now.isBefore(trip.startDate)) return 0;
    if (now.isAfter(trip.endDate)) return trip.durationDays;
    return now.difference(trip.startDate).inDays + 1;
  }
}