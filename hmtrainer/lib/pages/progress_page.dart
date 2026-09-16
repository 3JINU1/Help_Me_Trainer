import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/performance_chart.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, required this.records});

  final List<WorkoutRecord> records;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final Set<String> _selectedExercises = {};
  bool _showProgressChart = true;
  bool _hasInitializedExerciseSelection = false;

  @override
  void didUpdateWidget(covariant ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedExercises.removeWhere(
      (name) => !widget.records.any((record) => record.exercise == name),
    );
    final oldExercises = oldWidget.records
        .map((record) => record.exercise)
        .toSet();
    _selectedExercises.addAll(
      widget.records
          .map((record) => record.exercise)
          .where((name) => !oldExercises.contains(name)),
    );
    if (!_hasInitializedExerciseSelection && widget.records.isNotEmpty) {
      _selectedExercises.addAll(
        widget.records.map((record) => record.exercise).toSet(),
      );
      _hasInitializedExerciseSelection = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises =
        widget.records.map((record) => record.exercise).toSet().toList()
          ..sort((a, b) {
            final latestA = widget.records
                .where((record) => record.exercise == a)
                .map((record) => record.date)
                .reduce((x, y) => x.isAfter(y) ? x : y);
            final latestB = widget.records
                .where((record) => record.exercise == b)
                .map((record) => record.date)
                .reduce((x, y) => x.isAfter(y) ? x : y);
            return latestB.compareTo(latestA);
          });
    if (!_hasInitializedExerciseSelection && exercises.isNotEmpty) {
      _selectedExercises.addAll(exercises);
      _hasInitializedExerciseSelection = true;
    }
    final allExercisesSelected =
        exercises.isNotEmpty && exercises.every(_selectedExercises.contains);
    final visibleRecords = widget.records
        .where((record) => _selectedExercises.contains(record.exercise))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const Text(
                '진행 그래프',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '그래프 표시',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Checkbox(
                    key: const Key('show_progress_chart_checkbox'),
                    value: _showProgressChart,
                    onChanged: (selected) {
                      setState(() {
                        _showProgressChart = selected ?? false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (_showProgressChart)
            Container(
              margin: const EdgeInsets.only(bottom: 18, top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '최근 운동 기록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: PerformanceChart(records: visibleRecords),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const Text(
                '운동 별 추세',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '전체 운동',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Checkbox(
                    key: const Key('toggle_all_exercises_checkbox'),
                    value: allExercisesSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedExercises.addAll(exercises);
                        } else {
                          _selectedExercises.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...exercises.map((name) {
            final weights = widget.records
                .where((r) => r.exercise == name)
                .map((r) => r.weight)
                .toList();
            final latest = weights.isNotEmpty ? weights.last : 0;
            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '최근 중량: ${latest}kg',
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: Checkbox(
                  value: _selectedExercises.contains(name),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedExercises.add(name);
                      } else {
                        _selectedExercises.remove(name);
                      }
                    });
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
