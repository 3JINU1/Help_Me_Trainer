import 'package:flutter/material.dart';

import 'models.dart';
import 'pages/calendar_page.dart';
import 'pages/exercise_page.dart';
import 'pages/progress_page.dart';
import 'pages/settings_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<String> _exerciseNames = [
    '플랫 벤치프레스 (바벨 / 덤벨)',
    '인클라인 덤벨 프레스',
    '체스트 프레스 머신',
    '인클라인 체스트 프레스 머신',
    '풀업 (맨몸 턱걸이)',
    '렛풀다운',
    '바벨 로우',
    '어시스트 풀업 머신',
    '시티드 케이블 로우',
    '티바 로우 (T-Bar Row)',
    '시티드 덤벨 숄더 프레스 (메인)',
    '스미스 머신 숄더 프레스 (대체)',
    '숄더 프레스 머신 (대체)',
    '사이드 레터럴 레이즈 (메인)',
    '인클라인 덤벨 레터럴 레이즈 (메인)',
    '케이블 측면 레이즈 (대체)',
    '머신 레터럴 레이즈 (대체)',
    '페이스 풀 (케이블) (메인)',
    '리어델트 플라이 (머신) (메인)',
    '덤벨 벤트오버 레이즈 (대체)',
    '스티프 레그 데드리프트 (바벨 / 덤벨)',
    '라잉 레그 컬 (머신)',
    '시티드 레그 컬 (머신)',
    '바벨 글루트 브릿지',
    '맨몸 스쿼트',
    '고블릿 스쿼트 (덤벨)',
    '레그 익스텐션 (머신)',
    '박스 스쿼트 (대체)',
    '리버스 런지 (대체 - 뒤로 딛는 런지)',
    '카프 레이즈',
    '라잉 트라이셉스 익스텐션',
    '케이블 푸쉬다운',
    '바벨 컬',
    '덤벨 해머 컬',
    '행잉 레그 레이즈',
    '크런치',
    '실내 싸이클 (안장 높게 세팅)',
    '인클라인 러닝머신 (마이마운틴 / 경사도 걷기)',
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
  String _selectedRoutineMode = '분할';
  String _selectedWeekday = '월';
  bool _autoSync = true;
  int _restSeconds = 60;

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
        SplitSession(type: '스트레칭'),
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
      _splitTargetSessions[targetIndex].insert(sessionIndex + 1, SplitSession(type: '스트레칭'));
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
      ExercisePage(
        routineTitleController: _routineTitleController,
        splitTargets: _splitTargets,
        selectedSplitTargetIndex: _selectedSplitTargetIndex,
        splitTargetSessions: _splitTargetSessions,
        exerciseNames: _exerciseNames,
        onAddSplitTarget: _addSplitTarget,
        onSetSelectedSplitTarget: _setSelectedSplitTarget,
        onSetSplitTarget: _setSplitTarget,
        onAddSplitSession: _addSplitSession,
        onInsertSplitSession: _insertSplitSession,
        onMoveSplitSession: _moveSplitSession,
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
      CalendarPage(
        visibleMonth: _visibleMonth,
        selectedDate: _selectedDate,
        plansFor: _plansFor,
        planController: _planController,
        onChangeMonth: _changeMonth,
        onSelectDate: _onSelectDate,
        onAddPlan: _addPlan,
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
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: pages[_selectedIndex]),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.red.shade800,
        type: BottomNavigationBarType.fixed,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: '운동'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: '그래프'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
