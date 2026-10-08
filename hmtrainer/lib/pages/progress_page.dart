import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import 'workout_provider.dart';
import '../widgets/performance_chart.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    required this.records,
    required this.exerciseProgressions,
    required this.onToggleProgression,
    required this.onChangeProgressionAmount,
  });

  final List<WorkoutRecord> records;
  final Map<String, ExerciseProgressionSetting> exerciseProgressions;
  final Future<void> Function(String exercise, bool enabled)
  onToggleProgression;
  final Future<void> Function(String exercise, double incrementKg)
  onChangeProgressionAmount;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final Set<String> _selectedExercises = {};
  bool _showProgressChart = true;
  bool _hasInitializedExerciseSelection = false;

  Future<void> _showProgressionPicker(
    String exercise,
    double currentAmount,
  ) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ProgressionPickerSheet(
        exercise: exercise,
        initialAmount: currentAmount,
      ),
    );
    if (amount != null) {
      await widget.onChangeProgressionAmount(exercise, amount);
    }
  }

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
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '최근 중량: ${formatWeight(latest.toDouble())}kg',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '다음 운동부터 증량',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Switch(
                          key: Key('progression_toggle_$name'),
                          value:
                              widget.exerciseProgressions[name]?.enabled ??
                              false,
                          onChanged: (enabled) {
                            widget.onToggleProgression(name, enabled);
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          key: Key('progression_amount_$name'),
                          onPressed:
                              widget.exerciseProgressions[name]?.enabled ??
                                  false
                              ? () => _showProgressionPicker(
                                  name,
                                  widget
                                          .exerciseProgressions[name]
                                          ?.incrementKg ??
                                      1.25,
                                )
                              : null,
                          child: Text(
                            '+${formatWeight(widget.exerciseProgressions[name]?.incrementKg ?? 1.25)}kg',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProgressionPickerSheet extends StatefulWidget {
  const _ProgressionPickerSheet({
    required this.exercise,
    required this.initialAmount,
  });

  final String exercise;
  final double initialAmount;

  @override
  State<_ProgressionPickerSheet> createState() =>
      _ProgressionPickerSheetState();
}

class _ProgressionPickerSheetState extends State<_ProgressionPickerSheet> {
  late final FixedExtentScrollController _scrollController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ((widget.initialAmount - 1.25) / 0.25).round();
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: [
                TextButton(
                  key: const Key('progression_picker_cancel'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                Expanded(
                  child: Text(
                    widget.exercise,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('progression_picker_done'),
                  onPressed: () =>
                      Navigator.pop(context, 1.25 + _selectedIndex * 0.25),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 216,
            child: CupertinoPicker(
              key: const Key('progression_picker'),
              backgroundColor: Colors.white,
              scrollController: _scrollController,
              itemExtent: 44,
              useMagnifier: true,
              magnification: 1.08,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: Colors.red.withValues(alpha: 0.08),
              ),
              onSelectedItemChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: List<Widget>.generate(
                36,
                (index) => Center(
                  child: Text(
                    '+${formatWeight(1.25 + index * 0.25)}kg',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
