import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';
import 'package:soyle/features/lessons/presentation/widgets/lesson_practice.dart';

void main() {
  final state = AppState.instance;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await state.signOut();
    await state.openAccount({'email': 'timer@example.com', 'name': 'Anna'});
    await AppLocale.instance.setLanguage('en');
  });
  testWidgets('Timer expires in background and unanswered tasks cannot pass', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 28);
    final lesson = state.lessons.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonPractice(
            lesson: lesson,
            material: LessonMaterial.forLesson(lesson),
            now: () => now,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('start-practice')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    now = now.add(Duration(minutes: lesson.minutes + 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(tr('timeExpired')), findsOneWidget);
    expect(state.completed, isEmpty);
    expect(state.xp, 0);
    await tester.pumpWidget(const SizedBox());
    var flushed = false;
    state.flush().then((_) => flushed = true);
    for (var i = 0; i < 200 && !flushed; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(flushed, isTrue);
  });
  testWidgets(
    'Leaving active practice requires confirmation and staying keeps timer',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final lesson = state.lessons.first;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('home')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(),
            body: LessonPractice(
              lesson: lesson,
              material: LessonMaterial.forLesson(lesson),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-practice')));
      await tester.pumpAndSettle();
      navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.text(tr('leavePractice')), findsOneWidget);
      await tester.tap(find.text(tr('stayPractice')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr('leaveNow')));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(state.completed, isEmpty);
    },
  );
}
