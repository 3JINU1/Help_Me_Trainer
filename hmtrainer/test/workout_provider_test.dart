import 'package:flutter_test/flutter_test.dart';
import 'package:hmtrainer/pages/workout_provider.dart';
import 'package:hmtrainer/models.dart';

void main() {
  test('assigns a routine to a weekday and retrieves it', () {
    final provider = WorkoutProvider();
    final routine = WorkoutRoutine(
      id: 'routine-1',
      name: '테스트 루틴',
      exercises: [
        RoutineExercise(name: '벤치 프레스', sets: 3, reps: 10),
      ],
    );

    provider.addRoutine(routine);
    provider.assignRoutineToWeekday('월', routine.id);

    expect(provider.getRoutineForWeekday('월')?.id, routine.id);
  });
}
