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
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final lineColors = [
      Colors.red.shade700,
      Colors.red.shade400,
      Colors.red.shade900,
      Colors.deepOrange.shade600,
    ];
    final padding = 24.0;

    for (var i = 0; i <= 4; i++) {
      final dy = padding + (size.height - padding * 2) / 4 * i;
      canvas.drawLine(
        Offset(padding, dy),
        Offset(size.width - padding, dy),
        paintGrid,
      );
    }

    if (records.isEmpty) return;

    final groupedRecords = <String, List<WorkoutRecord>>{};
    for (final record in records) {
      groupedRecords.putIfAbsent(record.exercise, () => []).add(record);
    }
    for (final values in groupedRecords.values) {
      values.sort((a, b) => a.date.compareTo(b.date));
    }

    final maxWeight = records
        .map((record) => record.weight)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxDayCount = groupedRecords.values
        .map((values) => values.length)
        .reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight <= 0 ? 1.0 : maxWeight;

    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    groupedRecords.entries.toList().asMap().forEach((entryIndex, entry) {
      final paintLine = Paint()
        ..color = lineColors[entryIndex % lineColors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final paintPoints = Paint()
        ..color = lineColors[entryIndex % lineColors.length];
      final points = <Offset>[];
      for (var i = 0; i < entry.value.length; i++) {
        final x =
            padding +
            (maxDayCount == 1
                ? chartWidth / 2
                : chartWidth / (maxDayCount - 1) * i);
        final normalized = entry.value[i].weight / weightRange;
        final y = padding + chartHeight * (1 - normalized.clamp(0, 1));
        points.add(Offset(x, y));
      }

      if (points.length > 1) {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paintLine);
      }

      for (final point in points) {
        canvas.drawCircle(point, 5, paintPoints);
      }
    });

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labels = [
      '${maxWeight.toInt()}kg',
      '${(maxWeight * 0.75).toInt()}kg',
      '${(maxWeight * 0.5).toInt()}kg',
      '${(maxWeight * 0.25).toInt()}kg',
      '0kg',
    ];
    for (var i = 0; i < labels.length; i++) {
      final dy = padding + chartHeight / 4 * i;
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.black54, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, dy - 6));
    }

    for (var i = 0; i < maxDayCount; i++) {
      final x =
          padding +
          (maxDayCount == 1
              ? chartWidth / 2
              : chartWidth / (maxDayCount - 1) * i);
      textPainter.text = TextSpan(
        text: '${i + 1}일',
        style: const TextStyle(color: Colors.black54, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PerformancePainter oldDelegate) {
    return oldDelegate.records != records;
  }
}
