import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'exercise_catalog.dart';
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
  int _restElapsedSeconds = 0;
  int _restAlertStage = 0;
  Timer? _restTimer;
  Timer? _restAlarmTimer;
  int _restAlarmTicksRemaining = 0;
  OverlayEntry? _restTimerOverlayEntry;
  Timer? _messageTimer;
  OverlayEntry? _messageOverlayEntry;
  Timer? _sessionAutoScrollTimer;
  final ScrollController _routineEditorScrollController = ScrollController();
  final GlobalKey _routineEditorViewportKey = GlobalKey();
  final GlobalKey _sessionAddButtonKey = GlobalKey();
  final GlobalKey _sessionSectionKey = GlobalKey();
  bool _isReorderingSession = false;
  double? _sessionDragPointerY;
  ExerciseCatalog? _exerciseCatalog;
  String? _exerciseCatalogError;
  final Map<String, List<int?>> _exerciseSetProgress = {};
  final Map<String, double> _workoutWeights = {};
  DateTime? _workoutProgressDate;
  final Map<String, Map<int, Timer?>> _setTouchTimers = {};
  final Map<String, Set<int>> _finalizedSetIndexes = {};
  final Map<String, Timer?> _cardioTimers = {};
  final Map<String, int> _cardioRemainingSeconds = {};
  final Map<String, bool> _cardioRunning = {};
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
  bool _weekendSkipped = false;
  int _restSeconds = 60;
  List<int> _restAlertSeconds = [];
  String? _selectedRoutineId;

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExerciseCatalog();
    _loadWorkoutData();
  }

  List<ExerciseEntry> get _exerciseNames =>
      _exerciseCatalog?.strengthExercises ?? const [];
  List<ExerciseEntry> get _cardioExerciseNames =>
      _exerciseCatalog?.cardioExercises ?? const [];

  ExerciseEntry? _catalogExerciseForName(String name) {
    for (final exercise
        in _exerciseCatalog?.entries ?? const <ExerciseEntry>[]) {
      if (exercise.name.toLowerCase() == name.toLowerCase()) {
        return exercise;
      }
    }
    return null;
  }

  Widget _todayExerciseImage(String name) {
    final exercise = _catalogExerciseForName(name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 68,
        height: 68,
        child: exercise == null
            ? _todayExerciseImageFallback()
            : Image.asset(
                exercise.imageAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _todayExerciseImageFallback(),
              ),
      ),
    );
  }

  Widget _todayExerciseImageFallback() {
    return Container(
      color: Colors.red.shade50,
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center, color: Colors.red.shade300, size: 28),
    );
  }

  Future<void> _loadExerciseCatalog() async {
    try {
      final source = await _loadExerciseJson();
      final catalog = ExerciseCatalog.fromJson(source);
      if (mounted) {
        setState(() => _exerciseCatalog = catalog);
      }
    } on FormatException {
      if (!mounted) return;
      setState(() => _exerciseCatalogError = '운동 데이터 파일 형식이 올바르지 않습니다.');
      _showTopMessage('운동 데이터 파일을 읽지 못했습니다.');
    } on FlutterError {
      if (!mounted) return;
      setState(() => _exerciseCatalogError = '운동 데이터 파일을 찾을 수 없습니다.');
      _showTopMessage('운동 데이터 파일을 찾을 수 없습니다.');
    }
  }

  Future<String> _loadExerciseJson() async {
    try {
      return await rootBundle.loadString('data/exercises.json');
    } on FlutterError {
      return rootBundle.loadString('exercises.json');
    }
  }

  Future<void> _loadWorkoutData() async {
    await _workoutProvider.ready;
    if (!mounted) return;
    final settings = _workoutProvider.restTimerSettings;
    setState(() {
      _restSeconds = settings.initialSeconds;
      _restAlertSeconds = List.of(settings.alertSeconds);
      _restElapsedSeconds = 0;
    });
  }

  void _onNavTap(int index) {
    if (_isWorkoutMode) {
      _stopRestTimer(reset: false);
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
    final today = DateTime.now();
    final progressIsForToday =
        _workoutProgressDate?.year == today.year &&
        _workoutProgressDate?.month == today.month &&
        _workoutProgressDate?.day == today.day;
    final workoutIsCompletedToday = _workoutProvider.isWorkoutCompletedOn(
      today,
    );

    setState(() {
      if (!_isWorkoutMode &&
          hasExistingProgress &&
          progressIsForToday &&
          !workoutIsCompletedToday) {
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
    _syncRestTimerOverlay();
  }

  void _toggleWorkoutPlaying() {
    if (!_isWorkoutMode) {
      setState(() {
        _isWorkoutMode = true;
        _isPlaying = true;
      });
      if (_isResting) {
        _startRestTimer(reset: false);
      }
      return;
    }

    if (_isPlaying) {
      _stopRestTimer(reset: false);
      _cardioTimers.forEach((_, timer) => timer?.cancel());
      setState(() {
        _isPlaying = false;
        _isWorkoutMode = false;
        _cardioRunning.updateAll((_, __) => false);
      });
      _syncRestTimerOverlay();
      return;
    }

    setState(() {
      _isWorkoutMode = true;
      _isPlaying = true;
    });
    _syncRestTimerOverlay();

    if (_isResting) {
      _startRestTimer(reset: false);
    }

    for (final entry in _cardioRemainingSeconds.entries) {
      if (entry.value > 0) {
        _startCardioTimer(entry.key);
      }
    }
  }

  void _initializeWorkoutProgress() {
    final now = DateTime.now();
    _workoutProgressDate = now;
    final routine = _workoutProvider.getRoutineForDate(now);
    _exerciseSetProgress.clear();
    _workoutWeights.clear();
    _finalizedSetIndexes.clear();
    _cardioTimers.forEach((key, timer) => timer?.cancel());
    _cardioTimers.clear();
    _cardioRemainingSeconds.clear();
    _cardioRunning.clear();
    _isResting = false;
    _restElapsedSeconds = 0;
    _restAlertStage = 0;
    _restTimer?.cancel();
    _stopRestAlarm();
    _removeRestTimerOverlay();
    if (routine == null) return;

    for (final exercise in routine.exercises) {
      _exerciseSetProgress[exercise.name] = List<int?>.filled(
        exercise.sets,
        null,
        growable: false,
      );
      _workoutWeights[exercise.name] = _workoutProvider.nextWorkoutWeight(
        exercise.name,
        exercise.weight.toDouble(),
        now,
      );
      if (exercise.type == '유산소') {
        _cardioRemainingSeconds[exercise.name] = exercise.cardioSeconds;
        _cardioRunning[exercise.name] = false;
      }
    }

  }

  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  RestTimerSettings get _activeRestTimerSettings => RestTimerSettings(
    initialSeconds: _restSeconds,
    alertSeconds: _restAlertSeconds,
  );

  List<int> get _restThresholds => _activeRestTimerSettings.thresholds;
  int get _restAlertThresholdCount => _restThresholds.length;

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

    return exercise.hasCompletedAllSets(
      progress,
      _finalizedSetIndexes[exerciseName] ?? const <int>{},
    );
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

  void _startRestTimer({bool reset = true}) {
    _restTimer?.cancel();
    _stopRestAlarm();
    _isResting = true;
    if (reset) {
      _restElapsedSeconds = 0;
      _restAlertStage = 0;
    }
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _restElapsedSeconds += 1;
        final reachedStage = _activeRestTimerSettings.alertStageAt(
          _restElapsedSeconds,
        );
        while (_restAlertStage < reachedStage) {
          _restAlertStage++;
          _playRestAlarm();
        }
      });
      _restTimerOverlayEntry?.markNeedsBuild();
      _messageOverlayEntry?.markNeedsBuild();
    });
    _syncRestTimerOverlay();
  }

  void _stopRestTimer({bool reset = true}) {
    _restTimer?.cancel();
    _restTimer = null;
    _stopRestAlarm();
    if (reset) {
      _isResting = false;
      _restElapsedSeconds = 0;
      _restAlertStage = 0;
      _removeRestTimerOverlay();
      _messageOverlayEntry?.markNeedsBuild();
    }
  }

  void _syncRestTimerOverlay() {
    if (!mounted || !_isWorkoutMode || !_isResting) {
      _removeRestTimerOverlay();
      _messageOverlayEntry?.markNeedsBuild();
      return;
    }
    if (_restTimerOverlayEntry == null) {
      _restTimerOverlayEntry = OverlayEntry(
        builder: _buildRestTimerNotification,
      );
      Overlay.of(context, rootOverlay: true).insert(_restTimerOverlayEntry!);
    } else {
      _restTimerOverlayEntry!.markNeedsBuild();
    }
    _messageOverlayEntry?.markNeedsBuild();
  }

  Widget _buildRestTimerNotification(BuildContext overlayContext) {
    final topInset = MediaQuery.paddingOf(overlayContext).top;
    final progress = _restAlertThresholdCount == 0
        ? 0.0
        : (_restAlertStage / _restAlertThresholdCount)
              .clamp(0.0, 1.0)
              .toDouble();
    final backgroundColor = Color.lerp(
      Colors.red.shade700,
      Colors.red.shade900,
      progress,
    )!;
    return Positioned(
      top: topInset + 8,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '휴식',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_restAlertStage > 0)
                      Text(
                        '알림 $_restAlertStage / $_restAlertThresholdCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _formatDuration(_restElapsedSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => setState(_stopRestTimer),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                icon: const Icon(Icons.close, size: 20, color: Colors.white),
                tooltip: '휴식 종료',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeRestTimerOverlay() {
    _restTimerOverlayEntry?.remove();
    _restTimerOverlayEntry?.dispose();
    _restTimerOverlayEntry = null;
  }

  void _playRestAlarm() {
    _restAlarmTimer?.cancel();
    _restAlarmTicksRemaining = 5;
    void playAlert() {
      unawaited(SystemSound.play(SystemSoundType.alert));
      unawaited(HapticFeedback.lightImpact());
      _restAlarmTicksRemaining--;
    }

    playAlert();
    _restAlarmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restAlarmTicksRemaining <= 0) {
        timer.cancel();
        _restAlarmTimer = null;
        return;
      }
      playAlert();
      if (_restAlarmTicksRemaining <= 0) {
        timer.cancel();
        _restAlarmTimer = null;
      }
    });
  }

  void _stopRestAlarm() {
    _restAlarmTimer?.cancel();
    _restAlarmTimer = null;
    _restAlarmTicksRemaining = 0;
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
    _messageTimer?.cancel();
    _removeTopMessage();
    final overlay = Overlay.of(context, rootOverlay: true);
    _messageOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final topInset =
            MediaQuery.paddingOf(overlayContext).top +
            (_isWorkoutMode && _isResting ? 84 : 0);
        return Positioned(
          top: topInset + 8,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _hideTopMessage,
                    tooltip: '닫기',
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_messageOverlayEntry!);
    _messageTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _hideTopMessage();
    });
  }

  void _hideTopMessage() {
    _messageTimer?.cancel();
    _messageTimer = null;
    _removeTopMessage();
  }

  void _removeTopMessage() {
    _messageOverlayEntry?.remove();
    _messageOverlayEntry?.dispose();
    _messageOverlayEntry = null;
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
      _splitTargets.add(
        _splitTargets.length == 1 ? '하체' : '분할 ${_splitTargets.length + 1}',
      );
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

  void _startSessionReorder(int index) {
    _isReorderingSession = true;
    _sessionAutoScrollTimer?.cancel();
    _sessionAutoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScrollRoutineEditor(),
    );
  }

  void _endSessionReorder(int index) {
    _isReorderingSession = false;
    _sessionDragPointerY = null;
    _sessionAutoScrollTimer?.cancel();
    _sessionAutoScrollTimer = null;
  }

  void _updateSessionDragPointer(PointerMoveEvent event) {
    if (_isReorderingSession) {
      _sessionDragPointerY = event.position.dy;
    }
  }

  void _autoScrollRoutineEditor() {
    if (!_isReorderingSession ||
        !_routineEditorScrollController.hasClients ||
        _sessionDragPointerY == null) {
      return;
    }

    final renderObject = _routineEditorViewportKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final viewportTop = renderObject.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + renderObject.size.height;
    final pointerY = _sessionDragPointerY!;
    const edgeSize = 72.0;
    const scrollStep = 10.0;
    const playButtonClearance = 36.0;

    final position = _routineEditorScrollController.position;
    if (pointerY > viewportBottom - edgeSize &&
        position.pixels < position.maxScrollExtent) {
      final addButtonRenderObject = _sessionAddButtonKey.currentContext
          ?.findRenderObject();
      if (addButtonRenderObject is! RenderBox ||
          !addButtonRenderObject.hasSize) {
        return;
      }
      final addButtonTop = addButtonRenderObject.localToGlobal(Offset.zero).dy;
      final remainingUntilAddButton =
          addButtonTop - (viewportBottom - playButtonClearance);
      if (remainingUntilAddButton <= 0) return;
      _routineEditorScrollController.jumpTo(
        (position.pixels + scrollStep.clamp(0.0, remainingUntilAddButton))
            .clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    } else if (pointerY < viewportTop + edgeSize &&
        position.pixels > position.minScrollExtent) {
      _routineEditorScrollController.jumpTo(
        (position.pixels - scrollStep).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    }
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

  void _setSplitSessionWeight(
    int targetIndex,
    int sessionIndex,
    double? weight,
  ) {
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

  List<RoutineExercise>? _routineExercisesFromEditor() {
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
    return exercises.isEmpty ? null : exercises;
  }

  bool _hasInvalidSetOrRepCount() {
    return _splitTargetSessions[_selectedSplitTargetIndex].any((session) {
      if (session.type != '운동' ||
          session.exercise == null ||
          session.exercise!.isEmpty) {
        return false;
      }
      final sets = session.sets;
      final reps = session.reps;
      return sets == null ||
          sets < 1 ||
          sets > 50 ||
          reps == null ||
          reps < 1 ||
          reps > 50;
    });
  }

  Future<void> _saveRoutine() async {
    final title = _routineTitleController.text.trim();
    if (title.isEmpty) return;

    if (_hasInvalidSetOrRepCount()) {
      _showTopMessage('세트와 반복 횟수는 1~50 사이의 정수로 입력해 주세요.');
      return;
    }

    final isEditing = _selectedRoutineId != null;
    final exercises = _routineExercisesFromEditor();

    if (exercises == null) {
      _showTopMessage('저장할 운동이 없습니다.');
      return;
    }

    final routine = WorkoutRoutine(
      id: _selectedRoutineId ?? _uuid.v4(),
      name: title,
      exercises: exercises,
    );
    await _workoutProvider.saveRoutine(routine);
    if (!isEditing) {
      await _workoutProvider.assignRoutineToWeekday(
        _selectedWeekday,
        routine.id,
      );
    }
    _selectedRoutineId = routine.id;

    if (_selectedDraftRoutineIndex != null &&
        _selectedDraftRoutineIndex! < _draftRoutineNames.length) {
      _draftRoutineNames.removeAt(_selectedDraftRoutineIndex!);
      _selectedDraftRoutineIndex = null;
    }

    _showTopMessage('$title 루틴이 ${isEditing ? '수정' : '저장'}되었습니다.');
    setState(() {});
  }

  Future<void> _duplicateSelectedRoutine() async {
    if (_hasInvalidSetOrRepCount()) {
      _showTopMessage('세트와 반복 횟수는 1~50 사이의 정수로 입력해 주세요.');
      return;
    }

    final routine = _workoutProvider.getRoutineById(_selectedRoutineId ?? '');
    final exercises = _routineExercisesFromEditor();
    if (routine == null || exercises == null) return;

    final copy = WorkoutRoutine(
      id: _uuid.v4(),
      name: '${routine.name} (copy)',
      exercises: exercises,
    );
    await _workoutProvider.saveRoutine(copy);
    await _workoutProvider.assignRoutineToWeekday(_selectedWeekday, copy.id);
    _selectedRoutineId = copy.id;
    _routineTitleController.text = copy.name;
    _showTopMessage('${copy.name} 루틴이 복제되었습니다.');
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('루틴 삭제', style: TextStyle(color: Colors.black87)),
          content: Text(
            '${routine.name} 루틴을 정말 삭제하시겠습니까?',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
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
      _showTopMessage('오늘의 루틴이 없습니다.');
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

  Future<void> _toggleExerciseProgression(String exercise, bool enabled) async {
    await _workoutProvider.setExerciseProgressionEnabled(exercise, enabled);
    if (mounted) setState(() {});
  }

  Future<void> _changeExerciseProgressionAmount(
    String exercise,
    double incrementKg,
  ) async {
    await _workoutProvider.setExerciseProgressionAmount(exercise, incrementKg);
    if (mounted) setState(() {});
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

  Future<void> _changeRestTimerSettings(RestTimerSettings settings) async {
    setState(() {
      _restSeconds = settings.initialSeconds;
      _restAlertSeconds = List.of(settings.alertSeconds);
      if (_isResting) {
        _restAlertStage = _activeRestTimerSettings.alertStageAt(
          _restElapsedSeconds,
        );
      }
    });
    await _workoutProvider.setRestTimerSettings(settings);
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
                _cardioRemainingSeconds[exercise.name] ??
                exercise.cardioSeconds;
            return remaining < exercise.cardioSeconds;
          }
          final progress = _exerciseSetProgress[exercise.name];
          return progress?.any((value) => value != null) ?? false;
        })
        .map(
          (exercise) => WorkoutRecord(
            exercise: exercise.name,
            weight: _workoutWeights[exercise.name] ?? exercise.weight,
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
    final routine = _workoutProvider.getRoutineForDate(DateTime.now());
    if (routine != null) {
      final updatedWeights = <String, double>{};
      for (final exercise in routine.exercises) {
        final progress = _exerciseSetProgress[exercise.name];
        final finalized = _finalizedSetIndexes[exercise.name] ?? const <int>{};
        final appliedWeight = _workoutWeights[exercise.name];
        if (progress != null && appliedWeight != null) {
          final completedWeight = exercise.completedProgressionWeight(
            progressionEnabled: _workoutProvider
                .progressionForExercise(exercise.name)
                .enabled,
            repetitionsBySet: progress,
            finalizedSetIndexes: finalized,
            appliedWeight: appliedWeight,
          );
          if (completedWeight != null) {
            updatedWeights[exercise.name] = completedWeight;
          }
        }
      }
      if (updatedWeights.isNotEmpty) {
        await _workoutProvider.updateRoutineExerciseWeights(
          routine.id,
          updatedWeights,
        );
        if (_selectedRoutineId == routine.id) {
          for (final sessions in _splitTargetSessions) {
            for (final session in sessions) {
              final updatedWeight = updatedWeights[session.exercise];
              if (updatedWeight != null) session.weight = updatedWeight;
            }
          }
        }
      }
    }
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
    _stopRestAlarm();
    _messageTimer?.cancel();
    _removeTopMessage();
    _removeRestTimerOverlay();
    _sessionAutoScrollTimer?.cancel();
    _routineEditorScrollController.dispose();
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
    final routineMenuBar = Align(
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
    );
    final exerciseEditor = Column(
      children: [
        Material(color: Colors.transparent, child: routineMenuBar),
        const SizedBox(height: 16),
        ExercisePage(
          routineTitleController: _routineTitleController,
          splitTargets: _splitTargets,
          selectedSplitTargetIndex: _selectedSplitTargetIndex,
          splitTargetSessions: _splitTargetSessions,
          exerciseNames: _exerciseNames,
          cardioExerciseNames: _cardioExerciseNames,
          exerciseDataLoading:
              _exerciseCatalog == null && _exerciseCatalogError == null,
          exerciseDataError: _exerciseCatalogError,
          onAddSplitTarget: _addSplitTarget,
          onSetSelectedSplitTarget: _setSelectedSplitTarget,
          onSetSplitTarget: _setSplitTarget,
          onAddSplitSession: _addSplitSession,
          onInsertSplitSession: _insertSplitSession,
          onMoveSplitSession: _moveSplitSession,
          onRemoveSplitSession: _removeSplitSession,
          onReorderSplitSessions: _reorderSplitSessions,
          onSessionReorderStart: _startSessionReorder,
          onSessionReorderEnd: _endSessionReorder,
          sessionAddButtonKey: _sessionAddButtonKey,
          dragViewportKey: _routineEditorViewportKey,
          sessionSectionKey: _sessionSectionKey,
          onSetSplitSessionType: _setSplitSessionType,
          onSetSplitSessionExercise: _setSplitSessionExercise,
          onSetSplitSessionWeight: _setSplitSessionWeight,
          onSetSplitSessionSets: _setSplitSessionSets,
          onSetSplitSessionReps: _setSplitSessionReps,
          onSetSplitSessionCardioSeconds: _setSplitSessionCardioSeconds,
          weeklyRoutine: _weeklyRoutine,
          selectedRoutineMode: _selectedRoutineMode,
          selectedWeekday: _selectedWeekday,
          weeklyWorkoutController: _weeklyWorkoutController,
          onSetRoutineMode: _setRoutineMode,
          onSetWeekday: _setWeekday,
          onAddWeeklyWorkout: _addWeeklyWorkout,
        ),
        const SizedBox(height: 16),
        if (_selectedRoutineId == null)
          ElevatedButton.icon(
            onPressed: _saveRoutine,
            icon: const Icon(Icons.save),
            label: const Text('저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _saveRoutine,
                icon: const Icon(Icons.edit),
                label: const Text('수정'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _duplicateSelectedRoutine,
                icon: const Icon(Icons.copy),
                label: const Text('복제'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
            ],
          ),
      ],
    );
    final pages = [
      exerciseEditor,
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
      ProgressPage(
        records: _workoutProvider.workoutRecords,
        exerciseProgressions: _workoutProvider.exerciseProgressions,
        onToggleProgression: _toggleExerciseProgression,
        onChangeProgressionAmount: _changeExerciseProgressionAmount,
      ),
      SettingsPage(
        restTimerSettings: _workoutProvider.restTimerSettings.copyWith(
          initialSeconds: _restSeconds,
          alertSeconds: List.unmodifiable(_restAlertSeconds),
        ),
        onChangeRestTimerSettings: _changeRestTimerSettings,
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
      width: 64,
      height: 64,
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isWorkoutMode
              ? _toggleWorkoutPlaying
              : (_exerciseSetProgress.isNotEmpty ||
                        _finalizedSetIndexes.isNotEmpty ||
                        _cardioRemainingSeconds.isNotEmpty
                    ? _toggleWorkoutPlaying
                    : _toggleWorkoutMode),
          child: Center(
            child: Icon(
              _isWorkoutMode && _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.red.shade700,
              size: 36,
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
        resizeToAvoidBottomInset: false,
        appBar: _isWorkoutMode
            ? null
            : AppBar(
                title: Text(pageTitles[_selectedIndex]),
                centerTitle: true,
                backgroundColor: Colors.red.shade800,
                elevation: 0,
              ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            child: _isWorkoutMode
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: todayRoutine == null
                        ? const Text(
                            '오늘 설정된 루틴이 없습니다.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
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
                                        _cardioRemainingSeconds[exercise
                                            .name] ??
                                        goalSeconds;
                                    final isRunning =
                                        _cardioRunning[exercise.name] ?? false;

                                    return Opacity(
                                      opacity: isExerciseLocked ? 0.45 : 1.0,
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 18,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                                _todayExerciseImage(
                                                  exercise.name,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    exercise.name,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                                        : () =>
                                                              _startCardioTimer(
                                                                exercise.name,
                                                              ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .red
                                                                  .shade600,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text('start'),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: isExerciseLocked
                                                        ? null
                                                        : () =>
                                                              _pauseCardioTimer(
                                                                exercise.name,
                                                              ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .grey
                                                                  .shade200,
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
                                              _todayExerciseImage(
                                                exercise.name,
                                              ),
                                              const SizedBox(width: 12),
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
                                                '${formatWeight(_workoutWeights[exercise.name] ?? exercise.weight.toDouble())}kg',
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
                                                final isFinalized =
                                                    _isSetFinalized(
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
                                                            ? Colors
                                                                  .grey
                                                                  .shade300
                                                            : (isEmpty
                                                                  ? Colors
                                                                        .black54
                                                                  : (isFinalized
                                                                        ? Colors
                                                                              .red
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
                                                                color:
                                                                    isFinalized
                                                                    ? Colors
                                                                          .white
                                                                    : Colors
                                                                          .black87,
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
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
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: const Text('운동 종료'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: DragBoundary(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerMove: _updateSessionDragPointer,
                        child: SingleChildScrollView(
                          key: _selectedIndex == 0
                              ? _routineEditorViewportKey
                              : null,
                          controller: _selectedIndex == 0
                              ? _routineEditorScrollController
                              : null,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: _selectedIndex == 0 ? 128 : 0,
                            ),
                            child: pages[_selectedIndex],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        floatingActionButton: playFab,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: bottomBar,
      ),
    );
  }
}
