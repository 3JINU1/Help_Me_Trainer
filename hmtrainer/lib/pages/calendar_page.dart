import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.plansFor,
    required this.onChangeMonth,
    required this.onSelectDate,
    required this.todayRoutineSummary,
    required this.routineName,
    required this.isCompleted,
    required this.onResetCompletedWorkout,
    required this.onOpenWeekdaySettings,
    required this.hasRoutineForDate,
    required this.isCompletedForDate,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<String> Function(DateTime) plansFor;
  final void Function(int delta) onChangeMonth;
  final void Function(DateTime date) onSelectDate;
  final List<String> todayRoutineSummary;
  final String? routineName;
  final bool isCompleted;
  final VoidCallback onResetCompletedWorkout;
  final VoidCallback onOpenWeekdaySettings;
  final bool Function(DateTime date) hasRoutineForDate;
  final bool Function(DateTime date) isCompletedForDate;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isRoutineExpanded = false;

  List<DateTime> _monthDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final List<DateTime> days = [];
    final int leadingEmpty = first.weekday % 7;

    for (var i = 0; i < leadingEmpty; i++) {
      days.add(first.subtract(Duration(days: leadingEmpty - i)));
    }

    for (var day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _monthDays(widget.visibleMonth);
    final headers = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '오늘 운동 확인',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: widget.onOpenWeekdaySettings,
              icon: const Icon(Icons.calendar_view_week, color: Colors.white),
              label: const Text(
                '요일별 운동 설정',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => widget.onChangeMonth(-1),
            ),
            const Spacer(),
            Text(
              '${widget.visibleMonth.year}년 ${widget.visibleMonth.month}월',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => widget.onChangeMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: headers
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              ...List.generate(days.length ~/ 7, (week) {
                final weekDays = days.skip(week * 7).take(7).toList();
                return Row(
                  children: weekDays.map((day) {
                    final isCurrentMonth =
                      day.month == widget.visibleMonth.month;
                    final isSelected =
                        day.year == widget.selectedDate.year &&
                        day.month == widget.selectedDate.month &&
                        day.day == widget.selectedDate.day;
                      final hasPlan = widget.hasRoutineForDate(day);
                      final isCompleted = widget.isCompletedForDate(day);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onSelectDate(day),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          height: 44,
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: isCurrentMonth
                                        ? (isSelected
                                              ? Colors.red
                                              : Colors.white)
                                        : Colors.white38,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasPlan)
                                const Positioned(
                                  bottom: 6,
                                  left: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 14,
                                    color: Colors.yellowAccent,
                                  ),
                                ),
                              if (isCompleted)
                                const Positioned(
                                  top: 3,
                                  right: 3,
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.selectedDate.year}년 ${widget.selectedDate.month}월 ${widget.selectedDate.day}일',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.routineName == null)
                const Text(
                  '저장된 루틴이 없습니다.',
                  style: TextStyle(color: Colors.black87),
                )
              else ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          widget.routineName!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isCompleted)
                              const Icon(Icons.check_circle, color: Colors.green),
                            if (widget.isCompleted)
                              IconButton(
                                tooltip: '완료 초기화',
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                onPressed: widget.onResetCompletedWorkout,
                              ),
                            IconButton(
                              icon: Icon(
                                _isRoutineExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isRoutineExpanded = !_isRoutineExpanded;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_isRoutineExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.todayRoutineSummary
                                .map(
                                  (plan) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• $plan',
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
