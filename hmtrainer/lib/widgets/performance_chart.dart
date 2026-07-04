import 'package:flutter/material.dart';

import '../models.dart';

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({super.key, required this.records});

  final List<WorkoutRecord> records;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PerformancePainter(records: records),
      child: Container(),
    );
  }
}

class _PerformancePainter extends CustomPainter {
  _PerformancePainter({required this.records});

  final List<WorkoutRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final paintLine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final paintPoints = Paint()..color = Colors.yellowAccent;
    final padding = 24.0;

    for (var i = 0; i <= 4; i++) {
      final dy = padding + (size.height - padding * 2) / 4 * i;
      canvas.drawLine(Offset(padding, dy), Offset(size.width - padding, dy), paintGrid);
    }

    final visibleRecords = records.take(6).toList();
    if (visibleRecords.isEmpty) return;

    final minWeight = visibleRecords.map((e) => e.weight).reduce((a, b) => a < b ? a : b).toDouble();
    final maxWeight = visibleRecords.map((e) => e.weight).reduce((a, b) => a > b ? a : b).toDouble();
    final weightRange = (maxWeight - minWeight).clamp(1, double.infinity);

    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final points = <Offset>[];
    for (var i = 0; i < visibleRecords.length; i++) {
      final x = padding + chartWidth / (visibleRecords.length - 1).clamp(1, double.infinity) * i;
      final normalized = (visibleRecords[i].weight - minWeight) / weightRange;
      final y = padding + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paintLine);
    }

    for (var point in points) {
      canvas.drawCircle(point, 5, paintPoints);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labels = ['${maxWeight.toInt()}kg', '${(minWeight + weightRange * 0.75).toInt()}kg', '${(minWeight + weightRange * 0.5).toInt()}kg', '${(minWeight + weightRange * 0.25).toInt()}kg', '${minWeight.toInt()}kg'];
    for (var i = 0; i < labels.length; i++) {
      final dy = padding + chartHeight / 4 * i;
      textPainter.text = TextSpan(text: labels[i], style: const TextStyle(color: Colors.white70, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, dy - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _PerformancePainter oldDelegate) {
    return oldDelegate.records != records;
  }
}
