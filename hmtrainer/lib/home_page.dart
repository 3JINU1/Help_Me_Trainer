import 'package:flutter/material.dart';
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
  final TextEditingController _weeklyWorkoutController = TextEditingController();
  final TextEditingController _planController = TextEditingController();
  final List<WorkoutRecord> _records = [
    WorkoutRecord(exercise: 'Squat', weight: 120, date: DateTime.now().subtract(const Duration(days: 14))),
    WorkoutRecord(exercise: 'Squat', weight: 125, date: DateTime.now().subtract(const Duration(days: 7))),
    WorkoutRecord(exercise: 'Squat', weight: 130, date: DateTime.now()),
    WorkoutRecord(exercise: 'Bench Press', weight: 85, date: DateTime.now().subtract(const Duration(days: 14))),
    WorkoutRecord(exercise: 'Bench Press', weight: 90, date: DateTime.now().subtract(const Duration(days: 7))),
    WorkoutRecord(exercise: 'Bench Press', weight: 92, date: DateTime.now()),
  ];
  final Map<DateTime, List<String>> _plannedWorkouts = {};
  final WorkoutProvider _workoutProvider = WorkoutProvider();
  final Uuid _uuid = const Uuid();
  final List<String> _splitTargets = ['상체'];
  int _selectedSplitTargetIndex = 0;
  final List<List<SplitSession>> _splitTargetSessions = [
    [],
  ];
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

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addPlan() {
    final text = _planController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final key = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
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
    final hasAssignedRoutine = (_workoutProvider.weekdayRoutineIds[weekday] ?? '').isNotEmpty;
    return hasAssignedRoutine || _plansFor(date).isNotEmpty;
  }

  void _showTopMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      _splitTargetSessions[targetIndex].insert(sessionIndex + 1, SplitSession(type: '운동'));
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
      final sessions = List<SplitSession>.from(_splitTargetSessions[targetIndex]);
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

  void _setSplitSessionExercise(int targetIndex, int sessionIndex, String? exercise) {
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

  void _setSplitSessionRestSeconds(int targetIndex, int sessionIndex, int restSeconds) {
    setState(() {
      _splitTargetSessions[targetIndex][sessionIndex].restSeconds = restSeconds;
    });
  }

  void _setSplitSessionCardioSeconds(int targetIndex, int sessionIndex, int seconds) {
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

  void _createDraftRoutineChip() {
    final draftName = '루틴 ${_draftRoutineNames.length + 1}';
    _draftRoutineNames.add(draftName);
    _selectedDraftRoutineIndex = _draftRoutineNames.length - 1;
    _routineTitleController.text = draftName;
    setState(() {});
  }

  void _removeDraftRoutineChip(int index) {
    _draftRoutineNames.removeAt(index);
    if (_selectedDraftRoutineIndex == index) {
      _selectedDraftRoutineIndex = null;
    } else if (_selectedDraftRoutineIndex != null && _selectedDraftRoutineIndex! > index) {
      _selectedDraftRoutineIndex = _selectedDraftRoutineIndex! - 1;
    }
    setState(() {});
  }

  void _saveRoutine() {
    final title = _routineTitleController.text.trim();
    if (title.isEmpty) return;

    final exercises = <RoutineExercise>[];
    for (final session in _splitTargetSessions[_selectedSplitTargetIndex]) {
      if (session.type == '운동' && session.exercise != null) {
        exercises.add(
          RoutineExercise(
            name: session.exercise!,
            sets: session.sets ?? 0,
            reps: session.reps ?? 0,
          ),
        );
      }
    }

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장할 운동이 없습니다.')));
      return;
    }

    final routine = WorkoutRoutine(
      id: _uuid.v4(),
      name: title,
      exercises: exercises,
    );
    _workoutProvider.saveRoutine(routine);
    _workoutProvider.assignRoutineToWeekday(_selectedWeekday, routine.id);
    _workoutProvider.assignRoutineToDate(_selectedDate, routine.id);
    _selectedRoutineId = routine.id;

    if (_selectedDraftRoutineIndex != null && _selectedDraftRoutineIndex! < _draftRoutineNames.length) {
      _draftRoutineNames.removeAt(_selectedDraftRoutineIndex!);
      _selectedDraftRoutineIndex = null;
    }

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
                type: '운동',
                exercise: exercise.name,
                sets: exercise.sets,
                reps: exercise.reps,
                restSeconds: 60,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오늘의 루틴이 없습니다.')));
      return;
    }

    setState(() {
      _plannedWorkouts.putIfAbsent(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), () => []);
      _plannedWorkouts[DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)]!.clear();
      for (final exercise in routine.exercises) {
        _plannedWorkouts[DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)]!.add('${exercise.name} ${exercise.sets}세트 x ${exercise.reps}회');
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
            final weekdayList = ['월', '화', '수', '목', '금', '토', '일'].where((day) => !_weekendSkipped || !['토', '일'].contains(day)).toList();
            final red = Theme.of(context).colorScheme.primary;

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '요일별 운동 설정',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('주말 생략', style: TextStyle(fontSize: 12, color: Colors.black87)),
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
                          final isDisabled = _weekendSkipped && ['토', '일'].contains(day);
                          final routineId = _workoutProvider.weekdayRoutineIds[day];
                          final hasSelection = routineId != null && routineId.isNotEmpty;
                          return Opacity(
                            opacity: isDisabled ? 0.45 : 1.0,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDisabled ? Colors.grey.shade200 : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: hasSelection ? routineId : null,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: Colors.black87),
                                      iconEnabledColor: Colors.black54,
                                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                                      items: [
                                        const DropdownMenuItem<String>(value: null, child: Text('선택 안 함', style: TextStyle(color: Colors.black87))),
                                        ..._workoutProvider.routines.map((routine) => DropdownMenuItem<String>(value: routine.id, child: Text(routine.name, style: const TextStyle(color: Colors.black87)))).toList(),
                                      ],
                                      onChanged: isDisabled
                                          ? null
                                          : (value) {
                                              if (value == null) {
                                                _workoutProvider.assignRoutineToWeekday(day, '');
                                              } else {
                                                _workoutProvider.assignRoutineToWeekday(day, value);
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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

  @override
  void dispose() {
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
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                            child: Text(name, style: const TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          splashRadius: 12,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16, color: Colors.black54),
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
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                            child: Text(routine.name, style: const TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          splashRadius: 12,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16, color: Colors.black54),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
          ),
        ],
      ),
      CalendarPage(
        visibleMonth: _visibleMonth,
        selectedDate: _selectedDate,
        plansFor: _plansFor,
        onChangeMonth: _changeMonth,
        onSelectDate: _onSelectDate,
        todayRoutineSummary: _workoutProvider
                .getRoutineForDate(_selectedDate)
                ?.exercises
                .map((exercise) => exercise.name)
                .toList() ??
            const [],
        onOpenWeekdaySettings: _showWeekdayRoutineDialog,
        hasRoutineForDate: _hasRoutineIndicatorForDate,
      ),
      ProgressPage(records: _records),
      SettingsPage(
        autoSync: _autoSync,
        restSeconds: _restSeconds,
        onToggleAutoSync: _toggleAutoSync,
        onChangeRestSeconds: _changeRestSeconds,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: Colors.red.shade800,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: SingleChildScrollView(child: pages[_selectedIndex]),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            onPressed: _startTodayWorkout,
            backgroundColor: Colors.white,
            foregroundColor: Colors.red.shade700,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.play_arrow, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.red.shade800,
        shape: const CircularNotchedRectangle(),
        notchMargin: 0,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                icon: const Icon(Icons.fitness_center, size: 20),
                color: _selectedIndex == 0 ? Colors.white : Colors.white70,
                onPressed: () => _onNavTap(0),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                icon: const Icon(Icons.calendar_today, size: 20),
                color: _selectedIndex == 1 ? Colors.white : Colors.white70,
                onPressed: () => _onNavTap(1),
              ),
              const SizedBox(width: 40),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                icon: const Icon(Icons.show_chart, size: 20),
                color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                onPressed: () => _onNavTap(2),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                icon: const Icon(Icons.settings, size: 20),
                color: _selectedIndex == 3 ? Colors.white : Colors.white70,
                onPressed: () => _onNavTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
