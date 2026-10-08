import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../exercise_catalog.dart';
import '../models.dart';
import '../weight_input_formatter.dart';
import '../widgets/cardio_duration_picker.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({
    super.key,
    required this.routineTitleController,
    required this.splitTargets,
    required this.selectedSplitTargetIndex,
    required this.splitTargetSessions,
    required this.exerciseNames,
    required this.cardioExerciseNames,
    required this.exerciseDataLoading,
    required this.exerciseDataError,
    required this.onAddSplitTarget,
    required this.onSetSelectedSplitTarget,
    required this.onSetSplitTarget,
    required this.onAddSplitSession,
    required this.onInsertSplitSession,
    required this.onMoveSplitSession,
    required this.onRemoveSplitSession,
    required this.onReorderSplitSessions,
    required this.onSessionReorderStart,
    required this.onSessionReorderEnd,
    required this.sessionAddButtonKey,
    required this.dragViewportKey,
    required this.sessionSectionKey,
    required this.onSetSplitSessionType,
    required this.onSetSplitSessionExercise,
    required this.onSetSplitSessionWeight,
    required this.onSetSplitSessionSets,
    required this.onSetSplitSessionReps,
    required this.onSetSplitSessionCardioSeconds,
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
  final List<ExerciseEntry> exerciseNames;
  final List<ExerciseEntry> cardioExerciseNames;
  final bool exerciseDataLoading;
  final String? exerciseDataError;
  final VoidCallback onAddSplitTarget;
  final void Function(int index) onSetSelectedSplitTarget;
  final void Function(int index, String target) onSetSplitTarget;
  final void Function(int targetIndex) onAddSplitSession;
  final void Function(int targetIndex, int sessionIndex) onInsertSplitSession;
  final void Function(int targetIndex, int sessionIndex, int delta)
  onMoveSplitSession;
  final void Function(int targetIndex, int sessionIndex) onRemoveSplitSession;
  final void Function(int targetIndex, int oldIndex, int newIndex)
  onReorderSplitSessions;
  final ValueChanged<int> onSessionReorderStart;
  final ValueChanged<int> onSessionReorderEnd;
  final GlobalKey sessionAddButtonKey;
  final GlobalKey dragViewportKey;
  final GlobalKey sessionSectionKey;
  final void Function(int targetIndex, int sessionIndex, String type)
  onSetSplitSessionType;
  final void Function(int targetIndex, int sessionIndex, String? exercise)
  onSetSplitSessionExercise;
  final void Function(int targetIndex, int sessionIndex, double? weight)
  onSetSplitSessionWeight;
  final void Function(int targetIndex, int sessionIndex, int? sets)
  onSetSplitSessionSets;
  final void Function(int targetIndex, int sessionIndex, int? reps)
  onSetSplitSessionReps;
  final void Function(int targetIndex, int sessionIndex, int seconds)
  onSetSplitSessionCardioSeconds;
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
  DragBoundaryDelegate<Rect> _sessionDragBoundary(BuildContext context) {
    if (_currentSessionDragBounds() == null) {
      return DragBoundary.forRectOf(context);
    }
    return _RectDragBoundary(_currentSessionDragBounds);
  }

  Rect? _currentSessionDragBounds() {
    final renderObject = widget.dragViewportKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final viewport = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );
    final sectionRenderObject = widget.sessionSectionKey.currentContext
        ?.findRenderObject();
    final sectionBottom =
        sectionRenderObject is RenderBox && sectionRenderObject.hasSize
        ? sectionRenderObject
              .localToGlobal(Offset(0, sectionRenderObject.size.height))
              .dy
        : viewport.top;
    final safeBottom = viewport.bottom - 36;
    final boundaryBottom = safeBottom < viewport.top
        ? viewport.top
        : safeBottom;
    final addButtonRenderObject = widget.sessionAddButtonKey.currentContext
        ?.findRenderObject();
    final addButtonTop =
        addButtonRenderObject is RenderBox && addButtonRenderObject.hasSize
        ? addButtonRenderObject.localToGlobal(Offset.zero).dy
        : safeBottom;
    final dragBottom = addButtonTop > viewport.top
        ? addButtonTop.clamp(viewport.top, boundaryBottom)
        : boundaryBottom;
    final dragTop = sectionBottom.clamp(viewport.top, boundaryBottom);
    return Rect.fromLTRB(
      viewport.left,
      dragTop,
      viewport.right,
      dragBottom < dragTop ? dragTop : dragBottom,
    );
  }

  bool _matchesExerciseSearch(String exercise, String query) {
    final normalizedExercise = exercise
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
    final normalizedQuery = query.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (normalizedQuery.isEmpty ||
        normalizedExercise.contains(normalizedQuery)) {
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
        for (
          var length = normalizedQuery.length - 1;
          length <= normalizedQuery.length + 1;
          length++
        ) {
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

  bool _matchesExerciseFilters(
    ExerciseEntry exercise,
    Set<String> selectedBodyParts,
    Set<String> selectedEquipment,
    String query,
  ) {
    final matchesBodyPart =
        selectedBodyParts.isEmpty ||
        selectedBodyParts.contains(exercise.bodyPart);
    final matchesEquipment =
        selectedEquipment.isEmpty ||
        selectedEquipment.contains(exercise.equipment);
    final matchesQuery =
        _matchesExerciseSearch(exercise.name, query) ||
        _matchesExerciseSearch(exercise.category, query) ||
        _matchesExerciseSearch(exercise.bodyPart, query) ||
        _matchesExerciseSearch(exercise.equipment, query) ||
        _matchesExerciseSearch(exercise.target, query);

    return matchesBodyPart && matchesEquipment && matchesQuery;
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

  void _openExercisePicker({
    required int sessionIndex,
    required SplitSession session,
    required String title,
  }) {
    final searchController = TextEditingController();
    final activeFilters = <String>{};
    final List<ExerciseEntry> exerciseSource = session.type == '유산소'
        ? widget.cardioExerciseNames
        : widget.exerciseNames;
    final bodyParts =
        exerciseSource.map((exercise) => exercise.bodyPart).toSet().toList()
          ..sort();
    final equipmentTypes =
        exerciseSource.map((exercise) => exercise.equipment).toSet().toList()
          ..sort();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            final mediaQuery = MediaQuery.of(innerContext);
            final visibleHeight =
                mediaQuery.size.height - mediaQuery.viewInsets.bottom;
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
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
                height: ((visibleHeight - 180) * 0.94).clamp(240.0, 620.0),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 116),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bodyParts.isNotEmpty)
                              _buildExerciseFilterGroup(
                                title: '운동 부위',
                                values: bodyParts,
                                filterPrefix: 'body:',
                                activeFilters: activeFilters,
                                setDialogState: setDialogState,
                              ),
                            if (equipmentTypes.isNotEmpty)
                              _buildExerciseFilterGroup(
                                title: '기구',
                                values: equipmentTypes,
                                filterPrefix: 'equipment:',
                                activeFilters: activeFilters,
                                setDialogState: setDialogState,
                              ),
                          ],
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
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
                          if (widget.exerciseDataLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (widget.exerciseDataError != null) {
                            return Center(
                              child: Text(
                                widget.exerciseDataError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          final selectedBodyParts = activeFilters
                              .where((filter) => filter.startsWith('body:'))
                              .map((filter) => filter.substring('body:'.length))
                              .toSet();
                          final selectedEquipment = activeFilters
                              .where(
                                (filter) => filter.startsWith('equipment:'),
                              )
                              .map(
                                (filter) =>
                                    filter.substring('equipment:'.length),
                              )
                              .toSet();
                          final filtered = exerciseSource
                              .where(
                                (exercise) => _matchesExerciseFilters(
                                  exercise,
                                  selectedBodyParts,
                                  selectedEquipment,
                                  value.text.trim(),
                                ),
                              )
                              .toList();
                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                '검색 결과가 없습니다.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final exercise = filtered[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    exercise.imageAssetPath,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 56,
                                              height: 56,
                                              color: Colors.red.shade50,
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.fitness_center,
                                                color: Colors.red.shade300,
                                              ),
                                            ),
                                  ),
                                ),
                                title: Text(
                                  exercise.name,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                subtitle: Text(
                                  '${exercise.category} · ${exercise.equipment}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                trailing: IconButton(
                                  tooltip: '운동 정보',
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () => _showExerciseDetails(
                                    dialogContext,
                                    exercise,
                                  ),
                                ),
                                selected: session.exercise == exercise.name,
                                selectedTileColor: Colors.red.shade50,
                                onTap: () {
                                  widget.onSetSplitSessionExercise(
                                    widget.selectedSplitTargetIndex,
                                    sessionIndex,
                                    exercise.name,
                                  );
                                  Navigator.pop(dialogContext);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© Gym visual — https://gymvisual.com/',
                      style: TextStyle(color: Colors.black54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    '닫기',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExerciseDetails(BuildContext context, ExerciseEntry exercise) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(exercise.name, style: const TextStyle(color: Colors.black)),
        content: SingleChildScrollView(
          child: Text(
            '부위: ${exercise.bodyPart}\n'
            '기구: ${exercise.equipment}\n'
            '주요 근육: ${exercise.target}\n\n'
            '${exercise.koreanInstructions}\n\n'
            '${exercise.attribution}',
            style: const TextStyle(color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseFilterGroup({
    required String title,
    required List<String> values,
    required String filterPrefix,
    required Set<String> activeFilters,
    required StateSetter setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 3),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.red.shade900,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: values.map((value) {
            final filter = '$filterPrefix$value';
            final selected = activeFilters.contains(filter);
            return FilterChip(
              label: Text(
                value,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.red.shade900,
                  fontSize: 11,
                ),
              ),
              selected: selected,
              onSelected: (isSelected) {
                setDialogState(() {
                  if (isSelected) {
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
          }).toList(),
        ),
      ],
    );
  }

  Widget _numberInputField({
    required String label,
    required int? value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      keyboardType: TextInputType.number,
      textInputAction: label == '반복'
          ? TextInputAction.done
          : TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      onFieldSubmitted: (_) {
        if (label == '반복') FocusScope.of(context).unfocus();
      },
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        errorStyle: const TextStyle(fontSize: 0, height: 0),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (text) {
        final parsedValue = int.tryParse(text ?? '');
        if (!RegExp(r'^\d+$').hasMatch(text ?? '') ||
            parsedValue == null ||
            parsedValue < 1 ||
            parsedValue > 50) {
          return '$label은 1~50 사이의 정수로 입력해 주세요.';
        }
        return null;
      },
      onChanged: onChanged,
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
          child: Text(
            '루틴 제목',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        TextField(
          controller: widget.routineTitleController,
          style: const TextStyle(color: Colors.black87),
          cursorColor: Colors.red,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '루틴 제목 입력',
            hintStyle: TextStyle(color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              key: widget.sessionSectionKey,
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '세션 구성',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ReorderableListView(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              dragBoundaryProvider: _sessionDragBoundary,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                widget.onReorderSplitSessions(
                  widget.selectedSplitTargetIndex,
                  oldIndex,
                  newIndex,
                );
              },
              onReorderStart: widget.onSessionReorderStart,
              onReorderEnd: widget.onSessionReorderEnd,
              children: widget
                  .splitTargetSessions[widget.selectedSplitTargetIndex]
                  .asMap()
                  .entries
                  .map((entry) {
                    final sessionIndex = entry.key;
                    final session = entry.value;

                    return Container(
                      key: ValueKey(
                        'session-${widget.selectedSplitTargetIndex}-$sessionIndex',
                      ),
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
                                  value: session.type.isEmpty
                                      ? ''
                                      : session.type,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: Colors.black87),
                                  iconEnabledColor: Colors.black54,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  items: ['', '운동', '유산소']
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(
                                            type.isEmpty ? '타입 선택' : type,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      widget.onSetSplitSessionType(
                                        widget.selectedSplitTargetIndex,
                                        sessionIndex,
                                        value,
                                      );
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () => widget.onRemoveSplitSession(
                                  widget.selectedSplitTargetIndex,
                                  sessionIndex,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: sessionIndex,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.menu,
                                    color: Colors.black54,
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        session.exercise ?? '운동 선택',
                                        style: TextStyle(
                                          color: session.exercise == null
                                              ? Colors.grey.shade600
                                              : Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey(
                                      'weight-${widget.selectedSplitTargetIndex}-$sessionIndex-${session.exercise}',
                                    ),
                                    initialValue:
                                        session.weight == null
                                        ? ''
                                        : formatWeight(session.weight!),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      WeightInputFormatter(),
                                    ],
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: '무게(kg)',
                                      labelStyle: TextStyle(
                                        color: Colors.black87,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) =>
                                        widget.onSetSplitSessionWeight(
                                          widget.selectedSplitTargetIndex,
                                          sessionIndex,
                                          double.tryParse(value),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _numberInputField(
                                    label: '세트',
                                    value: session.sets,
                                    onChanged: (value) =>
                                        widget.onSetSplitSessionSets(
                                          widget.selectedSplitTargetIndex,
                                          sessionIndex,
                                          int.tryParse(value),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _numberInputField(
                                    label: '반복',
                                    value: session.reps,
                                    onChanged: (value) =>
                                        widget.onSetSplitSessionReps(
                                          widget.selectedSplitTargetIndex,
                                          sessionIndex,
                                          int.tryParse(value),
                                        ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        session.exercise ?? '유산소 종목 선택',
                                        style: TextStyle(
                                          color: session.exercise == null
                                              ? Colors.grey.shade600
                                              : Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CardioDurationPicker(
                              durationSeconds: session.cardioSeconds,
                              onChanged: (seconds) =>
                                  widget.onSetSplitSessionCardioSeconds(
                                    widget.selectedSplitTargetIndex,
                                    sessionIndex,
                                    seconds,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
            Container(
              key: widget.sessionAddButtonKey,
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
                  onTap: () =>
                      widget.onAddSplitSession(widget.selectedSplitTargetIndex),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.red, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.selectedRoutineMode == '주차') ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '주차별 루틴 설정',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.selectedWeekday,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: widget.weeklyRoutine.keys
                      .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)),
                      )
                      .toList(),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: widget.onAddWeeklyWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.key}요일',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (entry.value.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '등록된 루틴이 없습니다.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ...entry.value.map((workout) {
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        workout,
                        style: const TextStyle(color: Colors.black87),
                      ),
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

class _RectDragBoundary extends DragBoundaryDelegate<Rect> {
  _RectDragBoundary(this.boundsForCurrentLayout);

  final Rect? Function() boundsForCurrentLayout;

  @override
  bool isWithinBoundary(Rect draggedObject) {
    final bounds = boundsForCurrentLayout();
    if (bounds == null) return true;
    return bounds.contains(draggedObject.topLeft) &&
        bounds.contains(draggedObject.bottomRight);
  }

  @override
  Rect nearestPositionWithinBoundary(Rect draggedObject) {
    final bounds = boundsForCurrentLayout();
    if (bounds == null) return draggedObject;
    final maxLeft = bounds.right - draggedObject.width;
    final maxTop = bounds.bottom - draggedObject.height;
    final left = maxLeft < bounds.left
        ? bounds.left
        : draggedObject.left.clamp(bounds.left, maxLeft);
    final top = maxTop < bounds.top
        ? bounds.top
        : draggedObject.top.clamp(bounds.top, maxTop);
    return Rect.fromLTWH(left, top, draggedObject.width, draggedObject.height);
  }
}
