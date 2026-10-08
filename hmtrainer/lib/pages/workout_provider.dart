import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

class ExerciseProgressionSetting {
  const ExerciseProgressionSetting({
    this.enabled = false,
    this.incrementKg = 1.25,
  });

  final bool enabled;
  final double incrementKg;

  ExerciseProgressionSetting copyWith({bool? enabled, double? incrementKg}) {
    return ExerciseProgressionSetting(
      enabled: enabled ?? this.enabled,
      incrementKg: incrementKg ?? this.incrementKg,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'incrementKg': incrementKg,
  };

  factory ExerciseProgressionSetting.fromJson(Map<String, dynamic> json) {
    final storedIncrement =
        (json['incrementKg'] as num?)?.toDouble() ?? 1.25;
    final clampedIncrement = storedIncrement.clamp(1.25, 10).toDouble();
    final increment =
        1.25 + ((clampedIncrement - 1.25) / 0.25).round() * 0.25;
    return ExerciseProgressionSetting(
      enabled: json['enabled'] as bool? ?? false,
      incrementKg: increment,
    );
  }
}

class RestTimerSettings {
  const RestTimerSettings({
    this.initialSeconds = 60,
    this.alertSeconds = const [],
  });

  final int initialSeconds;
  final List<int> alertSeconds;

  static const defaultInitialSeconds = 60;
  static const minimumInitialSeconds = 10;
  static const maximumInitialSeconds = 180;
  static const minimumAlertGapSeconds = 60;
  static const maximumAlertSeconds = 3600;

  RestTimerSettings copyWith({int? initialSeconds, List<int>? alertSeconds}) {
    return RestTimerSettings(
      initialSeconds: initialSeconds ?? this.initialSeconds,
      alertSeconds: alertSeconds ?? this.alertSeconds,
    );
  }

  List<int> get thresholds => [initialSeconds, ...alertSeconds];

  int alertStageAt(int elapsedSeconds) =>
      thresholds.takeWhile((seconds) => seconds <= elapsedSeconds).length;

  bool get isValid {
    if (initialSeconds < minimumInitialSeconds ||
        initialSeconds > maximumInitialSeconds) {
      return false;
    }
    var previous = initialSeconds;
    for (final seconds in alertSeconds) {
      if (seconds < previous + minimumAlertGapSeconds ||
          seconds > maximumAlertSeconds) {
        return false;
      }
      previous = seconds;
    }
    return true;
  }

  static const defaults = RestTimerSettings(
    initialSeconds: defaultInitialSeconds,
  );
}

class WorkoutProvider {
  Future<void> get ready => _ready;

  late final Future<void> _ready = loadFromStorage();

  final List<WorkoutRoutine> _routines = [];
  final List<WorkoutRecord> _workoutRecords = [];
  final Set<String> _completedWorkoutDates = {};
  final Map<String, String?> _weekdayRoutineIds = {
    '월': null,
    '화': null,
    '수': null,
    '목': null,
    '금': null,
    '토': null,
    '일': null,
  };
  final Map<String, String> _dateRoutineIds = {};
  final Map<String, ExerciseProgressionSetting> _exerciseProgressions = {};
  RestTimerSettings _restTimerSettings = RestTimerSettings.defaults;

  List<WorkoutRoutine> get routines => List.unmodifiable(_routines);
  List<WorkoutRecord> get workoutRecords => List.unmodifiable(_workoutRecords);
  Map<String, ExerciseProgressionSetting> get exerciseProgressions =>
      Map.unmodifiable(_exerciseProgressions);
  RestTimerSettings get restTimerSettings => _restTimerSettings;
  Map<String, String?> get weekdayRoutineIds =>
      Map.unmodifiable(_weekdayRoutineIds);

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final routinesJson = prefs.getStringList('workout_routines') ?? <String>[];
    _routines
      ..clear()
      ..addAll(
        routinesJson
            .map((json) => WorkoutRoutine.fromJson(jsonDecode(json)))
            .toList(),
      );

    final recordsJson = prefs.getStringList('workout_records') ?? <String>[];
    _workoutRecords
      ..clear()
      ..addAll(
        recordsJson.map((json) => WorkoutRecord.fromJson(jsonDecode(json))),
      );

    final progressionJson = prefs.getString('exercise_progressions');
    _exerciseProgressions
      ..clear()
      ..addAll(
        progressionJson == null
            ? const <String, ExerciseProgressionSetting>{}
            : (jsonDecode(progressionJson) as Map<String, dynamic>).map(
                (name, value) => MapEntry(
                  name,
                  ExerciseProgressionSetting.fromJson(
                    value as Map<String, dynamic>,
                  ),
                ),
              ),
      );

