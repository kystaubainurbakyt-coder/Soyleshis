import 'package:soyle/features/lessons/presentation/widgets/lesson_practice.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:soyle/features/progress/presentation/screens/journey_screen.dart';
import 'package:soyle/features/progress/presentation/screens/achievements_screen.dart';
import 'package:soyle/features/progress/presentation/screens/certificate_screen.dart';
import 'package:soyle/features/progress/data/certificate_export.dart';
import 'package:soyle/features/review/presentation/screens/review_screen.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soyle/features/auth/presentation/screens/auth_screen.dart';
import 'package:soyle/features/home/presentation/screens/home_screen.dart';
import 'package:soyle/features/lessons/presentation/screens/lesson_detail_screen.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Capture mobile UI previews', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
    await tester.runAsync(() async {
      for (final family in ['NotoSans', 'Manrope', 'NotoSerif']) {
        final loader = FontLoader(family);
        for (final name
            in family == 'NotoSans'
                ? [
                    'NotoSans-Regular',
                    'NotoSans-SemiBold',
                    'NotoSans-Bold',
                    'NotoSans-ExtraBold',
                  ]
                : [family]) {
          loader.addFont(
            Future.value(
              ByteData.sublistView(
                await File('assets/fonts/$name.ttf').readAsBytes(),
              ),
            ),
          );
        }
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File(
                '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
              ).readAsBytes(),
            ),
          ),
        );
      await icons.load();
      // Used only by this explicit flutter test capture helper.
      // ignore: invalid_use_of_visible_for_testing_member
      FlutterSecureStorage.setMockInitialValues({});
      await AppState.instance.openAccount({
        'name': 'Айдана',
        'email': 'preview@gmail.com',
      });
      await Directory('docs/previews').create(recursive: true);
    });
    Future<void> capture(
      String name,
      Widget page, {
      Object? arg,
      double scroll = 0,
    }) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: Locale(AppLocale.instance.language),
            supportedLocales: const [Locale('ru'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              settings: RouteSettings(arguments: arg),
              builder: (_) => page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (scroll != 0) {
        await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/previews/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    await capture('login', const AuthScreen());
    await capture('registration', const AuthScreen(register: true));
    await capture('home', const HomeScreen());
    await capture('journey', const JourneyScreen());
    await capture('achievements', const AchievementsScreen());
    await capture('review', const ReviewScreen());
    final practiceLesson = const LessonService().getLessons().first;
    await capture(
      'practice',
      Scaffold(
        appBar: AppBar(title: Text(tr('practice'))),
        body: LessonPractice(
          lesson: practiceLesson,
          material: LessonMaterial.forLesson(practiceLesson),
        ),
      ),
    );
    await capture(
      'lesson',
      const LessonDetailScreen(),
      arg: const LessonService().getLessons().first,
    );
    await tester.runAsync(() async {
      for (final lesson in AppState.instance.levelLessons('A1')) {
        AppState.instance.recordAttempt(lesson.id, 100);
      }
      await AppState.instance.flush();
      final bytes = await const CertificateExport().create(
        AppState.instance.certificates['A1']!,
      );
      await File('docs/previews/certificate.pdf').writeAsBytes(bytes);
    });
    await capture('certificate', const CertificateScreen(), arg: 'A1');
    await capture('home-courses-ru', const HomeScreen(), scroll: 650);
    await tester.runAsync(() => AppLocale.instance.setLanguage('en'));
    await capture('home-en', const HomeScreen());
    await capture('lesson-en', const LessonDetailScreen(), arg: practiceLesson);
    await capture('certificate-en', const CertificateScreen(), arg: 'A1');
    tester.view.physicalSize = const Size(1024, 768);
    await capture('home-tablet', const HomeScreen());
  });
}
