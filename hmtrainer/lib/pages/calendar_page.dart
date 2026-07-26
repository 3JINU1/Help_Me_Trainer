import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.plansFor,
    required this.planController,
    required this.onChangeMonth,
    required this.onSelectDate,
    required this.onAddPlan,
    required this.todayRoutineSummary,
    required this.onOpenWeekdaySettings,
    required this.hasRoutineForDate,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<String> Function(DateTime) plansFor;
  final TextEditingController planController;
  final void Function(int delta) onChangeMonth;
  final void Function(DateTime date) onSelectDate;
  final VoidCallback onAddPlan;
  final List<String> todayRoutineSummary;
  final VoidCallback onOpenWeekdaySettings;
  final bool Function(DateTime date) hasRoutineForDate;

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
    final days = _monthDays(visibleMonth);
    final headers = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('오늘 운동 확인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            TextButton.icon(
              onPressed: onOpenWeekdaySettings,
              icon: const Icon(Icons.calendar_view_week, color: Colors.white),
              label: const Text('요일별 운동 설정', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => onChangeMonth(-1),
            ),
            const Spacer(),
            Text('${visibleMonth.year}년 ${visibleMonth.month}월', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => onChangeMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: headers.map((label) => Expanded(child: Center(child: Text(label, style: const TextStyle(color: Colors.white70))))).toList()),
              const SizedBox(height: 8),
              ...List.generate(days.length ~/ 7, (week) {
                final weekDays = days.skip(week * 7).take(7).toList();
                return Row(
                  children: weekDays.map((day) {
                    final isCurrentMonth = day.month == visibleMonth.month;
                    final isSelected = day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day;
                    final hasPlan = hasRoutineForDate(day);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onSelectDate(day),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          height: 44,
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(color: isCurrentMonth ? (isSelected ? Colors.red : Colors.white) : Colors.white38, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                              if (hasPlan)
                                const Positioned(
                                  bottom: 6,
                                  left: 0,
                                  right: 0,
                                  child: Icon(Icons.fitness_center, size: 14, color: Colors.yellowAccent),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('선택한 날짜: ${selectedDate.year}.${selectedDate.month}.${selectedDate.day}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('오늘 루틴 요약', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (todayRoutineSummary.isEmpty)
                const Text('오늘 루틴이 없습니다.', style: TextStyle(color: Colors.black87))
              else
                ...todayRoutineSummary.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $plan', style: const TextStyle(color: Colors.black87)),
                    )),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...plansFor(selectedDate).map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $plan', style: const TextStyle(color: Colors.black87)),
                  )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: planController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '오늘 할 운동 추가',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onAddPlan,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
