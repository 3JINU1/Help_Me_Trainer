import '../models.dart';

class WorkoutProvider {
  final List<WorkoutRoutine> _routines = [];
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
  Map<String, String?> get weekdayRoutineIds => Map.unmodifiable(_weekdayRoutineIds);

  void saveRoutine(WorkoutRoutine routine) {
    _routines.add(routine);
  }

  void addRoutine(WorkoutRoutine routine) {
    saveRoutine(routine);
  }

  void updateRoutineName(String routineId, String newName) {
    final routine = getRoutineById(routineId);
    if (routine == null) return;

    final index = _routines.indexWhere((item) => item.id == routineId);
    if (index == -1) return;

    final updated = WorkoutRoutine(
      id: routine.id,
      name: newName,
      exercises: routine.exercises,
    );
    _routines[index] = updated;
  }

  void deleteRoutine(String routineId) {
    _routines.removeWhere((routine) => routine.id == routineId);

    for (final entry in _weekdayRoutineIds.entries.toList()) {
      if (entry.value == routineId) {
        _weekdayRoutineIds[entry.key] = '';
      }
    }

    _dateRoutineIds.removeWhere((_, value) => value == routineId);
  }

  void assignRoutineToWeekday(String weekday, String routineId) {
    if (_weekdayRoutineIds.containsKey(weekday)) {
      _weekdayRoutineIds[weekday] = routineId;
    }
  }

  void assignRoutineToDate(DateTime date, String routineId) {
    _dateRoutineIds[_normalizeDate(date)] = routineId;
  }

  WorkoutRoutine? getRoutineById(String routineId) {
    return _routines.where((routine) => routine.id == routineId).cast<WorkoutRoutine?>().firstOrNull;
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
