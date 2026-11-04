import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final state = AppState.instance;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await state.signOut();
    await state.openAccount({'name': 'Anna', 'email': 'progress@example.com'});
    await AppLocale.instance.setLanguage('en');
  });
  Future<void> open(WidgetTester tester, String route, {Object? args}) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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

  Future<void> press(WidgetTester tester, String label) async {
    final button = find.widgetWithText(ElevatedButton, label);
    if (button.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        button,
        250,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final result = Function.apply(
        tester.widget<ElevatedButton>(button).onPressed!,
        const [],
      );
      if (result is Future) await result;
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'A full course unlocks a certificate and exports the selected-language PDF',
    (tester) async {
      await open(tester, AppRoutes.certificate, args: 'A1');
      expect(find.text(tr('downloadPdf')), findsNothing);
      await tester.runAsync(() async {
        for (final lesson in state.levelLessons('A1')) {
          state.recordAttempt(lesson.id, 100);
        }
        await state.flush();
      });
      await open(tester, AppRoutes.certificate, args: 'A1');
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text(tr('downloadPdf')), findsOneWidget);
      MethodCall? shared;
      const channel = MethodChannel('net.nfet.printing');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'sharePdf') {
              shared = call;
              return 1;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await press(tester, tr('downloadPdf'));
      expect(shared, isNotNull);
      final args = shared!.arguments as Map;
      expect(args['name'], '${state.certificates['A1']!.id}-en.pdf');
      expect((args['doc'] as Uint8List).take(4), [37, 80, 68, 70]);
    },
  );
  testWidgets('Review rewards a complete deck once per day', (tester) async {
    for (var pass = 0; pass < 2; pass++) {
      await open(tester, AppRoutes.review);
      for (var i = 0; i < 12; i++) {
        await press(tester, tr('showTranslation'));
        await press(tester, tr('know'));
      }
      expect(state.xp, 20);
      expect(find.text(tr('reviewDone')), findsOneWidget);
      await tester.runAsync(() => state.flush());
    }
  });
  testWidgets(
    'Sentence builder supports repeated words and validates their order',
    (tester) async {
      final lesson = state.lessons.first;
      await open(tester, AppRoutes.sentenceLab, args: lesson);
      for (final word in lesson.words.first.kk.split(' ')) {
        await tester.tap(find.widgetWithText(ActionChip, word).first);
        await tester.pumpAndSettle();
      }
      await press(tester, tr('checkSentence'));
      expect(find.text(tr('correct')), findsOneWidget);
    },
  );
}
