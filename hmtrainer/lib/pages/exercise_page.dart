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
  final VoidCallback onAddSplitTarget;
  final void Function(int index) onSetSelectedSplitTarget;
  final void Function(int index, String target) onSetSplitTarget;
  final void Function(int targetIndex) onAddSplitSession;
  final void Function(int targetIndex, int sessionIndex) onInsertSplitSession;
  final void Function(int targetIndex, int sessionIndex, int delta) onMoveSplitSession;
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
          child: Text('세션 구성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('활동을 추가하세요', style: TextStyle(color: Colors.white70)),
              ElevatedButton(
                onPressed: () => onAddSplitSession(selectedSplitTargetIndex),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
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
                        items: ['', '운동', '유산소', '스트레칭', '휴식']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type.isEmpty ? '타입 선택' : type)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onSetSplitSessionType(selectedSplitTargetIndex, sessionIndex, value);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.black54),
                      onPressed: sessionIndex > 0 ? () => onMoveSplitSession(selectedSplitTargetIndex, sessionIndex, -1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, color: Colors.black54),
                      onPressed: sessionIndex < splitTargetSessions[selectedSplitTargetIndex].length - 1 ? () => onMoveSplitSession(selectedSplitTargetIndex, sessionIndex, 1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
                      onPressed: () => onInsertSplitSession(selectedSplitTargetIndex, sessionIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (session.type == '운동') ...[
                  DropdownButtonFormField<String?>(
                    initialValue: session.exercise,
                    decoration: const InputDecoration(
                      labelText: '운동',
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: session.weight?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '무게(kg)', border: OutlineInputBorder()),
                          onChanged: (v) => onSetSplitSessionWeight(selectedSplitTargetIndex, sessionIndex, int.tryParse(v)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: session.sets?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '세트', border: OutlineInputBorder()),
                          onChanged: (v) => onSetSplitSessionSets(selectedSplitTargetIndex, sessionIndex, int.tryParse(v)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: session.reps?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '반복', border: OutlineInputBorder()),
                          onChanged: (v) => onSetSplitSessionReps(selectedSplitTargetIndex, sessionIndex, int.tryParse(v)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('휴식(초):', style: TextStyle(color: Colors.black54)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: session.restSeconds.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          onChanged: (v) {
                            final sec = int.tryParse(v) ?? 0;
                            onSetSplitSessionRestSeconds(selectedSplitTargetIndex, sessionIndex, sec);
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (session.type == '유산소') ...[
                  DropdownButtonFormField<String?>(
                    initialValue: session.exercise,
                    decoration: const InputDecoration(
                      labelText: '유산소 종목',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('종목 선택')),
                      ...exerciseNames.map((exercise) => DropdownMenuItem<String?>(value: exercise, child: Text(exercise))),
                    ],
                    onChanged: (value) => onSetSplitSessionExercise(selectedSplitTargetIndex, sessionIndex, value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('수행시간(초):', style: TextStyle(color: Colors.black54)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: session.cardioSeconds.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          onChanged: (v) => onSetSplitSessionCardioSeconds(selectedSplitTargetIndex, sessionIndex, int.tryParse(v) ?? 0),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('추가 설정 없음', style: TextStyle(color: Colors.black54)),
                  ),
                ],
              ],
            ),
          );
        }),
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
