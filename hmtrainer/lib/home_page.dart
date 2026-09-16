import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'pages/calendar_page.dart';
import 'pages/exercise_page.dart';
import 'pages/progress_page.dart';
import 'pages/settings_page.dart';
import 'pages/workout_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _isWorkoutMode = false;
  bool _isPlaying = false;
  bool _isResting = false;
  int _restRemainingSeconds = 60;
  Timer? _restTimer;
  final Map<String, List<int?>> _exerciseSetProgress = {};
  final Map<String, Map<int, Timer?>> _setTouchTimers = {};
  final Map<String, Set<int>> _finalizedSetIndexes = {};
  final Map<String, Timer?> _cardioTimers = {};
  final Map<String, int> _cardioRemainingSeconds = {};
  final Map<String, bool> _cardioRunning = {};
  final List<String> _exerciseNames = const [
    '바벨 스쿼트',
    '프론트 스쿼트',
    '고블릿 스쿼트',
    '덤벨 스쿼트',
    '리버스 런지',
    '워킹 런지',
    '스플릿 스쿼트',
    '레그 프레스',
    '레그 익스텐션',
    '레그 컬',
    '데드리프트',
    '굿모닝',
    '루마니안 데드리프트',
    '스티프 레그 데드리프트',
    '글루트 브릿지',
    '힙 쓰러스트',
    '벤치 프레스',
    '플랫 벤치프레스',
    '인클라인 벤치프레스',
    '디클라인 벤치프레스',
    '덤벨 벤치프레스',
    '인클라인 덤벨 프레스',
    '디클라인 덤벨 프레스',
    '체스트 프레스 머신',
    '푸시업',
    '딥스',
    '케이블 플라이',
    '덤벨 플라이',
    '풀업',
    '친업',
    '렛 풀다운',
    '시티드 케이블 로우',
    '바벨 로우',
    '덤벨 로우',
    '티바 로우',
    '케이블 로우',
    '오버헤드 프레스',
    '스미스 머신 숄더 프레스',
    '덤벨 숄더 프레스',
    '사이드 레터럴 레이즈',
    '프론트 레터럴 레이즈',
    '리어 델트 플라이',
    '페이스 풀',
    '케이블 푸쉬다운',
    '라잉 트라이셉스 익스텐션',
    '해머 컬',
    '바벨 컬',
    '이너 컬',
    '크런치',
    '러시안 트위스트',
    '레그 레이즈',
    '플랭크',
    '사이드 플랭크',
    '버터플라이',
    '마운틴 클라이머',
    '스쿼트 점프',
    '버피',
    '케틀벨 스윙',
    '덤벨 스윙',
    '덤벨 쓰러스트',
    '캐럴 워크',
    '백 익스텐션',
    '힙 어브덕션',
    '힙 어드덕션',
    '윗몸 일으키기',
    '머신 숄더 프레스',
    '재활 스쿼트',
    '체스트 스프레더',
    '아놀드 프레스',
    '스티프 바벨 데드리프트',
    '토마호크',
    '바벨 벤치 프레스',
    '징크스',
  ];
  final List<String> _cardioExerciseNames = const [
    '런닝머신',
    '실내 자전거',
    '싸이클',
    '스피닝',
    '엘립티컬',
    '스텝퍼',
    '로잉 머신',
    '점프 로프',
    '걷기',
    '달리기',
    '계단 오르기',
    '버피',
    '마운틴 클라이머',
    '스쿼트 점프',
    '케틀벨 스윙',
    '캐럴 워크',
  ];
  final TextEditingController _routineTitleController = TextEditingController();
  final TextEditingController _weeklyWorkoutController =
      TextEditingController();
  final TextEditingController _planController = TextEditingController();
  final Map<DateTime, List<String>> _plannedWorkouts = {};
  final WorkoutProvider _workoutProvider = WorkoutProvider();
  final Uuid _uuid = const Uuid();
  final List<String> _splitTargets = ['상체'];
  int _selectedSplitTargetIndex = 0;
  final List<List<SplitSession>> _splitTargetSessions = [[]];
  final Map<String, List<String>> _weeklyRoutine = {
    '월': [],
    '화': [],
    '수': [],
    '목': [],
    '금': [],
    '토': [],
    '일': [],
  };
  final List<String> _draftRoutineNames = [];
  int? _selectedDraftRoutineIndex;
  String _selectedRoutineMode = '분할';
  String _selectedWeekday = '월';
  bool _autoSync = true;
  bool _weekendSkipped = false;
  int _restSeconds = 60;
  String? _selectedRoutineId;

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    await _workoutProvider.ready;
    if (mounted) setState(() {});
  }

  void _onNavTap(int index) {
    if (_isWorkoutMode) {
      _stopRestTimer();
      _cardioTimers.forEach((_, timer) => timer?.cancel());
    }

    setState(() {
      _selectedIndex = index;
      if (_isWorkoutMode) {
        _isWorkoutMode = false;
        _isPlaying = false;
        _cardioRunning.updateAll((_, __) => false);
      }
    });
  }

  void _toggleWorkoutMode() {
    final hasExistingProgress =
        _exerciseSetProgress.isNotEmpty ||
        _finalizedSetIndexes.isNotEmpty ||
        _cardioRemainingSeconds.isNotEmpty;

    setState(() {
      if (!_isWorkoutMode && hasExistingProgress) {
        _isWorkoutMode = true;
        _isPlaying = true;
        return;
      }

      _isWorkoutMode = !_isWorkoutMode;
      _isPlaying = _isWorkoutMode;
      if (_isWorkoutMode) {
        _initializeWorkoutProgress();
      }
    });
  }

  void _toggleWorkoutPlaying() {
    if (!_isWorkoutMode) {
      setState(() {
        _isWorkoutMode = true;
        _isPlaying = true;
      });
      return;
    }

    if (_isPlaying) {
      _stopRestTimer();
      _cardioTimers.forEach((_, timer) => timer?.cancel());
      setState(() {
        _isPlaying = false;
        _isWorkoutMode = false;
        _cardioRunning.updateAll((_, __) => false);
      });
      return;
    }

    setState(() {
      _isWorkoutMode = true;
      _isPlaying = true;
    });

    if (_isResting && _restRemainingSeconds > 0) {
      _startRestTimer();
    }

    for (final entry in _cardioRemainingSeconds.entries) {
      if (entry.value > 0) {
        _startCardioTimer(entry.key);
      }
    }
  }

  void _initializeWorkoutProgress() {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    _exerciseSetProgress.clear();
    _finalizedSetIndexes.clear();
    _cardioTimers.forEach((key, timer) => timer?.cancel());
    _cardioTimers.clear();
    _cardioRemainingSeconds.clear();
    _cardioRunning.clear();
    if (routine == null) return;

    for (final exercise in routine.exercises) {
      _exerciseSetProgress[exercise.name] = List<int?>.filled(
        exercise.sets,
        null,
        growable: false,
      );
      if (exercise.type == '유산소') {
        _cardioRemainingSeconds[exercise.name] = exercise.cardioSeconds;
        _cardioRunning[exercise.name] = false;
      }
    }

    _isResting = false;
    _restRemainingSeconds = _restSeconds;
    _restTimer?.cancel();
  }

  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _startCardioTimer(String exerciseName) {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    final exercise = routine?.exercises.firstWhere(
      (item) => item.name == exerciseName,
      orElse: () => RoutineExercise(
        name: exerciseName,
        sets: 0,
        reps: 0,
        weight: 0,
        type: '유산소',
      ),
    );
    if (exercise == null || exercise.type != '유산소') return;

    final remaining =
        _cardioRemainingSeconds[exerciseName] ?? exercise.cardioSeconds;
    if (remaining <= 0) return;
    if (_cardioRunning[exerciseName] == true) return;

    _cardioRunning[exerciseName] = true;
    _cardioTimers[exerciseName]?.cancel();
    _cardioTimers[exerciseName] = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted) return;
      final currentValue =
          (_cardioRemainingSeconds[exerciseName] ?? exercise.cardioSeconds);
      if (currentValue <= 1) {
        timer.cancel();
        _cardioTimers[exerciseName] = null;
        _cardioRunning[exerciseName] = false;
        setState(() {
          _cardioRemainingSeconds[exerciseName] = 0;
        });
        return;
      }

      setState(() {
        _cardioRemainingSeconds[exerciseName] = currentValue - 1;
      });
    });
    setState(() {});
  }

  void _pauseCardioTimer(String exerciseName) {
    _cardioTimers[exerciseName]?.cancel();
    _cardioTimers[exerciseName] = null;
    _cardioRunning[exerciseName] = false;
    setState(() {});
  }

  bool _isSetFinalized(String exerciseName, int setIndex) {
    return _finalizedSetIndexes[exerciseName]?.contains(setIndex) ?? false;
  }

  bool _isExerciseCompleted(String exerciseName) {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    if (routine == null) return false;

    final exercise = routine.exercises.firstWhere(
      (item) => item.name == exerciseName,
      orElse: () =>
          RoutineExercise(name: exerciseName, sets: 0, reps: 0, weight: 0),
    );

    if (exercise.type == '유산소') {
      return (_cardioRemainingSeconds[exerciseName] ??
              exercise.cardioSeconds) <=
          0;
    }

    final progress =
        _exerciseSetProgress[exerciseName] ??
        List<int?>.filled(exercise.sets, null, growable: false);

    for (var index = 0; index < progress.length; index++) {
      if (progress[index] == null || !_isSetFinalized(exerciseName, index)) {
        return false;
      }
    }
    return true;
  }

  bool _isExerciseUnlocked(String exerciseName) {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    if (routine == null) return true;

    final index = routine.exercises.indexWhere(
      (exercise) => exercise.name == exerciseName,
    );
    if (index <= 0) return true;

    return List.generate(
      index,
      (i) => routine.exercises[i],
    ).every((exercise) => _isExerciseCompleted(exercise.name));
  }

  void _resetSetValue(String exerciseName, int setIndex) {
    final progress = _exerciseSetProgress[exerciseName];
    if (progress == null || setIndex < 0 || setIndex >= progress.length) return;

    _setTouchTimers[exerciseName]?[setIndex]?.cancel();
    _finalizedSetIndexes[exerciseName]?.remove(setIndex);
    progress[setIndex] = null;
    setState(() {});
  }

  void _startSetTouchTimer(String exerciseName, int setIndex) {
    final progress = _exerciseSetProgress[exerciseName];
    if (progress == null || setIndex < 0 || setIndex >= progress.length) return;
    if (_isSetFinalized(exerciseName, setIndex)) return;
    if (!_isExerciseUnlocked(exerciseName)) return;

    final previousSetDone =
        setIndex == 0 ||
        List.generate(
          setIndex,
          (index) => index,
        ).every((index) => _isSetFinalized(exerciseName, index));
    if (!previousSetDone) return;

    _setTouchTimers.putIfAbsent(exerciseName, () => {});
    _setTouchTimers[exerciseName]![setIndex]?.cancel();

    final timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      _finalizedSetIndexes
          .putIfAbsent(exerciseName, () => <int>{})
          .add(setIndex);
      _startRestTimer();
      setState(() {});
    });

    _setTouchTimers[exerciseName]![setIndex] = timer;
  }

  void _recordSetValue(String exerciseName, int setIndex) {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    final exercise = routine?.exercises.firstWhere(
      (item) => item.name == exerciseName,
      orElse: () =>
          RoutineExercise(name: exerciseName, sets: 0, reps: 0, weight: 0),
    );

    if (exercise == null) return;
    if (!_isExerciseUnlocked(exerciseName)) return;

    final progress = _exerciseSetProgress[exerciseName];
    if (progress == null || setIndex < 0 || setIndex >= progress.length) return;
    if (_isSetFinalized(exerciseName, setIndex)) return;

    final previousSetDone =
        setIndex == 0 ||
        List.generate(
          setIndex,
          (index) => index,
        ).every((index) => _isSetFinalized(exerciseName, index));
    if (!previousSetDone) return;

    final current = progress[setIndex];
    if (current == null) {
      progress[setIndex] = exercise.reps;
    } else {
      progress[setIndex] = current > 0 ? current - 1 : 0;
    }

    _startSetTouchTimer(exerciseName, setIndex);
    setState(() {});
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _isResting = true;
    _restRemainingSeconds = _restSeconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restRemainingSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isResting = false;
            _restRemainingSeconds = _restSeconds;
          });
        }
        return;
      }

      setState(() {
        _restRemainingSeconds -= 1;
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    _isResting = false;
    _restRemainingSeconds = _restSeconds;
  }

  List<String> _todayWorkoutSummary() {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    return routine?.exercises.map((exercise) => exercise.name).toList() ??
        const [];
  }

  void _addPlan() {
    final text = _planController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final key = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      _plannedWorkouts.putIfAbsent(key, () => []);
      _plannedWorkouts[key]!.add(text);
      _planController.clear();
    });
  }

  List<String> _plansFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _plannedWorkouts[key] ?? [];
  }

  String _weekdayLabelForDate(DateTime date) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[date.weekday - 1];
  }

  bool _hasRoutineIndicatorForDate(DateTime date) {
    final weekday = _weekdayLabelForDate(date);
    final hasAssignedRoutine =
        (_workoutProvider.weekdayRoutineIds[weekday] ?? '').isNotEmpty;
    return hasAssignedRoutine || _plansFor(date).isNotEmpty;
  }

  void _showTopMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _onSelectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _addSplitTarget() {
    if (_splitTargets.length >= 7) return;
    setState(() {
      _splitTargets.add('휴식');
      _splitTargetSessions.add([
        SplitSession(type: '운동'),
        SplitSession(type: '유산소'),
      ]);
      _selectedSplitTargetIndex = _splitTargets.length - 1;
    });
  }

  void _setSplitTarget(int index, String target) {
    setState(() {
      _splitTargets[index] = target;
    });
  }

  void _setSelectedSplitTarget(int index) {
    setState(() {
      _selectedSplitTargetIndex = index;
    });
  }

  void _addSplitSession(int targetIndex) {
    setState(() {
      _splitTargetSessions[targetIndex].add(SplitSession(type: ''));
    });
  }

  void _insertSplitSession(int targetIndex, int sessionIndex) {
    setState(() {
      _splitTargetSessions[targetIndex].insert(
        sessionIndex + 1,
        SplitSession(type: '운동'),
      );
    });
  }

  void _moveSplitSession(int targetIndex, int sessionIndex, int delta) {
    final sessions = _splitTargetSessions[targetIndex];
    final newIndex = sessionIndex + delta;
    if (newIndex < 0 || newIndex >= sessions.length) return;
    setState(() {
      final item = sessions.removeAt(sessionIndex);
      sessions.insert(newIndex, item);
    });
  }

  void _removeSplitSession(int targetIndex, int sessionIndex) {
    setState(() {
      _splitTargetSessions[targetIndex].removeAt(sessionIndex);
    });
  }

  void _reorderSplitSessions(int targetIndex, int oldIndex, int newIndex) {
    setState(() {
      final sessions = List<SplitSession>.from(
        _splitTargetSessions[targetIndex],
      );
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final session = sessions.removeAt(oldIndex);
      sessions.insert(newIndex, session);
      _splitTargetSessions[targetIndex] = sessions;
    });
  }

  void _setSplitSessionType(int targetIndex, int sessionIndex, String type) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].type = type;
    });
  }

  void _setSplitSessionExercise(
    int targetIndex,
    int sessionIndex,
    String? exercise,
  ) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].exercise = exercise;
    });
  }

  void _setSplitSessionWeight(int targetIndex, int sessionIndex, int? weight) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].weight = weight;
    });
  }

  void _setSplitSessionSets(int targetIndex, int sessionIndex, int? sets) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].sets = sets;
    });
  }

  void _setSplitSessionReps(int targetIndex, int sessionIndex, int? reps) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].reps = reps;
    });
  }

  void _setSplitSessionRestSeconds(
    int targetIndex,
    int sessionIndex,
    int restSeconds,
  ) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].restSeconds = restSeconds;
    });
  }

  void _setSplitSessionCardioSeconds(
    int targetIndex,
    int sessionIndex,
    int seconds,
  ) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].cardioSeconds = seconds;
    });
  }

  void _setWeekday(String value) {
    setState(() {
      _selectedWeekday = value;
    });
  }

  void _addWeeklyWorkout() {
    final text = _weeklyWorkoutController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _weeklyRoutine[_selectedWeekday]?.add(text);
      _weeklyWorkoutController.clear();
    });
  }

  void _resetRoutineEditor({String? title}) {
    _selectedRoutineId = null;
    _selectedSplitTargetIndex = 0;
    _routineTitleController.text = title ?? '';
    _splitTargets
      ..clear()
      ..add('상체');
    _splitTargetSessions
      ..clear()
      ..add(<SplitSession>[]);
  }

  void _createDraftRoutineChip() {
    final draftName = '루틴 ${_draftRoutineNames.length + 1}';
    _draftRoutineNames.add(draftName);
    _selectedDraftRoutineIndex = _draftRoutineNames.length - 1;
    _resetRoutineEditor(title: draftName);
    setState(() {});
  }

  void _removeDraftRoutineChip(int index) {
    _draftRoutineNames.removeAt(index);
    if (_selectedDraftRoutineIndex == index) {
      _selectedDraftRoutineIndex = null;
    } else if (_selectedDraftRoutineIndex != null &&
        _selectedDraftRoutineIndex! > index) {
      _selectedDraftRoutineIndex = _selectedDraftRoutineIndex! - 1;
    }
    if (_draftRoutineNames.isEmpty) {
      _resetRoutineEditor();
    }
    setState(() {});
  }

  void _saveRoutine() {
    final title = _routineTitleController.text.trim();
    if (title.isEmpty) return;

    final exercises = <RoutineExercise>[];
    for (final session in _splitTargetSessions[_selectedSplitTargetIndex]) {
      if (session.exercise == null || session.exercise!.isEmpty) {
        continue;
      }

      if (session.type == '운동') {
        exercises.add(
          RoutineExercise(
            name: session.exercise!,
            sets: session.sets ?? 0,
            reps: session.reps ?? 0,
            weight: session.weight ?? 0,
            type: '운동',
          ),
        );
      } else if (session.type == '유산소') {
        exercises.add(
          RoutineExercise(
            name: session.exercise!,
            sets: 1,
            reps: 0,
            weight: 0,
            type: '유산소',
            cardioSeconds: session.cardioSeconds,
          ),
        );
      }
    }

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장할 운동이 없습니다.')));
      return;
    }

    final routine = WorkoutRoutine(
      id: _uuid.v4(),
      name: title,
      exercises: exercises,
    );
    _workoutProvider.saveRoutine(routine);
    _workoutProvider.assignRoutineToWeekday(_selectedWeekday, routine.id);
    _selectedRoutineId = routine.id;

    if (_selectedDraftRoutineIndex != null &&
        _selectedDraftRoutineIndex! < _draftRoutineNames.length) {
      _draftRoutineNames.removeAt(_selectedDraftRoutineIndex!);
      _selectedDraftRoutineIndex = null;
    }

    _resetRoutineEditor();
    _showTopMessage('$title 루틴이 저장되었습니다.');
    setState(() {});
  }

  void _loadRoutine(String routineId) {
    final routine = _workoutProvider.getRoutineById(routineId);
    if (routine == null) return;

    setState(() {
      _selectedRoutineId = routine.id;
      _routineTitleController.text = routine.name;
      _splitTargets.clear();
      _splitTargetSessions.clear();
      _splitTargets.add('상체');
      _splitTargetSessions.add(
        routine.exercises
            .map(
              (exercise) => SplitSession(
                type: exercise.type == '유산소' ? '유산소' : '운동',
                exercise: exercise.name,
                weight: exercise.type == '유산소' ? null : exercise.weight,
                sets: exercise.type == '유산소' ? 1 : exercise.sets,
                reps: exercise.type == '유산소' ? null : exercise.reps,
                restSeconds: 60,
                cardioSeconds: exercise.type == '유산소'
                    ? exercise.cardioSeconds
                    : 0,
              ),
            )
            .toList(),
      );
      _selectedSplitTargetIndex = 0;
    });
  }

  void _confirmDeleteRoutine(String routineId) {
    final routine = _workoutProvider.getRoutineById(routineId);
    if (routine == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('루틴 삭제'),
          content: Text('${routine.name} 루틴을 정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _workoutProvider.deleteRoutine(routineId);
                if (_selectedRoutineId == routineId) {
                  _selectedRoutineId = null;
                }
                Navigator.pop(dialogContext);
                setState(() {});
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _startTodayWorkout() {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    if (routine == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 루틴이 없습니다.')));
      return;
    }

    setState(() {
      _plannedWorkouts.putIfAbsent(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
        () => [],
      );
      _plannedWorkouts[DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          )]!
          .clear();
      for (final exercise in routine.exercises) {
        _plannedWorkouts[DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            )]!
            .add('${exercise.name} ${exercise.sets}세트 x ${exercise.reps}회');
      }
      _selectedDate = DateTime.now();
      _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
    });

    _showTopMessage('${routine.name} 루틴이 오늘 운동으로 설정되었습니다.');
  }

  void _setRoutineMode(String mode) {
    setState(() {
      _selectedRoutineMode = mode;
    });
  }

  void _toggleAutoSync(bool value) {
    setState(() {
      _autoSync = value;
    });
  }

  void _showWeekdayRoutineDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final weekdayList = ['월', '화', '수', '목', '금', '토', '일']
                .where((day) => !_weekendSkipped || !['토', '일'].contains(day))
                .toList();
            final red = Theme.of(context).colorScheme.primary;

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '요일별 운동 설정',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '주말 생략',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  Switch(
                    value: _weekendSkipped,
                    activeColor: Colors.white,
                    activeTrackColor: red,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (value) {
                      setDialogState(() => _weekendSkipped = value);
                      setState(() => _weekendSkipped = value);
                    },
                  ),
                ],
              ),
              contentTextStyle: const TextStyle(color: Colors.black87),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 540),
                child: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        ...weekdayList.map((day) {
                          final isDisabled =
                              _weekendSkipped && ['토', '일'].contains(day);
                          final routineId =
                              _workoutProvider.weekdayRoutineIds[day];
                          final hasSelection =
                              routineId != null && routineId.isNotEmpty;
                          return Opacity(
                            opacity: isDisabled ? 0.45 : 1.0,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? Colors.grey.shade200
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: hasSelection ? routineId : null,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                      iconEnabledColor: Colors.black54,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text(
                                            '선택 안 함',
                                            style: TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        ..._workoutProvider.routines
                                            .map(
                                              (routine) =>
                                                  DropdownMenuItem<String>(
                                                    value: routine.id,
                                                    child: Text(
                                                      routine.name,
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                      ],
                                      onChanged: isDisabled
                                          ? null
                                          : (value) {
                                              if (value == null) {
                                                _workoutProvider
                                                    .assignRoutineToWeekday(
                                                      day,
                                                      '',
                                                    );
                                              } else {
                                                _workoutProvider
                                                    .assignRoutineToWeekday(
                                                      day,
                                                      value,
                                                    );
                                              }
                                              setDialogState(() {});
                                              setState(() {});
                                            },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(132, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () {
                      if (_weekendSkipped) {
                        for (final day in ['토', '일']) {
                          _workoutProvider.assignRoutineToWeekday(day, '');
                        }
                      }
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('저장'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _changeRestSeconds(int delta) {
    setState(() {
      _restSeconds = (_restSeconds + delta).clamp(10, 180);
    });
  }

  bool _isTodayWorkoutComplete() {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    if (routine == null || routine.exercises.isEmpty) return false;
    return routine.exercises.every(
      (exercise) => _isExerciseCompleted(exercise.name),
    );
  }

  List<WorkoutRecord> _completedWorkoutRecords() {
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    if (routine == null) return const [];
    final now = DateTime.now();
    return routine.exercises
        .where((exercise) {
          if (_isExerciseCompleted(exercise.name)) return true;
          if (exercise.type == '유산소') {
            final remaining =
                _cardioRemainingSeconds[exercise.name] ?? exercise.cardioSeconds;
            return remaining < exercise.cardioSeconds;
          }
          final progress = _exerciseSetProgress[exercise.name];
          return progress?.any((value) => value != null) ?? false;
        })
        .map(
          (exercise) => WorkoutRecord(
            exercise: exercise.name,
            weight: exercise.weight,
            date: now,
          ),
        )
        .toList();
  }

  void _confirmFinishWorkout() {
    if (_isTodayWorkoutComplete()) {
      _finishWorkout();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            '운동 종료',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            '아직 끝내지 않은 운동이 있습니다. 그래도 종료하시겠습니까?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('아니요', style: TextStyle(color: Colors.black87)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _finishWorkout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _finishWorkout() async {
    _stopRestTimer();
    _cardioTimers.forEach((_, timer) => timer?.cancel());
    await _workoutProvider.saveCompletedWorkout(
      DateTime.now(),
      _completedWorkoutRecords(),
    );
    if (!mounted) return;
    setState(() {
      _isWorkoutMode = false;
      _isPlaying = false;
      _cardioRunning.updateAll((_, __) => false);
    });
  }

  void _confirmResetCompletedWorkout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            '완료한 루틴 초기화',
            style: TextStyle(color: Colors.black87),
          ),
          content: const Text(
            '완료한 루틴을 초기화하시겠습니까?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _workoutProvider.clearCompletedWorkout(_selectedDate);
                if (mounted) setState(() {});
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final entry in _setTouchTimers.values) {
      for (final timer in entry.values) {
        timer?.cancel();
      }
    }
    _routineTitleController.dispose();
    _weeklyWorkoutController.dispose();
    _planController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageTitles = ['운동', '캘린더', '그래프', '설정'];
    final pages = [
      Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._draftRoutineNames.asMap().entries.map((entry) {
                  final index = entry.key;
                  final name = entry.value;
                  final isSelected = _selectedDraftRoutineIndex == index;
                  return Container(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            _selectedDraftRoutineIndex = index;
                            _routineTitleController.text = name;
                            setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          splashRadius: 12,
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black54,
                          ),
                          onPressed: () => _removeDraftRoutineChip(index),
                        ),
                      ],
                    ),
                  );
                }),
                ..._workoutProvider.routines.map((routine) {
                  final isSelected = _selectedRoutineId == routine.id;
                  return Container(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _loadRoutine(routine.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            child: Text(
                              routine.name,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          splashRadius: 12,
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black54,
                          ),
                          onPressed: () => _confirmDeleteRoutine(routine.id),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(
                  width: 44,
                  height: 38,
                  child: RawMaterialButton(
                    fillColor: Colors.white,
                    shape: const StadiumBorder(),
                    onPressed: _createDraftRoutineChip,
                    child: const Icon(Icons.add, color: Colors.red, size: 20),
                  ),
                ),
              ],
            ),
          ),
          ExercisePage(
            routineTitleController: _routineTitleController,
            splitTargets: _splitTargets,
            selectedSplitTargetIndex: _selectedSplitTargetIndex,
            splitTargetSessions: _splitTargetSessions,
            exerciseNames: _exerciseNames,
            cardioExerciseNames: _cardioExerciseNames,
            onAddSplitTarget: _addSplitTarget,
            onSetSelectedSplitTarget: _setSelectedSplitTarget,
            onSetSplitTarget: _setSplitTarget,
            onAddSplitSession: _addSplitSession,
            onInsertSplitSession: _insertSplitSession,
            onMoveSplitSession: _moveSplitSession,
            onRemoveSplitSession: _removeSplitSession,
            onReorderSplitSessions: _reorderSplitSessions,
            onSetSplitSessionType: _setSplitSessionType,
            onSetSplitSessionExercise: _setSplitSessionExercise,
            onSetSplitSessionWeight: _setSplitSessionWeight,
            onSetSplitSessionSets: _setSplitSessionSets,
            onSetSplitSessionReps: _setSplitSessionReps,
            onSetSplitSessionRestSeconds: _setSplitSessionRestSeconds,
            onSetSplitSessionCardioSeconds: _setSplitSessionCardioSeconds,
            restSeconds: _restSeconds,
            onChangeRestSeconds: _changeRestSeconds,
            weeklyRoutine: _weeklyRoutine,
            selectedRoutineMode: _selectedRoutineMode,
            selectedWeekday: _selectedWeekday,
            weeklyWorkoutController: _weeklyWorkoutController,
            onSetRoutineMode: _setRoutineMode,
            onSetWeekday: _setWeekday,
            onAddWeeklyWorkout: _addWeeklyWorkout,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saveRoutine,
            icon: const Icon(Icons.save),
            label: const Text('루틴 저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
            ),
          ),
        ],
      ),
      CalendarPage(
        visibleMonth: _visibleMonth,
        selectedDate: _selectedDate,
        plansFor: _plansFor,
        onChangeMonth: _changeMonth,
        onSelectDate: _onSelectDate,
        todayRoutineSummary:
            _workoutProvider
                .getRoutineForDate(_selectedDate)
                ?.exercises
                .map((exercise) => exercise.name)
                .toList() ??
            const [],
        routineName: _workoutProvider.getRoutineForDate(_selectedDate)?.name,
        isCompleted: _workoutProvider.isWorkoutCompletedOn(_selectedDate),
        onResetCompletedWorkout: _confirmResetCompletedWorkout,
        onOpenWeekdaySettings: _showWeekdayRoutineDialog,
        hasRoutineForDate: _hasRoutineIndicatorForDate,
        isCompletedForDate: _workoutProvider.isWorkoutCompletedOn,
      ),
      ProgressPage(records: _workoutProvider.workoutRecords),
      SettingsPage(
        autoSync: _autoSync,
        restSeconds: _restSeconds,
        onToggleAutoSync: _toggleAutoSync,
        onChangeRestSeconds: _changeRestSeconds,
      ),
    ];

    final bottomBar = BottomAppBar(
      color: Colors.red.shade800,
      shape: const CircularNotchedRectangle(),
      notchMargin: 0,
      height: 64,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 64),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              icon: const Icon(Icons.fitness_center, size: 28),
              color: Colors.white,
              onPressed: () => _onNavTap(0),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 64),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              icon: const Icon(Icons.calendar_today, size: 28),
              color: Colors.white,
              onPressed: () => _onNavTap(1),
            ),
            const SizedBox(width: 40),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 64),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              icon: const Icon(Icons.show_chart, size: 28),
              color: Colors.white,
              onPressed: () => _onNavTap(2),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 64),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              icon: const Icon(Icons.settings, size: 28),
              color: Colors.white,
              onPressed: () => _onNavTap(3),
            ),
          ],
        ),
      ),
    );

    final playFab = SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: _isWorkoutMode
            ? _toggleWorkoutPlaying
            : (_exerciseSetProgress.isNotEmpty ||
                      _finalizedSetIndexes.isNotEmpty ||
                      _cardioRemainingSeconds.isNotEmpty
                  ? _toggleWorkoutPlaying
                  : _toggleWorkoutMode),
        backgroundColor: Colors.white,
        foregroundColor: Colors.red.shade700,
        elevation: 4,
        shape: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Icon(
              _isWorkoutMode && _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 28,
            ),
          ),
        ),
      ),
    );

    final statusOverlayStyle = _isWorkoutMode
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.red,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          );

    final todayWorkoutList = _todayWorkoutSummary();
    final todayRoutine = _workoutProvider.getRoutineForDate(DateTime.now());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusOverlayStyle,
      child: Scaffold(
        backgroundColor: _isWorkoutMode ? Colors.white : Colors.red.shade900,
        appBar: _isWorkoutMode
            ? null
            : AppBar(
                title: Text(pageTitles[_selectedIndex]),
                centerTitle: true,
                backgroundColor: Colors.red.shade800,
                elevation: 0,
              ),
        body: SafeArea(
          child: _isWorkoutMode
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: todayRoutine == null
                      ? const Text(
                          '오늘 설정된 루틴이 없습니다.',
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Text(
                              '오늘 운동',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...todayRoutine.exercises.asMap().entries.map((
                              entry,
                            ) {
                              final exerciseIndex = entry.key;
                              final exercise = entry.value;
                              final isExerciseLocked = !_isExerciseUnlocked(
                                exercise.name,
                              );

                              if (exercise.type == '유산소') {
                                final goalSeconds = exercise.cardioSeconds;
                                final remainingSeconds =
                                    _cardioRemainingSeconds[exercise.name] ??
                                    goalSeconds;
                                final isRunning =
                                    _cardioRunning[exercise.name] ?? false;

                                return Opacity(
                                  opacity: isExerciseLocked ? 0.45 : 1.0,
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 18),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '목표시간: ${_formatDuration(goalSeconds)}',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '남은시간: ${_formatDuration(remainingSeconds)}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isExerciseLocked
                                                    ? null
                                                    : () => _startCardioTimer(
                                                        exercise.name,
                                                      ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade600,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('start'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isExerciseLocked
                                                    ? null
                                                    : () => _pauseCardioTimer(
                                                        exercise.name,
                                                      ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  foregroundColor:
                                                      Colors.black87,
                                                ),
                                                child: const Text('rest'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final progress =
                                  _exerciseSetProgress[exercise.name] ??
                                  List<int>.filled(
                                    exercise.sets,
                                    exercise.reps,
                                    growable: false,
                                  );

                              return Opacity(
                                opacity: isExerciseLocked ? 0.45 : 1.0,
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              exercise.name,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${exercise.weight}kg',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 38,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: exercise.sets,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 8),
                                          itemBuilder: (context, index) {
                                            final value = progress[index];
                                            final isEmpty = value == null;
                                            final isBlocked =
                                                isExerciseLocked ||
                                                (index > 0 &&
                                                    !_isSetFinalized(
                                                      exercise.name,
                                                      index - 1,
                                                    ));
                                            final isFinalized = _isSetFinalized(
                                              exercise.name,
                                              index,
                                            );

                                            return GestureDetector(
                                              onTap: isBlocked
                                                  ? null
                                                  : () => _recordSetValue(
                                                      exercise.name,
                                                      index,
                                                    ),
                                              onLongPress: isExerciseLocked
                                                  ? null
                                                  : () => _resetSetValue(
                                                      exercise.name,
                                                      index,
                                                    ),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isBlocked
                                                        ? Colors.grey.shade300
                                                        : (isEmpty
                                                              ? Colors.black54
                                                              : (isFinalized
                                                                    ? Colors.red
                                                                    : Colors
                                                                          .black54)),
                                                    width: 1.5,
                                                  ),
                                                  color: isBlocked
                                                      ? Colors.grey.shade100
                                                      : (isFinalized
                                                            ? Colors.red
                                                            : Colors.white),
                                                ),
                                                child: isEmpty
                                                    ? const SizedBox()
                                                    : Center(
                                                        child: Text(
                                                          value.toString(),
                                                          style: TextStyle(
                                                            color: isFinalized
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _confirmFinishWorkout,
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('운동 종료'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (_isResting) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        '휴식',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$_restRemainingSeconds초',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(_stopRestTimer),
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 32,
                                            height: 32,
                                          ),
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      icon: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                      tooltip: '휴식 종료',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            ],
                          ),
                        ),
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: SingleChildScrollView(child: pages[_selectedIndex]),
                ),
        ),
        floatingActionButton: Padding(padding: EdgeInsets.zero, child: playFab),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: bottomBar,
      ),
    );
  }
}
