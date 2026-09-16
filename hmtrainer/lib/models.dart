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
  WorkoutRecord({
    required this.exercise,
    required this.weight,
    required this.date,
  });

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutRecord(
      exercise: json['exercise'] as String,
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String exercise;
  final int weight;
  final DateTime date;

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}

class SplitSession {
  SplitSession({
    required this.type,
    this.exercise,
    this.weight,
    this.sets,
    this.reps,
    this.restSeconds = 60,
    this.cardioSeconds = 0,
  });

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

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      name: json['name'] as String,
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '운동',
      cardioSeconds: (json['cardioSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'type': type,
      'cardioSeconds': cardioSeconds,
    };
  }
}

class WorkoutRoutine {
  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exercises,
  });

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map(
            (exercise) =>
                RoutineExercise.fromJson(exercise as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String id;
  final String name;
  final List<RoutineExercise> exercises;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }
}
