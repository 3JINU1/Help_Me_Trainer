import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({
    super.key,
    required this.routineTitleController,
    required this.splitTargets,
    required this.selectedSplitTargetIndex,
    required this.splitTargetSessions,
    required this.exerciseNames,
    required this.cardioExerciseNames,
    required this.onAddSplitTarget,
    required this.onSetSelectedSplitTarget,
    required this.onSetSplitTarget,
    required this.onAddSplitSession,
    required this.onInsertSplitSession,
    required this.onMoveSplitSession,
    required this.onRemoveSplitSession,
    required this.onReorderSplitSessions,
    required this.onSetSplitSessionType,
    required this.onSetSplitSessionExercise,
    required this.onSetSplitSessionWeight,
    required this.onSetSplitSessionSets,
    required this.onSetSplitSessionReps,
    required this.onSetSplitSessionRestSeconds,
    required this.onSetSplitSessionCardioSeconds,
    required this.restSeconds,
    required this.onChangeRestSeconds,
    required this.weeklyRoutine,
    required this.selectedRoutineMode,
    required this.selectedWeekday,
    required this.weeklyWorkoutController,
    required this.onSetRoutineMode,
    required this.onSetWeekday,
    required this.onAddWeeklyWorkout,
  });

  final TextEditingController routineTitleController;
  final List<String> splitTargets;
  final int selectedSplitTargetIndex;
  final List<List<SplitSession>> splitTargetSessions;
  final List<String> exerciseNames;
  final List<String> cardioExerciseNames;
  final VoidCallback onAddSplitTarget;
  final void Function(int index) onSetSelectedSplitTarget;
  final void Function(int index, String target) onSetSplitTarget;
  final void Function(int targetIndex) onAddSplitSession;
  final void Function(int targetIndex, int sessionIndex) onInsertSplitSession;
  final void Function(int targetIndex, int sessionIndex, int delta) onMoveSplitSession;
  final void Function(int targetIndex, int sessionIndex) onRemoveSplitSession;
  final void Function(int targetIndex, int oldIndex, int newIndex) onReorderSplitSessions;
  final void Function(int targetIndex, int sessionIndex, String type) onSetSplitSessionType;
  final void Function(int targetIndex, int sessionIndex, String? exercise) onSetSplitSessionExercise;
  final void Function(int targetIndex, int sessionIndex, int? weight) onSetSplitSessionWeight;
  final void Function(int targetIndex, int sessionIndex, int? sets) onSetSplitSessionSets;
  final void Function(int targetIndex, int sessionIndex, int? reps) onSetSplitSessionReps;
  final void Function(int targetIndex, int sessionIndex, int restSeconds) onSetSplitSessionRestSeconds;
  final void Function(int targetIndex, int sessionIndex, int seconds) onSetSplitSessionCardioSeconds;
  final int restSeconds;
  final void Function(int delta) onChangeRestSeconds;
  final Map<String, List<String>> weeklyRoutine;
  final String selectedRoutineMode;
  final String selectedWeekday;
  final TextEditingController weeklyWorkoutController;
  final void Function(String mode) onSetRoutineMode;
  final void Function(String value) onSetWeekday;
  final VoidCallback onAddWeeklyWorkout;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final Map<String, TextEditingController> _cardioTimeControllers = {};

  static const _filterGroups = <String, List<String>>{
    'Equipment': [
      'Dumbbell',
      'Barbell',
      'Cable',
      'Machine',
      'Smith Machine',
      'Kettlebell',
      'Band / Resistance Band',
      'Bodyweight',
    ],
    'Posture & Position': [
      'Seated',
      'Standing',
      'Bent-over',
      'Incline',
      'Decline',
      'Lying / Prone',
      'Supine',
      'Spider',
      'Single-Arm / One-Arm',
      'Half-Kneeling',
    ],
    'Grip': [
      'Pronated (Overhand)',
      'Supinated (Underhand)',
      'Neutral',
      'Wide / Narrow (Close)',
      'Reverse',
    ],
    'Movement Pattern & Execution': [
      'Press / Push',
      'Pull / Row',
      'Raise / Fly',
      'Curl / Extension',
      'Pause / Dead-stop',
      'Deficit',
    ],
  };

  String _formatCardioDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool _matchesExerciseSearch(String exercise, String query) {
    final normalizedExercise = exercise
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
    final normalizedQuery = query.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (normalizedQuery.isEmpty || normalizedExercise.contains(normalizedQuery)) {
      return true;
    }

    var queryIndex = 0;
    for (final character in normalizedExercise.split('')) {
      if (queryIndex < normalizedQuery.length &&
          character == normalizedQuery[queryIndex]) {
        queryIndex++;
        if (queryIndex == normalizedQuery.length) return true;
      }
    }

    if (normalizedQuery.length >= 2) {
      final exerciseCharacters = normalizedExercise.split('');
      for (var start = 0; start < exerciseCharacters.length; start++) {
        for (var length = normalizedQuery.length - 1;
            length <= normalizedQuery.length + 1;
            length++) {
          final end = start + length;
          if (end <= exerciseCharacters.length &&
              _editDistanceAtMostOne(
                normalizedQuery,
                exerciseCharacters.sublist(start, end).join(),
              )) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _editDistanceAtMostOne(String first, String second) {
    if ((first.length - second.length).abs() > 1) return false;
    var differences = 0;
    var firstIndex = 0;
    var secondIndex = 0;
    while (firstIndex < first.length && secondIndex < second.length) {
      if (first[firstIndex] == second[secondIndex]) {
        firstIndex++;
        secondIndex++;
        continue;
      }
      differences++;
      if (differences > 1) return false;
      if (first.length > second.length) {
        firstIndex++;
      } else if (second.length > first.length) {
        secondIndex++;
      } else {
        firstIndex++;
        secondIndex++;
      }
    }
    differences += (first.length - firstIndex) + (second.length - secondIndex);
    return differences <= 1;
  }

  TextEditingController _cardioTimeControllerFor(int targetIndex, int sessionIndex) {
    final key = 'cardio-$targetIndex-$sessionIndex';
    final existing = _cardioTimeControllers[key];
    if (existing != null) {
      return existing;
    }
    final cardioSeconds = widget.splitTargetSessions[targetIndex][sessionIndex].cardioSeconds;
    final text = cardioSeconds > 0 ? _formatCardioDuration(cardioSeconds) : '';
    final controller = TextEditingController(text: text);
    _cardioTimeControllers[key] = controller;
    return controller;
  }

  void _openExercisePicker({
    required int sessionIndex,
    required SplitSession session,
    required String title,
  }) {
    final searchController = TextEditingController();
    final activeFilters = <String>{};
    final exerciseSource = session.type == '유산소' ? widget.cardioExerciseNames : widget.exerciseNames;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            final mediaQuery = MediaQuery.of(innerContext);
            final visibleHeight = mediaQuery.size.height -
                mediaQuery.viewInsets.bottom;
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              contentTextStyle: const TextStyle(color: Colors.black87),
              content: SizedBox(
                width: double.maxFinite,
                height: (visibleHeight * 0.68).clamp(280.0, 460.0),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 116),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _filterGroups.values
                              .expand((filters) => filters)
                              .map((filter) {
                            final selected = activeFilters.contains(filter);
                            return FilterChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.red.shade900,
                                  fontSize: 11,
                                ),
                              ),
                              selected: selected,
                              onSelected: (value) {
                                setDialogState(() {
                                  if (value) {
                                    activeFilters.add(filter);
                                  } else {
                                    activeFilters.remove(filter);
                                  }
                                });
                              },
                              backgroundColor: Colors.red.shade50,
                              selectedColor: Colors.red,
                              checkmarkColor: Colors.white,
                              side: BorderSide(color: Colors.red.shade200),
                              visualDensity: VisualDensity.compact,
                            );
                          })
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: '운동 검색',
                              hintStyle: TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: searchController,
                        builder: (context, value, child) {
                          final filtered = exerciseSource.where((exercise) {
                            final matchesQuery = _matchesExerciseSearch(
                              exercise,
                              value.text.trim(),
                            );
                            return matchesQuery;
                          }).toList();

                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final exercise = filtered[index];
                              return ListTile(
                                title: Text(
                                  exercise,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                selected: session.exercise == exercise,
                                selectedTileColor: Colors.red.shade50,
                                onTap: () {
                                  widget.onSetSplitSessionExercise(
                                    widget.selectedSplitTargetIndex,
                                    sessionIndex,
                                    exercise,
                                  );
                                  Navigator.pop(dialogContext);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('닫기', style: TextStyle(color: Colors.black87)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('루틴 제목', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        TextField(
          controller: widget.routineTitleController,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '루틴 제목 입력',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('세션 구성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        ReorderableListView(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          onReorder: (oldIndex, newIndex) {
            widget.onReorderSplitSessions(widget.selectedSplitTargetIndex, oldIndex, newIndex);
          },
          children: widget.splitTargetSessions[widget.selectedSplitTargetIndex].asMap().entries.map((entry) {
            final sessionIndex = entry.key;
            final session = entry.value;

            return Container(
              key: ValueKey('session-${widget.selectedSplitTargetIndex}-$sessionIndex'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: session.type.isEmpty ? '' : session.type,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black87),
                          iconEnabledColor: Colors.black54,
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: ['', '운동', '유산소', '휴식']
                              .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.isEmpty ? '타입 선택' : type, style: const TextStyle(color: Colors.black87))))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              widget.onSetSplitSessionType(widget.selectedSplitTargetIndex, sessionIndex, value);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => widget.onRemoveSplitSession(widget.selectedSplitTargetIndex, sessionIndex),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                      ),
                      ReorderableDragStartListener(
                        index: sessionIndex,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.menu, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (session.type == '운동') ...[
                    InkWell(
                      onTap: () => _openExercisePicker(
                        sessionIndex: sessionIndex,
                        session: session,
                        title: '운동 선택',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.exercise ?? '운동 선택',
                                style: TextStyle(
                                  color: session.exercise == null ? Colors.grey.shade600 : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: session.weight?.toString() ?? '',
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: '무게(kg)',
                              labelStyle: TextStyle(color: Colors.black87),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => widget.onSetSplitSessionWeight(widget.selectedSplitTargetIndex, sessionIndex, int.tryParse(value)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: session.sets?.toString() ?? '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: false),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: '세트',
                              labelStyle: const TextStyle(color: Colors.black87),
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: (session.sets != null && (session.sets! < 1 || session.sets! > 10)) ? Colors.red : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: (session.sets != null && (session.sets! < 1 || session.sets! > 10)) ? Colors.red : Colors.red.shade700,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed == null) {
                                widget.onSetSplitSessionSets(widget.selectedSplitTargetIndex, sessionIndex, null);
                                return;
                              }
                              widget.onSetSplitSessionSets(widget.selectedSplitTargetIndex, sessionIndex, parsed);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: session.reps?.toString() ?? '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: false),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: '반복',
                              labelStyle: const TextStyle(color: Colors.black87),
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: (session.reps != null && (session.reps! < 1 || session.reps! > 30)) ? Colors.red : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: (session.reps != null && (session.reps! < 1 || session.reps! > 30)) ? Colors.red : Colors.red.shade700,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed == null) {
                                widget.onSetSplitSessionReps(widget.selectedSplitTargetIndex, sessionIndex, null);
                                return;
                              }
                              widget.onSetSplitSessionReps(widget.selectedSplitTargetIndex, sessionIndex, parsed);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else if (session.type == '유산소') ...[
                    InkWell(
                      onTap: () => _openExercisePicker(
                        sessionIndex: sessionIndex,
                        session: session,
                        title: '유산소 종목 선택',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.exercise ?? '유산소 종목 선택',
                                style: TextStyle(
                                  color: session.exercise == null ? Colors.grey.shade600 : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cardioTimeControllerFor(widget.selectedSplitTargetIndex, sessionIndex),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: '수행시간 (HH:MM:SS)',
                              labelStyle: TextStyle(color: Colors.black87),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final parts = value.split(':');
                              if (parts.length != 3) return;
                              final hours = int.tryParse(parts[0]) ?? 0;
                              final minutes = int.tryParse(parts[1]) ?? 0;
                              final seconds = int.tryParse(parts[2]) ?? 0;
                              final totalSeconds = hours * 3600 + minutes * 60 + seconds;
                              widget.onSetSplitSessionCardioSeconds(widget.selectedSplitTargetIndex, sessionIndex, totalSeconds);
                              final controller = _cardioTimeControllers['cardio-${widget.selectedSplitTargetIndex}-$sessionIndex'];
                              if (controller != null && controller.text != _formatCardioDuration(totalSeconds)) {
                                controller.text = _formatCardioDuration(totalSeconds);
                                controller.selection = TextSelection.fromPosition(
                                  TextPosition(offset: controller.text.length),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('추가 설정 없음', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5E5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onAddSplitSession(widget.selectedSplitTargetIndex),
              child: const Center(
                child: Icon(Icons.add, color: Colors.red, size: 28),
              ),
            ),
          ),
        ),
        if (widget.selectedRoutineMode == '주차') ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('주차별 루틴 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.selectedWeekday,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: widget.weeklyRoutine.keys.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                  onChanged: (value) {
                    if (value != null) widget.onSetWeekday(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.weeklyWorkoutController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '예: 상체, 하체',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: widget.onAddWeeklyWorkout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                child: const Text('추가'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.weeklyRoutine.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Text('${entry.key}요일', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                if (entry.value.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('등록된 루틴이 없습니다.', style: TextStyle(color: Colors.white70)),
                  ),
                ...entry.value.map((workout) {
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(workout, style: const TextStyle(color: Colors.black87)),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
