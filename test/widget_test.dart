import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/features/lessons/presentation/widgets/lesson_practice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soyle/main.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/auth/data/auth_service.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, String> seed;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AuthService().register('Айдана', 'student@gmail.com', 'Password1');
    seed = await const FlutterSecureStorage().readAll();
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(Map<String, String>.of(seed));
    await AppState.instance.signOut();
  });
  Future<void> splash(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SoyleApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> submitLogin(
    WidgetTester tester,
    String address,
    String password,
  ) async {
    await tester.enterText(find.byType(TextFormField).at(0), address);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    final button = find.widgetWithText(ElevatedButton, tr('login'));
    await tester.ensureVisible(button);
    // Execute the async submit in a real zone: isolate/secure-storage futures
    // cannot be awaited inside Flutter's fake clock.
    await tester.runAsync(() async {
      final callback = tester.widget<ElevatedButton>(button).onPressed!;
      await (Function.apply(callback, const []) as Future<void>);
    });
    await tester.pumpAndSettle();
  }

  Future<void> drainWrites(WidgetTester tester) async {
    var completed = false;
    AppState.instance.flush().then((_) => completed = true);
    for (var i = 0; i < 200 && !completed; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(completed, isTrue, reason: 'Queued profile writes must finish');
  }

  testWidgets('Unregistered users cannot log in', (tester) async {
    await splash(tester);
    await submitLogin(tester, 'unknown@gmail.com', 'Password1');
    expect(AppState.instance.authenticated, isFalse);
    expect(
      find.text(
        tr(
          'Email немесе құпиясөз қате. Тіркелмесеңіз, алдымен аккаунт құрыңыз.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(tr('progress')), findsNothing);
  });
  testWidgets('Registered login → lesson → exercise → completed → profile', (
    tester,
  ) async {
    await splash(tester);
    await submitLogin(tester, 'student@gmail.com', 'Password1');
    expect(AppState.instance.authenticated, isTrue);
    await tester.scrollUntilVisible(
      find.text(tr('allCourses')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('allCourses')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        AppState.instance.lessons.firstWhere((l) => l.id == 1).displayTitle,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == tr('saveLesson'),
            ),
          )
          .onPressed!();
    });
    await tester.pumpAndSettle();
    expect(AppState.instance.favorites, contains(1));
    await tester.ensureVisible(find.text(tr('practice')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('practice')));
    await tester.pumpAndSettle();
    final lesson = const LessonService().getLessons().firstWhere(
      (l) => l.id == 1,
    );
    await tester.tap(find.byKey(const ValueKey('start-practice')));
    await tester.pumpAndSettle();
    final questions = LessonMaterial.forLesson(lesson).questions(lesson);
    for (var i = 0; i < questions.length; i++) {
      final answer = find.byKey(ValueKey('answer-${questions[i].answer}'));
      await tester.scrollUntilVisible(
        answer,
        200,
        scrollable: find
            .descendant(
              of: find.byType(LessonPractice),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(answer);
      await tester.pumpAndSettle();
      final next = find.text(
        i == questions.length - 1 ? tr('seeResults') : tr('nextQuestion'),
      );
      await tester.scrollUntilVisible(
        next,
        200,
        scrollable: find
            .descendant(
              of: find.byType(LessonPractice),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        tester
            .widget<ElevatedButton>(
              find
                  .ancestor(of: next, matching: find.byType(ElevatedButton))
                  .first,
            )
            .onPressed!();
      });
      await tester.pumpAndSettle();
    }
    expect(AppState.instance.completed, contains(1));
    expect(AppState.instance.scores[1], 100);
    await tester.scrollUntilVisible(
      find.text(tr('profile')),
      250,
      scrollable: find
          .descendant(
            of: find.byType(LessonPractice),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('profile')));
    await tester.pumpAndSettle();
    expect(find.text('Айдана'), findsOneWidget);
    expect(find.text(tr('completedLessons')), findsOneWidget);
    await tester.pump();
  });
  testWidgets(
    'Login and registration validate format, uppercase and confirmation',
    (tester) async {
      await splash(tester);
      final button = find.widgetWithText(ElevatedButton, tr('login'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(tr('Email енгізіңіз')), findsOneWidget);
      expect(
        find.text(tr('Құпиясөз кемінде 6 таңба болуы керек')),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'badgmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'abcdef');
      await tester.pumpAndSettle();
      expect(
        find.text(tr('Email қате. Мысалы: name@gmail.com')),
        findsOneWidget,
      );
      expect(find.text(tr('Кемінде бір үлкен әріп қосыңыз')), findsOneWidget);
      await tester.ensureVisible(find.text(tr('noAccount')));
      await tester.tap(find.text(tr('noAccount')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Арман');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'arman@gmail.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Password1');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password2');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, tr('register')),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, tr('register')));
      await tester.pumpAndSettle();
      expect(find.text(tr('passwordMismatch')), findsOneWidget);
      expect(AppState.instance.authenticated, isFalse);
    },
  );
  testWidgets('Protected named routes require authentication', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text(tr('progress')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
  testWidgets(
    'Incorrect exercise does not complete lesson and can be retried',
    (tester) async {
      final state = AppState.instance;
      await tester.runAsync(() async {
        await state.openAccount(
          await state.auth.login('student@gmail.com', 'Password1'),
        );
      });
      final lesson = const LessonService().getLessons().first;
      final material = LessonMaterial.forLesson(lesson);
      final qs = material.questions(lesson);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LessonPractice(lesson: lesson, material: material),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('start-practice')));
      await tester.pumpAndSettle();
      for (var i = 0; i < qs.length; i++) {
        final wrong = (qs[i].answer + 1) % qs[i].options.length;
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('answer-$wrong')),
          200,
          scrollable: find
              .descendant(
                of: find.byType(LessonPractice),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('answer-$wrong')));
        await tester.pumpAndSettle();
        final next = find.text(
          i == qs.length - 1 ? tr('seeResults') : tr('nextQuestion'),
        );
        await tester.scrollUntilVisible(
          next,
          200,
          scrollable: find
              .descendant(
                of: find.byType(LessonPractice),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          tester
              .widget<ElevatedButton>(
                find
                    .ancestor(of: next, matching: find.byType(ElevatedButton))
                    .first,
              )
              .onPressed!();
        });
        await tester.pumpAndSettle();
      }
      expect(state.completed, isEmpty);
      await tester.scrollUntilVisible(find.text(tr('retry')), 200);
      await tester.tap(find.text(tr('retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-practice')), findsOneWidget);
      expect(state.completed, isEmpty);
      await drainWrites(tester);
    },
  );
}
