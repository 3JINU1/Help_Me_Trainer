import 'package:flutter_test/flutter_test.dart';
import 'package:hmtrainer/pages/workout_provider.dart';
import 'package:hmtrainer/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('복원 시 누락된 숫자 필드에 기본값을 사용한다', () {
    final routine = WorkoutRoutine.fromJson({
      'id': 'legacy-routine',
      'name': '기존 루틴',
      'exercises': [
        {'name': '스쿼트'},
      ],
    });

    expect(routine.exercises.single.sets, 0);
    expect(routine.exercises.single.reps, 0);
    expect(routine.exercises.single.weight, 0);
    expect(routine.exercises.single.cardioSeconds, 0);
  });

  test('assigns a routine to a weekday and retrieves it', () {
    final provider = WorkoutProvider();
    final routine = WorkoutRoutine(
      id: 'routine-1',
      name: '테스트 루틴',
      exercises: [
        RoutineExercise(name: '벤치 프레스', sets: 3, reps: 10, weight: 80),
      ],
    );

    provider.addRoutine(routine);
    provider.assignRoutineToWeekday('월', routine.id);

    expect(provider.getRoutineForWeekday('월')?.id, routine.id);
  });

  test('preserves cardio session metadata for a saved routine', () {
    final provider = WorkoutProvider();
    final routine = WorkoutRoutine(
      id: 'routine-2',
      name: '유산소 루틴',
      exercises: [
        RoutineExercise(
          name: '러닝머신',
          sets: 1,
          reps: 0,
          weight: 0,
          type: '유산소',
          cardioSeconds: 1800,
        ),
      ],
    );

    provider.addRoutine(routine);

    final saved = provider.getRoutineById(routine.id)!;
    expect(saved.exercises.single.type, '유산소');
    expect(saved.exercises.single.cardioSeconds, 1800);
  });
}
