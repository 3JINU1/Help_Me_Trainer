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
import 'package:hmtrainer/widgets/performance_chart.dart';

void main() {
  testWidgets('앱이 오늘 화면을 표시한다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('운동'), findsOneWidget);
  });

  testWidgets('그래프 표시 여부와 전체 운동 선택 체크박스를 제어한다', (
    WidgetTester tester,
  ) async {
    final records = [
      WorkoutRecord(
        exercise: '스쿼트',
        weight: 100,
        date: DateTime(2024, 1, 1),
      ),
      WorkoutRecord(
        exercise: '스쿼트',
        weight: 110,
        date: DateTime(2024, 1, 3),
      ),
      WorkoutRecord(
        exercise: '벤치프레스',
        weight: 60,
        date: DateTime(2024, 1, 2),
      ),
      WorkoutRecord(
        exercise: '벤치프레스',
        weight: 70,
        date: DateTime(2024, 1, 4),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressPage(records: records),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('show_progress_chart_checkbox')), findsOneWidget);
    expect(find.byKey(const Key('toggle_all_exercises_checkbox')), findsOneWidget);
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
}
