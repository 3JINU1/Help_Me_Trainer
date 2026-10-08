// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hmtrainer/main.dart';
import 'package:hmtrainer/models.dart';
import 'package:hmtrainer/pages/progress_page.dart';
import 'package:hmtrainer/pages/settings_page.dart';
import 'package:hmtrainer/pages/workout_provider.dart';
import 'package:hmtrainer/widgets/cardio_duration_picker.dart';
import 'package:hmtrainer/widgets/performance_chart.dart';

void main() {
  testWidgets('앱이 오늘 화면을 표시한다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('운동'), findsOneWidget);
  });

  testWidgets('그래프 표시 여부와 전체 운동 선택 체크박스를 제어한다', (WidgetTester tester) async {
    final records = [
      WorkoutRecord(exercise: '스쿼트', weight: 100, date: DateTime(2024, 1, 1)),
      WorkoutRecord(exercise: '스쿼트', weight: 110, date: DateTime(2024, 1, 3)),
      WorkoutRecord(exercise: '벤치프레스', weight: 60, date: DateTime(2024, 1, 2)),
      WorkoutRecord(exercise: '벤치프레스', weight: 70, date: DateTime(2024, 1, 4)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressPage(
            records: records,
            exerciseProgressions: const {},
            onToggleProgression: (_, _) async {},
            onChangeProgressionAmount: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('show_progress_chart_checkbox')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('toggle_all_exercises_checkbox')),
      findsOneWidget,
    );
    expect(find.text('진행 그래프'), findsOneWidget);
    expect(find.byType(Checkbox), findsWidgets);

    await tester.tap(find.byKey(const Key('show_progress_chart_checkbox')));
    await tester.pumpAndSettle();
    expect(find.byType(PerformanceChart), findsNothing);

    await tester.tap(find.byKey(const Key('toggle_all_exercises_checkbox')));
    await tester.pumpAndSettle();
    final checkbox = tester.widget<Checkbox>(
      find.byKey(const Key('toggle_all_exercises_checkbox')),
    );
    expect(checkbox.value, isFalse);
  });

  testWidgets('증량값을 Cupertino 피커로 선택한다', (WidgetTester tester) async {
    double? selectedAmount;
    final records = [
      WorkoutRecord(exercise: '스쿼트', weight: 80, date: DateTime(2026, 10, 8)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressPage(
            records: records,
            exerciseProgressions: const {
              '스쿼트': ExerciseProgressionSetting(
                enabled: true,
                incrementKg: 1.25,
              ),
            },
            onToggleProgression: (_, _) async {},
            onChangeProgressionAmount: (_, amount) async {
              selectedAmount = amount;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('progression_amount_스쿼트')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('progression_picker')), findsOneWidget);
    expect(find.text('+1.25kg'), findsWidgets);

    await tester.drag(
      find.byKey(const Key('progression_picker')),
      const Offset(0, -5000),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('progression_picker')),
      const Offset(0, -1000),
    );
    await tester.pumpAndSettle();
    expect(find.text('+10kg'), findsOneWidget);

    await tester.tap(find.byKey(const Key('progression_picker_done')));
    await tester.pumpAndSettle();
    expect(selectedAmount, 10);
  });

  testWidgets('유산소 시간을 시간, 분, 초 피커로 한 번에 설정한다', (WidgetTester tester) async {
    int? selectedDuration;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardioDurationPicker(
            durationSeconds: 3723,
            onChanged: (seconds) => selectedDuration = seconds,
          ),
        ),
      ),
    );

    expect(find.text('01시간  02분  03초'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cardio_duration_picker_button')));
    await tester.pumpAndSettle();

    expect(find.text('운동 시간'), findsOneWidget);
    expect(find.byKey(const Key('cardio_시간_picker')), findsOneWidget);
    expect(find.byKey(const Key('cardio_분_picker')), findsOneWidget);
    expect(find.byKey(const Key('cardio_초_picker')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cardio_duration_done')));
    await tester.pumpAndSettle();
    expect(selectedDuration, 3723);
  });

  testWidgets('휴식 알림을 추가하고 이전 시점보다 길게 설정한다', (
    WidgetTester tester,
  ) async {
    var settings = const RestTimerSettings(initialSeconds: 90);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SettingsPage(
              restTimerSettings: settings,
              onChangeRestTimerSettings: (value) async {
                setState(() => settings = value);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('1분 30초'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add_rest_alert')));
    await tester.pumpAndSettle();
    expect(find.text('3분'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_rest_alert')));
    await tester.pumpAndSettle();
    expect(find.text('5분'), findsOneWidget);
    expect(settings.alertSeconds, [180, 300]);

    await tester.tap(find.byKey(const Key('decrease_rest_alert_0')));
    await tester.pumpAndSettle();
    expect(settings.alertSeconds, [150, 300]);
  });
}