    final storedInitialSeconds =
        prefs.getInt('rest_timer_initial_seconds') ??
        RestTimerSettings.defaultInitialSeconds;
    final initialSeconds = storedInitialSeconds
        .clamp(
          RestTimerSettings.minimumInitialSeconds,
          RestTimerSettings.maximumInitialSeconds,
        )
        .toInt();
    var previousAlertSeconds = initialSeconds;
    final alertSeconds = <int>[];
    for (final value
        in prefs.getStringList('rest_timer_alert_seconds') ?? const <String>[]) {
      final seconds = int.tryParse(value);
      if (seconds == null ||
          seconds < previousAlertSeconds +
              RestTimerSettings.minimumAlertGapSeconds ||
          seconds > RestTimerSettings.maximumAlertSeconds) {
        continue;
      }
      alertSeconds.add(seconds);
      previousAlertSeconds = seconds;
    }
    _restTimerSettings = RestTimerSettings(
      initialSeconds: initialSeconds,
      alertSeconds: List.unmodifiable(alertSeconds),
    );

    _completedWorkoutDates
      ..clear()
      ..addAll(prefs.getStringList('completed_workout_dates') ?? <String>[]);

    final weekdayEntries =
        prefs.getStringList('weekday_routine_ids') ?? <String>[];
    for (final entry in weekdayEntries) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        _weekdayRoutineIds[parts[0]] = parts[1].isEmpty ? null : parts[1];
      }
    }

    _dateRoutineIds.clear();
    await prefs.remove('date_routine_ids');
  }

  Future<void> saveRoutine(WorkoutRoutine routine) async {
    final existingIndex = _routines.indexWhere((item) => item.id == routine.id);
    if (existingIndex >= 0) {
      _routines[existingIndex] = routine;
    } else {
      _routines.add(routine);
    }
    await _persistToStorage();
  }

  ExerciseProgressionSetting progressionForExercise(String exercise) =>
      _exerciseProgressions[exercise] ??
      const ExerciseProgressionSetting();

  double nextWorkoutWeight(
    String exercise,
    double routineWeight,
    DateTime date,
  ) {
    final records =
        _workoutRecords
            .where((record) => record.exercise == exercise)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final recordsForDate = records.where(
      (record) =>
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day,
    );
    final baseline = recordsForDate.isNotEmpty
        ? recordsForDate.last.weight
        : records.isNotEmpty
        ? records.last.weight
        : routineWeight;
    final progression = progressionForExercise(exercise);
    return baseline +
        (progression.enabled && recordsForDate.isEmpty
            ? progression.incrementKg
            : 0);
  }

  Future<void> setExerciseProgressionEnabled(
    String exercise,
    bool enabled,
  ) async {
    await ready;
    final current = progressionForExercise(exercise);
    _exerciseProgressions[exercise] = current.copyWith(enabled: enabled);
    await _persistExerciseProgressions();
  }

  Future<void> setExerciseProgressionAmount(
    String exercise,
    double incrementKg,
  ) async {
    if (incrementKg < 1.25 ||
        incrementKg > 10 ||
        ((incrementKg - 1.25) / 0.25 - ((incrementKg - 1.25) / 0.25).round())
                .abs() >
            0.000001) {
      throw ArgumentError.value(incrementKg, 'incrementKg');
    }
    await ready;
    final current = progressionForExercise(exercise);
    _exerciseProgressions[exercise] = current.copyWith(
      incrementKg: incrementKg,
    );
    await _persistExerciseProgressions();
  }

  Future<void> _persistExerciseProgressions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'exercise_progressions',
      jsonEncode(
        _exerciseProgressions.map(
          (name, setting) => MapEntry(name, setting.toJson()),
        ),
      ),
    );
  }

  Future<void> setRestTimerSettings(RestTimerSettings settings) async {
    if (!settings.isValid) {
      throw ArgumentError.value(settings, 'settings');
    }
    await ready;
    _restTimerSettings = settings.copyWith(
      alertSeconds: List.unmodifiable(settings.alertSeconds),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'rest_timer_initial_seconds',
      _restTimerSettings.initialSeconds,
    );
    await prefs.setStringList(
      'rest_timer_alert_seconds',
      _restTimerSettings.alertSeconds
          .map((seconds) => seconds.toString())
          .toList(),
    );
  }

  Future<void> updateRoutine(WorkoutRoutine routine) async {
    final index = _routines.indexWhere((item) => item.id == routine.id);
    if (index >= 0) {
      _routines[index] = routine;
      await _persistToStorage();
    }
  }

  Future<void> updateRoutineExerciseWeights(
    String routineId,
    Map<String, double> weights,
  ) async {
    final routine = getRoutineById(routineId);
    if (routine == null || weights.isEmpty) return;
    final updatedRoutine = WorkoutRoutine(
      id: routine.id,
      name: routine.name,
      exercises: routine.exercises
          .map(
            (exercise) => weights.containsKey(exercise.name)
                ? exercise.copyWith(weight: weights[exercise.name])
                : exercise,
          )
          .toList(),
    );
    await updateRoutine(updatedRoutine);
  }

  Future<void> addRoutine(WorkoutRoutine routine) async {
    await saveRoutine(routine);
  }

  Future<void> deleteRoutine(String routineId) async {
    _routines.removeWhere((routine) => routine.id == routineId);
    _weekdayRoutineIds.updateAll(
      (_, assignedRoutineId) =>
          assignedRoutineId == routineId ? null : assignedRoutineId,
    );
    _dateRoutineIds.removeWhere(
      (_, assignedRoutineId) => assignedRoutineId == routineId,
    );
    await _persistToStorage();
  }

  bool isWorkoutCompletedOn(DateTime date) {
    return getRoutineForDate(date) != null &&
        _completedWorkoutDates.contains(_normalizeDate(date));
  }

  Future<void> clearCompletedWorkout(DateTime date) async {
    final dateKey = _normalizeDate(date);
    _completedWorkoutDates.remove(dateKey);
    _workoutRecords.removeWhere(
      (record) => _normalizeDate(record.date) == dateKey,
    );
    await _persistToStorage();
  }

  Future<void> saveCompletedWorkout(
    DateTime date,
    List<WorkoutRecord> records,
  ) async {
    await ready;
    final dateKey = _normalizeDate(date);
    _workoutRecords.removeWhere(
      (record) => _normalizeDate(record.date) == dateKey,
    );
    _workoutRecords.addAll(records);
    _completedWorkoutDates.add(dateKey);
    await _persistToStorage();
  }

  Future<void> assignRoutineToWeekday(String weekday, String routineId) async {
    if (_weekdayRoutineIds.containsKey(weekday)) {
      _weekdayRoutineIds[weekday] = routineId;
      await _persistToStorage();
    }
  }

  Future<void> assignRoutineToDate(DateTime date, String routineId) async {
    _dateRoutineIds[_normalizeDate(date)] = routineId;
    await _persistToStorage();
  }

  WorkoutRoutine? getRoutineById(String routineId) {
    return _routines
        .where((routine) => routine.id == routineId)
        .cast<WorkoutRoutine?>()
        .firstOrNull;
  }

  Future<void> _persistToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final routinesJson = _routines
        .map((routine) => jsonEncode(routine.toJson()))
        .toList();
    await prefs.setStringList('workout_routines', routinesJson);

    final weekdayEntries = _weekdayRoutineIds.entries
        .map((entry) => '${entry.key}|${entry.value ?? ''}')
        .toList();
    await prefs.setStringList('weekday_routine_ids', weekdayEntries);

    final dateEntries = _dateRoutineIds.entries
        .map((entry) => '${entry.key}|${entry.value}')
        .toList();
    await prefs.setStringList('date_routine_ids', dateEntries);

    final recordsJson = _workoutRecords
        .map((record) => jsonEncode(record.toJson()))
        .toList();
    await prefs.setStringList('workout_records', recordsJson);
    await prefs.setStringList(
      'completed_workout_dates',
      _completedWorkoutDates.toList(),
    );
  }

  WorkoutRoutine? getRoutineForWeekday(String weekday) {
    final routineId = _weekdayRoutineIds[weekday];
    if (routineId == null) return null;
    return getRoutineById(routineId);
  }

  WorkoutRoutine? getRoutineForDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    final dateRoutineId = _dateRoutineIds[dateKey];
    if (dateRoutineId != null) {
      return getRoutineById(dateRoutineId);
    }

    final weekday = _weekdayLabel(date.weekday);
    return getRoutineForWeekday(weekday);
  }

  String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[weekday - 1];
  }

  String _normalizeDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
