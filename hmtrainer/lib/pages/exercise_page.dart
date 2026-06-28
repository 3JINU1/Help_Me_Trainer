import 'package:flutter/material.dart';

import '../models.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({
    super.key,
    required this.routineTitleController,
    required this.splitTargets,
    required this.selectedSplitTargetIndex,
    required this.splitTargetSessions,
    required this.exerciseNames,
    required this.onAddSplitTarget,
    required this.onSetSelectedSplitTarget,
    required this.onSetSplitTarget,
    required this.onAddSplitSession,
    required this.onInsertSplitSession,
    required this.onMoveSplitSession,
    required this.onSetSplitSessionType,
    required this.onSetSplitSessionExercise,
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
  final VoidCallback onAddSplitTarget;
  final void Function(int index) onSetSelectedSplitTarget;
  final void Function(int index, String target) onSetSplitTarget;
  final void Function(int targetIndex) onAddSplitSession;
  final void Function(int targetIndex, int sessionIndex) onInsertSplitSession;
  final void Function(int targetIndex, int sessionIndex, int delta) onMoveSplitSession;
  final void Function(int targetIndex, int sessionIndex, String type) onSetSplitSessionType;
  final void Function(int targetIndex, int sessionIndex, String? exercise) onSetSplitSessionExercise;
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('루틴 모드 선택', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => onSetRoutineMode('분할'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRoutineMode == '분할' ? Colors.white : Colors.white24,
                  foregroundColor: selectedRoutineMode == '분할' ? Colors.red.shade900 : Colors.white,
                ),
                child: const Text('분할 루틴'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onSetRoutineMode('주차'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRoutineMode == '주차' ? Colors.white : Colors.white24,
                  foregroundColor: selectedRoutineMode == '주차' ? Colors.red.shade900 : Colors.white,
                ),
                child: const Text('주차 루틴'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('루틴 제목', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        TextField(
          controller: routineTitleController,
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
          child: Text('휴식 시간', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  valueIndicatorColor: Colors.red.shade900,
                ),
                child: Slider(
                  min: 10,
                  max: 180,
                  divisions: 17,
                  value: restSeconds.toDouble(),
                  label: '$restSeconds초',
                  onChanged: (value) => onChangeRestSeconds(value.toInt()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('$restSeconds초', style: const TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 24),
        if (selectedRoutineMode == '분할') ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('분할 타겟 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...splitTargets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  final selected = index == selectedSplitTargetIndex;
                  return GestureDetector(
                    onTap: () => onSetSelectedSplitTarget(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: selected ? Colors.white : Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: selected ? Colors.red.shade900 : Colors.white,
                            child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Text(value, style: TextStyle(color: selected ? Colors.red.shade900 : Colors.white)),
                        ],
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: onAddSplitTarget,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('분할 타겟 선택', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['상체', '하체', '가슴', '등', '어깨', '유산소', '휴식']
                .map((target) {
                  final isSelected = splitTargets[selectedSplitTargetIndex] == target;
                  return GestureDetector(
                    onTap: () => onSetSplitTarget(selectedSplitTargetIndex, target),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                      ),
                      child: Text(target, style: TextStyle(color: isSelected ? Colors.red.shade900 : Colors.white)),
                    ),
                  );
                })
                .toList(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${splitTargets[selectedSplitTargetIndex]} 세션 구성', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          if (splitTargets[selectedSplitTargetIndex] == '휴식') ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
              child: const Text(
                '휴식은 세션이 필요하지 않습니다.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ] else ...[
            ...splitTargetSessions[selectedSplitTargetIndex].asMap().entries.map((entry) {
              final sessionIndex = entry.key;
              final session = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: session.type,
                            decoration: const InputDecoration(border: InputBorder.none),
                            items: ['스트레칭', '운동', '유산소']
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) onSetSplitSessionType(selectedSplitTargetIndex, sessionIndex, value);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, color: Colors.black54),
                          onPressed: sessionIndex > 0
                              ? () => onMoveSplitSession(selectedSplitTargetIndex, sessionIndex, -1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, color: Colors.black54),
                          onPressed: sessionIndex < splitTargetSessions[selectedSplitTargetIndex].length - 1
                              ? () => onMoveSplitSession(selectedSplitTargetIndex, sessionIndex, 1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
                          onPressed: () => onInsertSplitSession(selectedSplitTargetIndex, sessionIndex),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: session.exercise,
                      decoration: const InputDecoration(
                        labelText: '세션에 운동 추가',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('운동 선택')),
                        ...exerciseNames.map((exercise) => DropdownMenuItem<String?>(value: exercise, child: Text(exercise))),
                      ],
                      onChanged: (value) => onSetSplitSessionExercise(selectedSplitTargetIndex, sessionIndex, value),
                    ),
                    if (session.exercise != null && session.exercise!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('선택된 운동: ${session.exercise}', style: const TextStyle(color: Colors.black54)),
                      ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: () => onAddSplitSession(selectedSplitTargetIndex),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('세션 추가', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
            ),
          ],
        ],
        if (selectedRoutineMode == '주차') ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('주차별 루틴 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedWeekday,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: weeklyRoutine.keys.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                  onChanged: (value) {
                    if (value != null) onSetWeekday(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: weeklyWorkoutController,
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
                onPressed: onAddWeeklyWorkout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                child: const Text('추가'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...weeklyRoutine.entries.map((entry) {
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
