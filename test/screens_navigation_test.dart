import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/presentation/widgets/lesson_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final state = AppState.instance;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await state.signOut();
    await state.openAccount({'name': 'Alex', 'email': 'layout@example.com'});
    await AppLocale.instance.setLanguage('ru');
  });
  Future<void> open(
    WidgetTester tester,
    String route, {
    Object? args,
    double scale = 1,
  }) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        onGenerateInitialRoutes: (_) => [
          AppRoutes.onGenerateRoute(
            RouteSettings(name: route, arguments: args),
          ),
        ],
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final lang in ['ru', 'en']) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(1024, 768),
    ]) {
      testWidgets('$lang: all learner screens fit $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() => AppLocale.instance.setLanguage(lang));
        for (final route in [
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.onboarding,
          AppRoutes.home,
          AppRoutes.lessons,
          AppRoutes.lessonDetail,
          AppRoutes.search,
          AppRoutes.favorites,
          AppRoutes.profile,
          AppRoutes.settings,
          AppRoutes.journey,
          AppRoutes.achievements,
          AppRoutes.certificate,
          AppRoutes.review,
          AppRoutes.sentenceLab,
        ]) {
          await open(
            tester,
            route,
            args:
                [AppRoutes.lessonDetail, AppRoutes.sentenceLab].contains(route)
                ? state.lessons.first
                : null,
            scale: size.width == 320 ? 1.3 : 1,
          );
          expect(tester.takeException(), isNull, reason: '$lang $route $size');
          expect(find.byType(Scaffold), findsOneWidget);
          if (route == AppRoutes.home) {
            await tester.fling(
              find.byType(Scrollable).first,
              const Offset(0, -1800),
              1600,
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Scrolled home: $lang $size',
            );
          }
        }
      });
    }
  }
  testWidgets(
    'Learners cannot create or edit published lessons, even via named routes',
    (tester) async {
      await open(tester, AppRoutes.lessons);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(() => state.lessons.clear(), throwsUnsupportedError);
      await open(tester, AppRoutes.editor);
      expect(find.text(tr('readOnly')), findsOneWidget);
      expect(find.byType(Form), findsNothing);
      await open(tester, AppRoutes.lessonDetail, args: state.lessons.first);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    },
  );
  testWidgets('English search, saved lesson and root navigation work', (
    tester,
  ) async {
    await tester.runAsync(() => AppLocale.instance.setLanguage('en'));
    await open(tester, AppRoutes.search);
    await tester.enterText(find.byType(TextFormField), 'greetings');
    await tester.pumpAndSettle();
    expect(find.byType(LessonCard), findsOneWidget);
    await tester.tap(find.byType(LessonCard));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == tr('saveLesson'),
            ),
          )
          .onPressed!();
      await state.flush();
    });
    await tester.pumpAndSettle();
    await open(tester, AppRoutes.favorites);
    expect(find.byType(LessonCard), findsOneWidget);
    tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .onDestinationSelected!(4);
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    expect(Navigator.of(tester.element(find.text('Alex'))).canPop(), isFalse);
  });
  testWidgets('Settings validation and renamed profile persist', (
    tester,
  ) async {
    await open(tester, AppRoutes.profile);
    await tester.scrollUntilVisible(
      find.text(tr('settings')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('settings')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), ' ');
    await tester.tap(find.widgetWithText(ElevatedButton, tr('save')));
    await tester.pumpAndSettle();
    expect(find.text(tr('Атыңыз кемінде 2 таңба болсын')), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Anna');
    await tester.runAsync(() async {
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, tr('save')),
          )
          .onPressed!();
      await state.flush();
    });
    await tester.pumpAndSettle();
    expect(state.name, 'Anna');
  });
}
