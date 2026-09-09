class Exercise {
  Exercise(this.name);
  final String name;
}

class ExerciseCategory {
  ExerciseCategory(this.title, this.exercises);
  final String title;
  final List<Exercise> exercises;
}

class WorkoutRecord {
  WorkoutRecord({required this.exercise, required this.weight, required this.date});
  final String exercise;
  final int weight;
  final DateTime date;
}

class SplitSession {
  SplitSession({required this.type, this.exercise, this.weight, this.sets, this.reps, this.restSeconds = 60, this.cardioSeconds = 0});

  String type;
  String? exercise;
  int? weight;
  int? sets;
  int? reps;
  int restSeconds;
  int cardioSeconds;
}

class RoutineExercise {
  RoutineExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.type = '운동',
    this.cardioSeconds = 0,
  });

  final String name;
  final int sets;
  final int reps;
  final int weight;
  final String type;
  final int cardioSeconds;
}

class WorkoutRoutine {
  WorkoutRoutine({required this.id, required this.name, required this.exercises});

  final String id;
  final String name;
  final List<RoutineExercise> exercises;
}
