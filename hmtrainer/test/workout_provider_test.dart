import 'package:flutter_test/flutter_test.dart';
import 'package:hmtrainer/pages/workout_provider.dart';
import 'package:hmtrainer/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  test('does not show a weekday routine on an unassigned weekday', () {
    final provider = WorkoutProvider();
    final routine = WorkoutRoutine(
      id: 'weekday-routine',
      name: '월요일 루틴',
      exercises: [RoutineExercise(name: '스쿼트', sets: 3, reps: 10, weight: 60)],
    );

    provider.addRoutine(routine);
    provider.assignRoutineToWeekday('월', routine.id);

    expect(provider.getRoutineForDate(DateTime(2026, 9, 21))?.id, routine.id);
    expect(provider.getRoutineForDate(DateTime(2026, 9, 23)), isNull);
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

  test('saves completed workout records and completion date', () async {
    final provider = WorkoutProvider();
    await provider.ready;
    final date = DateTime(2026, 9, 10);
    final record = WorkoutRecord(exercise: '스쿼트', weight: 100, date: date);

    await provider.addRoutine(
      WorkoutRoutine(
        id: 'completed-routine',
        name: '완료 루틴',
        exercises: [
          RoutineExercise(name: '스쿼트', sets: 3, reps: 10, weight: 100),
        ],
      ),
    );
    await provider.assignRoutineToWeekday('목', 'completed-routine');
    await provider.saveCompletedWorkout(date, [record]);

    expect(provider.workoutRecords.single.exercise, '스쿼트');
    expect(provider.isWorkoutCompletedOn(date), isTrue);
  });

  test(
    'persists progression settings and preserves amount when disabled',
    () async {
      final provider = WorkoutProvider();
      await provider.ready;
      await provider.setExerciseProgressionAmount('스쿼트', 1.75);
      await provider.setExerciseProgressionEnabled('스쿼트', true);
      await provider.setExerciseProgressionEnabled('스쿼트', false);

      final restoredProvider = WorkoutProvider();
      await restoredProvider.ready;
      final setting = restoredProvider.progressionForExercise('스쿼트');

      expect(setting.enabled, isFalse);
      expect(setting.incrementKg, 1.75);
    },
  );

  test('round-trips fractional workout weights', () {
    final record = WorkoutRecord(
      exercise: '스쿼트',
      weight: 81.25,
      date: DateTime(2026, 9, 10),
    );

    expect(WorkoutRecord.fromJson(record.toJson()).weight, 81.25);
  });

  test('applies exercise progression to the next workout only', () async {
    final provider = WorkoutProvider();
    await provider.ready;
    final previousDate = DateTime(2026, 9, 9);
    final workoutDate = DateTime(2026, 9, 10);
    await provider.saveCompletedWorkout(previousDate, [
      WorkoutRecord(exercise: '스쿼트', weight: 80.5, date: previousDate),
    ]);
    await provider.setExerciseProgressionAmount('스쿼트', 1.25);
    await provider.setExerciseProgressionEnabled('스쿼트', true);

    expect(provider.nextWorkoutWeight('스쿼트', 60, workoutDate), 81.75);
    expect(provider.nextWorkoutWeight('데드리프트', 60, workoutDate), 60);
    expect(provider.nextWorkoutWeight('스쿼트', 60, previousDate), 80.5);
  });

  test('persists the initial rest time and ordered alert times', () async {
    final provider = WorkoutProvider();
    await provider.ready;
    await provider.setRestTimerSettings(
      const RestTimerSettings(initialSeconds: 90, alertSeconds: [180, 300]),
    );

    final restoredProvider = WorkoutProvider();
    await restoredProvider.ready;
    expect(restoredProvider.restTimerSettings.initialSeconds, 90);
    expect(restoredProvider.restTimerSettings.alertSeconds, [180, 300]);
  });

  test('rejects rest alerts that are not strictly later than prior alerts', () {
    const settings = RestTimerSettings(
      initialSeconds: 90,
      alertSeconds: [180, 180],
    );
    expect(settings.isValid, isFalse);
  });

  test('rest alert stages progress at initial and extra configured times', () {
    const settings = RestTimerSettings(
      initialSeconds: 90,
      alertSeconds: [180, 300],
    );

    expect(settings.thresholds, [90, 180, 300]);
    expect(settings.alertStageAt(89), 0);
    expect(settings.alertStageAt(90), 1);
    expect(settings.alertStageAt(240), 2);
    expect(settings.alertStageAt(300), 3);
  });

  test(
    'routine exercise only completes when every set reaches target reps',
    () {
      final exercise = RoutineExercise(
        name: '스쿼트',
        sets: 3,
        reps: 10,
        weight: 80,
      );

      expect(exercise.hasCompletedAllSets([10, 10, 10], {0, 1, 2}), isTrue);
      expect(exercise.hasCompletedAllSets([10, 9, 10], {0, 1, 2}), isFalse);
      expect(exercise.hasCompletedAllSets([10, 10], {0, 1}), isFalse);
      expect(exercise.hasCompletedAllSets([10, 10, 10], {0, 1}), isFalse);
    },
  );

  test(
    'only returns applied progression weight for a fully completed exercise',
    () {
      final exercise = RoutineExercise(
        name: '스쿼트',
        sets: 3,
        reps: 10,
        weight: 80,
      );
      const appliedWeight = 81.25;

      expect(
        exercise.completedProgressionWeight(
          progressionEnabled: true,
          repetitionsBySet: [10, 10, 10],
          finalizedSetIndexes: {0, 1, 2},
          appliedWeight: appliedWeight,
        ),
        appliedWeight,
      );
      expect(
        exercise.completedProgressionWeight(
          progressionEnabled: true,
          repetitionsBySet: [10, 9, 10],
          finalizedSetIndexes: {0, 1, 2},
          appliedWeight: appliedWeight,
        ),
        isNull,
      );
      expect(
        exercise.completedProgressionWeight(
          progressionEnabled: false,
          repetitionsBySet: [10, 10, 10],
          finalizedSetIndexes: {0, 1, 2},
          appliedWeight: appliedWeight,
        ),
        isNull,
      );
    },
  );

  test('routine exercise serialization preserves decimal weights', () {
    final exercise = RoutineExercise.fromJson({
      'name': '벤치프레스',
      'sets': 3,
      'reps': 10,
      'weight': 82.75,
    });

    expect(exercise.weight, 82.75);
    expect(RoutineExercise.fromJson(exercise.toJson()).weight, 82.75);
  });

  test('persists applied progression weight to its routine', () async {
    final provider = WorkoutProvider();
    await provider.ready;
    const routineId = 'progressed-routine';
    await provider.saveRoutine(
      WorkoutRoutine(
        id: routineId,
        name: '증량 루틴',
        exercises: [
          RoutineExercise(name: '스쿼트', sets: 3, reps: 10, weight: 80),
          RoutineExercise(name: '벤치프레스', sets: 3, reps: 8, weight: 60),
        ],
      ),
    );

    await provider.updateRoutineExerciseWeights(routineId, {'스쿼트': 81.25});

    final updatedRoutine = provider.getRoutineById(routineId)!;
    expect(updatedRoutine.exercises[0].weight, 81.25);
    expect(updatedRoutine.exercises[1].weight, 60);
    final restoredProvider = WorkoutProvider();
    await restoredProvider.ready;
    expect(
      restoredProvider.getRoutineById(routineId)!.exercises[0].weight,
      81.25,
    );
  });
}
