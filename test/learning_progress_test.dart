import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/progress/domain/learning_progress.dart';
import 'package:soyle/features/progress/data/certificate_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppState state;
  final day = DateTime(2026, 10, 27);
  const account = {'name': 'Әлия Қанатқызы', 'email': 'aliya@example.com'};
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    state = AppState();
    await state.openAccount(account);
  });
  tearDown(() async {
    await state.flush();
    state.dispose();
  });

  test('levels unlock at 70 percent, certificates need average 85', () async {
    expect(state.levelUnlocked('A1'), isTrue);
    expect(state.levelUnlocked('A2'), isFalse);
    expect(state.recordAttempt(state.levelLessons('A2').first.id, 100), 0);
    for (final lesson in state.levelLessons('A1')) {
      state.recordAttempt(lesson.id, 69);
    }
    expect(state.levelUnlocked('A2'), isFalse);
    for (final lesson in state.levelLessons('A1')) {
      state.recordAttempt(lesson.id, 70);
    }
    expect(state.levelUnlocked('A2'), isTrue);
    expect(state.levelUnlocked('B1'), isFalse);
    expect(state.certificates, isEmpty);
    for (final lesson in state.levelLessons('A1')) {
      state.recordAttempt(lesson.id, 84);
    }
    expect(state.certificates, isEmpty);
    for (final lesson in state.levelLessons('A1')) {
      state.recordAttempt(lesson.id, 85);
    }
    expect(state.certificates['A1']!.average, 85);
    await state.flush();
    final restored = AppState();
    await restored.openAccount(account);
    expect(restored.levelUnlocked('A2'), isTrue);
    expect(restored.certificates['A1']!.average, 85);
    await restored.flush();
    restored.dispose();
  });
  test(
    'XP rewards pass and perfect once; failure and replay cannot farm points',
    () async {
      final id = state.lessons.first.id;
      expect(state.recordAttempt(id, 50, now: day), 0);
      expect(state.completed, isEmpty);
      expect(state.recordAttempt(id, 75, now: day), 100);
      expect(state.recordAttempt(id, 75, now: day), 0);
      expect(state.recordAttempt(id, 100, now: day), 25);
      expect(state.recordAttempt(id, 100, now: day), 0);
      expect(state.recordAttempt(id, 101, now: day), 0);
      expect(state.recordAttempt(-1, 100, now: day), 0);
      expect(state.xp, 125);
      expect(state.activity[learningDay(day)], 125);
      state.recordAttempt(id, 100, now: day.add(const Duration(days: 1)));
      expect(state.activity[learningDay(day.add(const Duration(days: 1)))], 0);
      expect(state.scores[id], 100);
    },
  );

  test(
    'Certificates require all lessons and average at least 85% and persist with stable identity',
    () async {
      final course = state.levelLessons('A1');
      for (final lesson in course.take(course.length - 1)) {
        state.recordAttempt(lesson.id, 100, now: day);
      }
      expect(state.certificates, isEmpty);
      state.recordAttempt(course.last.id, 50, now: day);
      expect(state.certificates, isEmpty);
      state.recordAttempt(course.last.id, 75, now: day);
      final certificate = state.certificates['A1']!;
      expect(certificate.lessonCount, course.length);
      expect(certificate.name, account['name']);
      expect(certificate.issuedAt, '2026-10-27');
      expect(state.certificates.containsKey('A2'), isFalse);
      state.recordAttempt(
        course.last.id,
        100,
        now: day.add(const Duration(days: 1)),
      );
      expect(state.certificates['A1']!.toJson(), certificate.toJson());
      await state.flush();
      await state.signOut();
      await state.openAccount(account);
      expect(state.certificates['A1']!.toJson(), certificate.toJson());
      await state.openAccount({'name': 'Басқа', 'email': 'other@example.com'});
      expect(state.certificates, isEmpty);
      expect(state.xp, 0);
      expect(state.activity, isEmpty);
    },
  );

  test('Review bonus is once per calendar day, saved across restart', () async {
    expect(state.finishReview(now: day), 20);
    expect(state.finishReview(now: day.add(const Duration(hours: 12))), 0);
    await state.flush();
    await state.openAccount(account);
    expect(state.finishReview(now: day), 0);
    expect(state.finishReview(now: day.add(const Duration(days: 1))), 20);
    expect(state.xp, 40);
  });

  test(
    'Earned badges survive removing favorites and an account restart',
    () async {
      state.update(
        () => state.favorites.addAll(state.lessons.take(3).map((l) => l.id)),
      );
      expect(
        state.badges.firstWhere((b) => b.id == 'collector').earned,
        isTrue,
      );
      state.update(() => state.favorites.clear());
      await state.flush();
      await state.openAccount(account);
      expect(state.favorites, isEmpty);
      expect(
        state.badges.firstWhere((b) => b.id == 'collector').earned,
        isTrue,
      );
      state.finishReview(now: day);
      state.finishReview(now: day.add(const Duration(days: 1)));
      state.finishReview(now: day.add(const Duration(days: 2)));
      expect(state.badges.firstWhere((b) => b.id == 'streak').earned, isTrue);
    },
  );

  test(
    'Streak tolerates an unfinished today, breaks on gaps and crosses months',
    () {
      final activity = {'2026-09-29': 100, '2026-09-30': 0, '2026-10-01': 20};
      expect(learningStreak(activity, DateTime(2026, 10, 1)), 3);
      expect(learningStreak(activity, DateTime(2026, 10, 2)), 3);
      expect(learningStreak(activity, DateTime(2026, 10, 3)), 0);
      expect(learningStreak({}, day), 0);
    },
  );

  test('Old saved scores below 85 do not issue a certificate', () async {
    final course = state.levelLessons('A2');
    await const FlutterSecureStorage().write(
      key: 'soyle.progress.v1.legacy@example.com',
      value: jsonEncode({
        'name': 'Бұрынғы қолданушы',
        'completed': course.map((l) => l.id).toList(),
        'scores': {for (final l in course) '${l.id}': 75},
      }),
    );
    await state.openAccount({
      'name': 'Бұрынғы қолданушы',
      'email': 'legacy@example.com',
    });
    expect(state.certificates.containsKey('A2'), isFalse);
    state.update(() {});
    await state.flush();
    final saved = await const FlutterSecureStorage().read(
      key: 'soyle.progress.v1.legacy@example.com',
    );
    expect((jsonDecode(saved!) as Map)['certificates'], isEmpty);
  });

  test(
    'Legacy personal lessons cannot override the published catalog; short-course certificates are archived',
    () async {
      await const FlutterSecureStorage().write(
        key: 'soyle.progress.v1.old@example.com',
        value: jsonEncode({
          'name': 'Old learner',
          'completed': [1, 2, 3, 4, 7],
          'scores': {'1': 100, '2': 100, '3': 100, '4': 100, '7': 100},
          'lessons': [
            {'id': 7, 'title': 'Personal override', 'level': 'A1'},
          ],
          'certificates': [
            const LearningCertificate(
              id: 'OLD-A1',
              level: 'A1',
              name: 'Old learner',
              email: 'old@example.com',
              issuedAt: '2026-10-20',
              lessonCount: 5,
              average: 100,
            ).toJson(),
          ],
        }),
      );
      await state.openAccount({
        'name': 'Old learner',
        'email': 'old@example.com',
      });
      expect(state.lessons, hasLength(75));
      expect(state.lessons.first.title, isNot('Personal override'));
      expect(state.certificates, isEmpty);
      expect(state.certificateArchive.single.id, 'OLD-A1');
      expect(state.levelPassed('A1'), 5);
    },
  );

  test(
    'Certificate PDF embeds Kazakh fonts and produces a real PDF file',
    () async {
      final data = await const CertificateExport().create(
        const LearningCertificate(
          id: 'SOYLE-A1-TEST1234',
          level: 'A1',
          name: 'Әлия Ғабитқызы Қоңыр',
          email: 'aliya@example.com',
          issuedAt: '2026-10-27',
          lessonCount: 6,
          average: 95,
        ),
      );
      expect(ascii.decode(data.take(4).toList()), '%PDF');
      expect(data.length, greaterThan(10000));
    },
  );
}
