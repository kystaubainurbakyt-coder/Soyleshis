import 'package:soyle/features/notebook/presentation/screens/notebook_screen.dart';
import 'package:soyle/features/notebook/presentation/screens/rest_api_screen.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
// ignore_for_file: prefer_const_constructors
// Fresh screen widgets let language updates rebuild UI while retaining State.
import 'package:soyle/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:soyle/features/progress/presentation/screens/journey_screen.dart';
import 'package:soyle/features/progress/presentation/screens/achievements_screen.dart';
import 'package:soyle/features/progress/presentation/screens/certificate_screen.dart';
import 'package:soyle/features/review/presentation/screens/review_screen.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/features/lessons/presentation/screens/sentence_lab_screen.dart';
import 'package:soyle/features/profile/presentation/screens/settings_screen.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:soyle/features/auth/presentation/screens/auth_screen.dart';
import 'package:soyle/features/lessons/presentation/screens/catalog_screen.dart';
import 'package:soyle/features/home/presentation/screens/home_screen.dart';
import 'package:soyle/features/lessons/presentation/screens/lesson_detail_screen.dart';
import 'package:soyle/features/profile/presentation/screens/profile_screen.dart';
import 'package:soyle/features/qr/presentation/screens/qr_scanner_screen.dart';
import 'package:soyle/features/chat/presentation/screens/study_chat_screen.dart';
import 'package:soyle/features/onboarding/presentation/screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const lessons = '/lessons';
  static const lessonDetail = '/lesson-detail';
  static const search = '/search';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const settings = '/settings';
  static const editor = '/editor';
  static const sentenceLab = '/sentence-lab';
  static const journey = '/journey';
  static const achievements = '/achievements';
  static const certificate = '/certificate';
  static const review = '/review';
  static const notebook = '/notebook';
  static const restApi = '/notebook/rest-api';
  static const qrScanner = '/qr-scanner';
  static const studyRoom = '/study-room';
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => SplashScreen(),
    login: (_) => AuthScreen(),
    register: (_) => AuthScreen(register: true),
    onboarding: (_) => OnboardingScreen(),
    home: (_) => HomeScreen(),
    lessons: (_) => CatalogScreen(),
    lessonDetail: (_) => LessonDetailScreen(),
    search: (_) => CatalogScreen(search: true),
    favorites: (_) => CatalogScreen(favorites: true),
    profile: (_) => ProfileScreen(),
    settings: (_) => SettingsScreen(),
    journey: (_) => JourneyScreen(),
    achievements: (_) => AchievementsScreen(),
    certificate: (_) => CertificateScreen(),
    review: (_) => ReviewScreen(),
    notebook: (_) => NotebookScreen(),
    restApi: (_) => const RestApiScreen(),
    sentenceLab: (_) => SentenceLabScreen(),
    qrScanner: (_) => const QrScannerScreen(),
    studyRoom: (_) => const StudyChatScreen(),
  };
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final public = {splash, login, register, onboarding};
    if (!public.contains(settings.name) && !AppState.instance.authenticated) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: login),
        builder: (_) => ListenableBuilder(
          listenable: AppLocale.instance,
          builder: (_, _) => AuthScreen(),
        ),
      );
    }
    final argument = settings.arguments;
    final locked =
        argument is Lesson && !AppState.instance.levelUnlocked(argument.level);
    final builder = locked ? null : routes[settings.name];
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => ListenableBuilder(
        listenable: AppLocale.instance,
        builder: (context, _) => builder != null
            ? builder(context)
            : Scaffold(
                appBar: AppBar(title: Text(tr('notFound'))),
                body: Center(
                  child: Text(tr(locked ? 'levelLocked' : 'readOnly')),
                ),
              ),
      ),
    );
  }
}
