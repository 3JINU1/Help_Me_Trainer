import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';

List<DateTime> _dateTicks(List<DateTime> dates, {int limit = 5}) {
  if (dates.length <= limit) return dates;
  return List<DateTime>.generate(
    limit,
    (index) => dates[(index * (dates.length - 1) / (limit - 1)).round()],
  );
}

String _formatDate(DateTime date, {required bool includeYear}) => includeYear
    ? '${date.year}/${date.month}/${date.day}'
    : '${date.month}/${date.day}';

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({super.key, required this.records});

  final List<WorkoutRecord> records;

  @override
  Widget build(BuildContext context) {
    final sortedDates =
        records
            .map((record) => DateUtils.dateOnly(record.date))
            .toSet()
            .toList()
          ..sort();
    final includeYear =
        sortedDates.length > 1 &&
        sortedDates.first.year != sortedDates.last.year;
    final dateLabels = _dateTicks(
      sortedDates,
    ).map((date) => _formatDate(date, includeYear: includeYear)).join(', ');

    return Semantics(
      key: const Key('performance_chart_semantics'),
      label:
          '가로축: 저장 날짜${dateLabels.isEmpty ? '' : ', $dateLabels'}; '
          '세로축: 중량 (kg)',
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _PerformancePainter(records: records),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PerformancePainter extends CustomPainter {
  _PerformancePainter({required this.records});

  final List<WorkoutRecord> records;

  static const _leftPadding = 54.0;
  static const _rightPadding = 14.0;
  static const _topPadding = 14.0;
  static const _bottomPadding = 30.0;
  static const _pointRadius = 4.5;

  static const _lineColors = [
    Color(0xFFC62828),
    Color(0xFFEF6C00),
    Color(0xFF7B1FA2),
    Color(0xFF00897B),
    Color(0xFF3949AB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final chartLeft = _leftPadding;
    final chartRight = size.width - _rightPadding;
    final chartTop = _topPadding;
    final chartBottom = size.height - _bottomPadding;
    if (chartRight <= chartLeft || chartBottom <= chartTop) return;

    if (records.isEmpty) {
      _paintEmptyState(canvas, size);
      return;
    }

    final groupedRecords = <String, List<WorkoutRecord>>{};
    for (final record in records) {
      groupedRecords.putIfAbsent(record.exercise, () => []).add(record);
    }
    for (final values in groupedRecords.values) {
      values.sort((a, b) => a.date.compareTo(b.date));
    }

    final dates =
        records
            .map((record) => DateUtils.dateOnly(record.date))
            .toSet()
            .toList()
          ..sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    final dateRange = lastDate.difference(firstDate).inMicroseconds;
    final weightScale = _weightScale(records);
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;
    final pointInset = math.min(_pointRadius + 2, chartWidth / 2);
    final firstX = chartLeft + pointInset;
    final lastX = chartRight - pointInset;

    double xForDate(DateTime date) {
      if (dateRange == 0) return (chartLeft + chartRight) / 2;
      final progress = date.difference(firstDate).inMicroseconds / dateRange;
      return firstX + (lastX - firstX) * progress;
    }

    double yForWeight(double weight) {
      final progress =
          (weight - weightScale.minimum) /
          (weightScale.maximum - weightScale.minimum);
      return chartBottom - chartHeight * progress;
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF2)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFD3D9E1)
      ..strokeWidth = 1;
    final dateTicks = _dateTicks(dates);
    final includeYear = firstDate.year != lastDate.year;

    for (var index = 0; index < weightScale.tickCount; index++) {
      final weight = weightScale.minimum + weightScale.step * index;
      final y = yForWeight(weight);
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        index == 0 ? axisPaint : gridPaint,
      );
      _paintText(
        canvas,
        textPainter,
        '${formatWeight(weight)}kg',
        Offset(chartLeft - 8, y),
        align: _TextAlign.right,
        color: const Color(0xFF737B86),
      );
    }

    for (var index = 0; index < dateTicks.length; index++) {
      final date = dateTicks[index];
      final x = xForDate(date);
      canvas.drawLine(
        Offset(x, chartTop),
        Offset(x, chartBottom),
        index == 0 || index == dateTicks.length - 1 ? axisPaint : gridPaint,
      );
      final align = dateTicks.length == 1
          ? _TextAlign.center
          : index == 0
          ? _TextAlign.left
          : index == dateTicks.length - 1
          ? _TextAlign.right
          : _TextAlign.center;
      _paintText(
        canvas,
        textPainter,
        _formatDate(date, includeYear: includeYear),
        Offset(x, chartBottom + 16),
        align: align,
        color: const Color(0xFF737B86),
      );
    }

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
    );
    groupedRecords.entries.toList().asMap().forEach((entryIndex, entry) {
      final color = _lineColors[entryIndex % _lineColors.length];
      final points = entry.value
          .map(
            (record) => Offset(
              xForDate(DateUtils.dateOnly(record.date)),
              yForWeight(record.weight),
            ),
          )
          .toList();

      if (points.length > 1) {
        final linePath = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          linePath.lineTo(point.dx, point.dy);
        }
        final areaPath = Path.from(linePath)
          ..lineTo(points.last.dx, chartBottom)
          ..lineTo(points.first.dx, chartBottom)
          ..close();
        canvas.drawPath(
          areaPath,
          Paint()
            ..shader =
                LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.14),
                    color.withValues(alpha: 0.01),
                  ],
                ).createShader(
                  Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
                ),
        );
        canvas.drawPath(
          linePath,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      for (final point in points) {
        canvas.drawCircle(point, _pointRadius, Paint()..color = Colors.white);
        canvas.drawCircle(
          point,
          _pointRadius,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    });
    canvas.restore();
  }

  static _WeightScale _weightScale(List<WorkoutRecord> records) {
    final minimum = records
        .map((record) => record.weight)
        .reduce((a, b) => a < b ? a : b);
    final maximum = records
        .map((record) => record.weight)
        .reduce((a, b) => a > b ? a : b);
    final rawRange = maximum - minimum;
    final range = rawRange == 0
        ? math.max(maximum.abs() * 0.2, 2.0)
        : rawRange * 1.2;
    final roughStep = range / 4;
    final magnitude = math.pow(10, (math.log(roughStep) / math.ln10).floor());
    final fraction = roughStep / magnitude;
    final niceFraction = fraction <= 1
        ? 1.0
        : fraction <= 2
        ? 2.0
        : fraction <= 2.5
        ? 2.5
        : fraction <= 5
        ? 5.0
        : 10.0;
    final step = niceFraction * magnitude;
    var scaleMinimum = (minimum / step).floor() * step;
    var scaleMaximum = (maximum / step).ceil() * step;
    if (scaleMinimum == scaleMaximum) {
      scaleMinimum -= step;
      scaleMaximum += step;
    }
    return _WeightScale(
      minimum: scaleMinimum,
      maximum: scaleMaximum,
      step: step,
      tickCount: ((scaleMaximum - scaleMinimum) / step).round() + 1,
    );
  }

  static void _paintEmptyState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '표시할 운동 기록이 없습니다',
        style: TextStyle(color: Color(0xFF8A919B), fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  static void _paintText(
    Canvas canvas,
    TextPainter textPainter,
    String text,
    Offset anchor, {
    required _TextAlign align,
    required Color color,
  }) {
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 10),
    );
    textPainter.layout();
    final dx = switch (align) {
      _TextAlign.left => anchor.dx,
      _TextAlign.center => anchor.dx - textPainter.width / 2,
      _TextAlign.right => anchor.dx - textPainter.width,
    };
    textPainter.paint(canvas, Offset(dx, anchor.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PerformancePainter oldDelegate) {
    return oldDelegate.records != records;
  }
}

class _WeightScale {
  const _WeightScale({
    required this.minimum,
    required this.maximum,
    required this.step,
    required this.tickCount,
  });

  final double minimum;
  final double maximum;
  final double step;
  final int tickCount;
}

enum _TextAlign { left, center, right }
