import 'package:soyle/core/database/learning_repository.dart';
import 'dart:convert';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
import 'package:soyle/features/auth/data/auth_service.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/progress/domain/learning_progress.dart';

class AppState extends ChangeNotifier {
  static final instance = AppState();
  final auth = AuthService();
  final _storage = const FlutterSecureStorage();
  Future<void>? _pending;
  LearningRepository? repository;
  List<Lesson> get lessons => repository?.readLessons() ?? curriculum;
  final favorites = <int>{};
  final completed = <int>{};
  final scores = <int, int>{};
  final activity = <String, int>{};
  final reviewDays = <String>{};
  final certificates = <String, LearningCertificate>{};
  final certificateArchive = <LearningCertificate>[];
  final earnedBadges = <String>{};
  static final curriculum = const LessonService().getLessons();
  int get xp =>
      scores.values.fold(
        0,
        (sum, score) => sum + (score >= 70 ? 100 : 0) + (score == 100 ? 25 : 0),
      ) +
      reviewDays.length * 20;
  int get streak => learningStreak(activity, DateTime.now());
  int get todayXp => activity[learningDay(DateTime.now())] ?? 0;
  int get dailyGoal => completed.length >= curriculum.length ? 20 : 100;
  int get rank => xp ~/ 300 + 1;
  String get rankTitle => tr('rank${(rank - 1).clamp(0, 3)}');
  List<Lesson> levelLessons(String level) =>
      curriculum.where((l) => l.level == level).toList();
  int levelPassed(String level) => levelLessons(
    level,
  ).where((l) => completed.contains(l.id) && (scores[l.id] ?? 0) >= 70).length;
  double levelAverage(String level) {
    final course = levelLessons(level);
    return course.isEmpty
        ? 0
        : course.fold<int>(0, (sum, l) => sum + (scores[l.id] ?? 0)) /
              course.length;
  }

  bool levelUnlocked(String level) {
    final index = LessonService.levels.indexOf(level);
    if (index < 0) return false;
    if (index == 0) return true;
    final previous = LessonService.levels[index - 1];
    return levelUnlocked(previous) &&
        levelPassed(previous) == levelLessons(previous).length &&
        levelAverage(previous) >= 70;
  }

  List<LearningBadge> get badges => _badgeCandidates
      .map(
        (badge) => LearningBadge(
          badge.id,
          badge.title,
          badge.description,
          badge.earned || earnedBadges.contains(badge.id),
        ),
      )
      .toList();
  List<LearningBadge> get _badgeCandidates => [
    LearningBadge(
      'first',
      tr('badgeFirst'),
      tr('badgeFirstHint'),
      completed.isNotEmpty,
    ),
    LearningBadge(
      'perfect',
      tr('badgePerfect'),
      tr('badgePerfectHint'),
      scores.values.contains(100),
    ),
    LearningBadge(
      'collector',
      tr('badgeCollector'),
      tr('badgeCollectorHint'),
      favorites.length >= 3,
    ),
    LearningBadge(
      'streak',
      tr('badgeStreak'),
      tr('badgeStreakHint'),
      activity.keys.any(
        (day) => learningStreak(activity, DateTime.parse(day)) >= 3,
      ),
    ),
    for (final level in LessonService.levels)
      LearningBadge(
        level,
        '$level · ${tr(level)}',
        tr('courseCertificate'),
        certificates.containsKey(level),
      ),
  ];

  /// Replaying a passed lesson does not farm XP; only a new milestone counts.
  int recordAttempt(int lessonId, int percent, {DateTime? now}) {
    if (!authenticated ||
        percent < 0 ||
        percent > 100 ||
        !lessons.any((l) => l.id == lessonId && levelUnlocked(l.level))) {
      return 0;
    }
    final previous = scores[lessonId] ?? 0;
    final earned =
        (percent >= 70 && previous < 70 ? 100 : 0) +
        (percent == 100 && previous < 100 ? 25 : 0);
    final date = now ?? DateTime.now();
    update(() {
      if (percent > previous) scores[lessonId] = percent;
      if (percent >= 70) {
        completed.add(lessonId);
        final day = learningDay(date);
        // Successful revision counts as an active day even without more XP.
        activity[day] = (activity[day] ?? 0) + earned;
      }
      _issueCertificates(date);
    });
    return earned;
  }

  int finishReview({DateTime? now}) {
    if (!authenticated) return 0;
    final day = learningDay(now ?? DateTime.now());
    if (reviewDays.contains(day)) return 0;
    update(() {
      reviewDays.add(day);
      activity[day] = (activity[day] ?? 0) + 20;
    });
    return 20;
  }

  void _issueCertificates(DateTime date) {
    for (final level in LessonService.levels) {
      final course = levelLessons(level);
      if (certificates.containsKey(level) ||
          course.isEmpty ||
          levelPassed(level) != course.length ||
          levelAverage(level) < 85) {
        continue;
      }
      certificates[level] = LearningCertificate(
        id: LearningCertificate.identifier(email, level),
        level: level,
        name: name,
        email: email,
        issuedAt: learningDay(date),
        lessonCount: course.length,
        average:
            (course.fold<int>(0, (sum, l) => sum + scores[l.id]!) /
                    course.length)
                .round(),
      );
    }
  }

