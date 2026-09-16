import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

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

  List<WorkoutRoutine> get routines => List.unmodifiable(_routines);
  List<WorkoutRecord> get workoutRecords => List.unmodifiable(_workoutRecords);
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

    final dateEntries = prefs.getStringList('date_routine_ids') ?? <String>[];
    for (final entry in dateEntries) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        _dateRoutineIds[parts[0]] = parts[1];
      }
    }
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

  Future<void> updateRoutine(WorkoutRoutine routine) async {
    final index = _routines.indexWhere((item) => item.id == routine.id);
    if (index >= 0) {
      _routines[index] = routine;
      await _persistToStorage();
    }
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
    return _completedWorkoutDates.contains(_normalizeDate(date));
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
