import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soyle/app/app.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppState.instance.signOut();
    await AppLocale.instance.setLanguage('ru');
  });
  test('Every interface key has exactly two nonempty translations', () {
    for (final entry in messages.entries) {
      expect(entry.value, hasLength(2), reason: entry.key);
      expect(
        entry.value.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: entry.key,
      );
    }
  });
  test(
    'Lesson counters use Russian and English singular and plural forms',
    () async {
      for (final entry in {
        1: '1 урок',
        2: '2 урока',
        5: '5 уроков',
        11: '11 уроков',
        21: '21 урок',
        24: '24 урока',
      }.entries) {
        expect(tr('lessonsCount', {'n': entry.key}), entry.value);
      }
      await AppLocale.instance.setLanguage('en');
      expect(tr('lessonsCount', {'n': 1}), '1 lesson');
      expect(tr('lessonsCount', {'n': 2}), '2 lessons');
      expect(tr('days', {'n': 1}), '1 day');
      expect(tr('days', {'n': 2}), '2 days');
    },
  );
  test(
    '75 lessons have both instructional languages and unambiguous exercises',
    () async {
      final lessons = const LessonService().getLessons();
      expect(lessons.where((l) => l.level == 'A1'), hasLength(30));
      expect(lessons.map((l) => l.id).toSet(), hasLength(75));
      for (final language in ['ru', 'en']) {
        await AppLocale.instance.setLanguage(language);
        for (final lesson in lessons) {
          expect(lesson.displayTitle, isNotEmpty);
          expect(lesson.rule.length, greaterThan(100));
          expect(lesson.words, hasLength(6));
          for (final question in LessonMaterial.forLesson(
            lesson,
          ).questions(lesson)) {
            expect(question.options.toSet().length, question.options.length);
            expect(question.options[question.answer], isNotEmpty);
            expect(question.prompt, isNotEmpty);
            expect([
              'meaning',
              'grammarSkill',
              'dialogueSkill',
              'syntaxSkill',
            ], contains(question.skill));
          }
        }
      }
    },
  );
  testWidgets(
    'Language switches on the current login screen and preserves typed input',
    (tester) async {
      await tester.pumpWidget(const SoyleApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Рады видеть вас снова'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'anna@example.com',
      );
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Рады видеть вас снова'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'anna@example.com',
      );
      await tester.runAsync(() => AppLocale.instance.initialize());
      expect(AppLocale.instance.language, 'en');
    },
  );
  testWidgets(
    'Lesson shows Kazakh and only the selected translation language',
    (tester) async {
      final state = AppState.instance;
      await tester.runAsync(
        () => state.openAccount({'name': 'Anna', 'email': 'anna@example.com'}),
      );
      final lesson = state.lessons.firstWhere((l) => l.id == 1);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onGenerateInitialRoutes: (_) => [
            AppRoutes.onGenerateRoute(
              RouteSettings(name: AppRoutes.lessonDetail, arguments: lesson),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr('vocabulary')));
      await tester.pumpAndSettle();
      expect(find.text(lesson.words.first.ru), findsOneWidget);
      expect(find.text(lesson.words.first.en), findsNothing);
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text(lesson.words.first.en), findsOneWidget);
      expect(find.text(lesson.words.first.ru), findsNothing);
      expect(find.text(lesson.words.first.kk), findsOneWidget);
    },
  );
}