  String name = 'Қонақ';
  String email = '';
  bool reminders = false;
  String? storageError;
  bool get authenticated => email.isNotEmpty;
  String get _key => 'soyle.progress.v1.$email';

  Future<void> openAccount(
    Map<String, dynamic> account, {
    bool persistSession = true,
  }) async {
    final previous = _pending;
    if (previous != null) await previous;
    _pending = null;
    final address = account['email'] as String;
    final stored = repository?.readSnapshot(address);
    final raw = stored == null
        ? await _storage.read(key: 'soyle.progress.v1.$address')
        : null;
    final data =
        stored ??
        (raw == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(raw) as Map));
    _clear();
    name = data['name'] as String? ?? account['name'] as String;
    email = address;
    reminders = data['reminders'] as bool? ?? false;
    favorites.addAll((data['favorites'] as List? ?? []).cast<int>());
    completed.addAll((data['completed'] as List? ?? []).cast<int>());
    scores.addAll(
      (data['scores'] as Map? ?? {}).map(
        (k, v) => MapEntry(int.parse(k as String), v as int),
      ),
    );
    activity.addAll(
      (data['activity'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, v as int),
      ),
    );
    reviewDays.addAll((data['reviewDays'] as List? ?? []).cast<String>());
    earnedBadges.addAll((data['earnedBadges'] as List? ?? []).cast<String>());
    for (final item in (data['certificates'] as List? ?? [])) {
      final certificate = LearningCertificate.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (LessonService.levels.contains(certificate.level) &&
          certificate.lessonCount == levelLessons(certificate.level).length &&
          levelPassed(certificate.level) == certificate.lessonCount &&
          levelAverage(certificate.level) >= 85) {
        certificates[certificate.level] = certificate;
      } else {
        certificateArchive.add(certificate);
      }
    }
    for (final item in (data['certificateArchive'] as List? ?? [])) {
      certificateArchive.add(
        LearningCertificate.fromJson(Map<String, dynamic>.from(item as Map)),
      );
    }
    if (repository != null && stored == null) {
      await repository!.writeSnapshot(address, {
        'name': name,
        'reminders': reminders,
        'favorites': favorites.toList(),
        'completed': completed.toList(),
        'scores': scores.map((k, v) => MapEntry('$k', v)),
        'activity': activity,
        'reviewDays': reviewDays.toList(),
        'earnedBadges': earnedBadges.toList(),
        'certificates': certificates.values.map((c) => c.toJson()).toList(),
        'certificateArchive': certificateArchive
            .map((c) => c.toJson())
            .toList(),
      });
    }
    // Legacy certificates remain archived; the expanded course has new requirements.
    final certificateCount = certificates.length;
    _issueCertificates(DateTime.now());
    if (certificateCount != certificates.length) {
      update(() {});
    } else {
      notifyListeners();
    }
    if (persistSession) await auth.saveSession(address);
  }

  Future<bool> restoreSession() async {
    try {
      final account = await auth.restoreSession();
      if (account == null) return false;
      await openAccount(account, persistSession: false);
      return true;
    } catch (_) {
      await auth.clearSession();
      return false;
    }
  }

  void update(VoidCallback change) {
    if (!authenticated) return;
    change();
    earnedBadges.addAll(
      _badgeCandidates.where((b) => b.earned).map((b) => b.id),
    );
    final key = _key;
    final snapshot = jsonEncode({
      'name': name,
      'reminders': reminders,
      'favorites': favorites.toList(),
      'completed': completed.toList(),
      'scores': scores.map((k, v) => MapEntry('$k', v)),
      'activity': activity,
      'reviewDays': reviewDays.toList(),
      'earnedBadges': earnedBadges.toList(),
      'certificates': certificates.values.map((c) => c.toJson()).toList(),
      'certificateArchive': certificateArchive.map((c) => c.toJson()).toList(),
    });
    _pending = _persist(_pending, key, snapshot);
    notifyListeners();
  }

  Future<void> _persist(
    Future<void>? previous,
    String key,
    String snapshot,
  ) async {
    try {
      if (previous != null) await previous;
      if (repository != null) {
        await repository!.writeSnapshot(
          key.substring('soyle.progress.v1.'.length),
          Map<String, dynamic>.from(jsonDecode(snapshot) as Map),
        );
      } else {
        await _storage.write(key: key, value: snapshot);
      }
      if (_key == key && storageError != null) {
        storageError = null;
        notifyListeners();
      }
    } catch (_) {
      if (_key == key) {
        storageError =
            'Өзгерістерді сақтау мүмкін болмады. Құрылғы жадын тексеріңіз.';
        notifyListeners();
      }
    }
  }

  Future<void> flush() => _pending ?? Future<void>.value();
  void _clear() {
    name = 'Қонақ';
    email = '';
    reminders = false;
    storageError = null;
    favorites.clear();
    completed.clear();
    scores.clear();
    activity.clear();
    reviewDays.clear();
    certificates.clear();
    certificateArchive.clear();
    earnedBadges.clear();
  }

  Future<void> signOut() async {
    _clear();
    notifyListeners();
    await auth.clearSession();
  }
}
