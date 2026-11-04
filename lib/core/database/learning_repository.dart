import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
import 'package:soyle/core/database/models/local_entities.dart';

class LocalDatabaseException implements Exception {
  const LocalDatabaseException(this.operation);
  final String operation;
}

/// Six entity collections. Primitive maps are a versioned, adapter-free Hive schema.
class LearningRepository {
  LearningRepository(this.hive);
  final HiveInterface hive;
  static String recordKey(String owner, Object id) =>
      sha256.convert(utf8.encode('$owner/$id')).toString();
  static const names = [
    'learners',
    'courses',
    'lessons',
    'notes',
    'favorites',
    'progress',
  ];
  Box<dynamic> box(String name) => hive.box<dynamic>('soyle_v4_$name');
  Future<T> protect<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on LocalDatabaseException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Hive $operation failed: $error\n$stackTrace');
      throw LocalDatabaseException(operation);
    }
  }

  Future<void> initialize() => protect('initialize', () async {
    for (final name in names) {
      await hive.openBox<dynamic>('soyle_v4_$name');
    }
    await hive.openBox<dynamic>('soyle_v4_remote_posts');
    for (final entry in LessonService.levels.asMap().entries) {
      await box('courses').put(
        entry.value,
        CourseRecord(id: entry.value, position: entry.key).toMap(),
      );
    }
    // Authored curriculum is always authoritative; personal notes stay separate.
    await box('lessons').putAll({
      for (final lesson in const LessonService().getLessons())
        lesson.id: lessonMap(lesson),
    });
    await box('lessons').flush();
  });
  static Future<LearningRepository> openFlutter() async {
    try {
      await Hive.initFlutter('soyle_v4');
      final repository = LearningRepository(Hive);
      await repository.initialize();
      return repository;
    } catch (error, stackTrace) {
      debugPrint('Hive startup failed: $error\n$stackTrace');
      throw const LocalDatabaseException('initialize');
    }
  }

  static Map<String, dynamic> lessonMap(Lesson l) => {
    'id': l.id,
    'title': l.title,
    'level': l.level,
    'description': l.description,
    'titleRu': l.titleRu,
    'titleEn': l.titleEn,
    'ruleRu': l.ruleRu,
    'ruleEn': l.ruleEn,
    'minutes': l.minutes,
    'words': [
      for (final w in l.words) {'kk': w.kk, 'ru': w.ru, 'en': w.en},
    ],
  };
  List<Lesson> readLessons() {
    try {
      return List.unmodifiable(
        box('lessons').values.map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return Lesson(
            id: m['id'] as int,
            title: m['title'] as String,
            level: m['level'] as String,
            description: m['description'] as String,
            titleRu: m['titleRu'] as String,
            titleEn: m['titleEn'] as String,
            ruleRu: m['ruleRu'] as String,
            ruleEn: m['ruleEn'] as String,
            minutes: m['minutes'] as int,
            icon: Icons.auto_stories_outlined,
            words: List.unmodifiable(
              (m['words'] as List).map(
                (v) => Word(
                  kk: v['kk'] as String,
                  ru: v['ru'] as String,
                  en: v['en'] as String,
                ),
              ),
            ),
          );
        }),
      );
    } catch (_) {
      throw const LocalDatabaseException('read');
    }
  }

  Map<String, dynamic>? readSnapshot(String owner) {
    try {
      final raw = box('learners').get(owner);
      if (raw == null) return null;
      final learner = LearnerRecord.fromMap(
        Map<String, dynamic>.from(raw as Map),
      );
      final favorites = box('favorites').values
          .map(
            (m) => FavoriteRecord.fromMap(Map<String, dynamic>.from(m as Map)),
          )
          .where((f) => f.ownerId == owner);
      final progress = box('progress').values
          .map(
            (m) => LessonProgressRecord.fromMap(
              Map<String, dynamic>.from(m as Map),
            ),
          )
          .where((p) => p.ownerId == owner)
          .toList();
      return {
        ...learner.learningData,
        'name': learner.name,
        'favorites': favorites.map((f) => f.lessonId).toList(),
        'completed': progress
            .where((p) => p.completed)
            .map((p) => p.lessonId)
            .toList(),
        'scores': {for (final p in progress) '${p.lessonId}': p.score},
      };
    } catch (_) {
      throw const LocalDatabaseException('read');
    }
  }

  Future<void> writeSnapshot(String owner, Map<String, dynamic> snapshot) =>
      protect('save', () async {
        if (owner.isEmpty) throw const LocalDatabaseException('account');
        final extras = Map<String, dynamic>.from(snapshot)
          ..remove('favorites')
          ..remove('completed')
          ..remove('scores')
          ..remove('name');
        final favorites = (snapshot['favorites'] as List).cast<int>();
        final completed = (snapshot['completed'] as List).cast<int>();
        final scores = Map<String, dynamic>.from(snapshot['scores'] as Map);
        final records = {
          for (final id in {...completed, ...scores.keys.map(int.parse)})
            recordKey(owner, id): LessonProgressRecord(
              ownerId: owner,
              lessonId: id,
              score: (scores['$id'] as int?) ?? 0,
              completed: completed.contains(id),
            ).toMap(),
        };
        final favs = {
          for (final id in favorites)
            recordKey(owner, id): FavoriteRecord(
              ownerId: owner,
              lessonId: id,
            ).toMap(),
        };
        for (final entry in {'favorites': favs, 'progress': records}.entries) {
          final collection = box(entry.key);
          final obsolete = collection.keys
              .where(
                (key) =>
                    (collection.get(key) as Map)['ownerId'] == owner &&
                    !entry.value.containsKey(key),
              )
              .toList();
          await collection.putAll(entry.value);
          await collection.deleteAll(obsolete);
        }
        await box('learners').put(
          owner,
          LearnerRecord(
            id: owner,
            name: snapshot['name'] as String,
            learningData: extras,
          ).toMap(),
        );
        for (final name in ['learners', 'favorites', 'progress']) {
          await box(name).flush();
        }
      });
  List<StudyNote> queryNotes(
    String owner, {
    String query = '',
    String? level,
    int? lessonId,
    bool favoritesOnly = false,
    NoteSort sort = NoteSort.updated,
  }) {
    try {
      final lessonIds = readLessons()
          .where((l) => level == null || l.level == level)
          .map((l) => l.id)
          .toSet();
      final needle = query.toLowerCase().trim();
      final notes = box('notes').values
          .map((m) => StudyNote.fromMap(Map<String, dynamic>.from(m as Map)))
          .where(
            (n) =>
                n.ownerId == owner &&
                lessonIds.contains(n.lessonId) &&
                (lessonId == null || n.lessonId == lessonId) &&
                (!favoritesOnly || n.favorite) &&
                '${n.title} ${n.body}'.toLowerCase().contains(needle),
          )
          .toList();
      notes.sort((a, b) {
        final result = switch (sort) {
          NoteSort.title => a.title.toLowerCase().compareTo(
            b.title.toLowerCase(),
          ),
          NoteSort.priority => b.priority.compareTo(a.priority),
          NoteSort.updated => b.updatedAt.compareTo(a.updatedAt),
        };
        return result != 0 ? result : a.id.compareTo(b.id);
      });
      return List.unmodifiable(notes);
    } catch (_) {
      throw const LocalDatabaseException('read');
    }
  }

  Future<StudyNote> saveNote(
    String owner, {
    String? id,
    required int lessonId,
    required String title,
    required String body,
    int priority = 1,
    bool favorite = false,
  }) => protect('save', () async {
    if (owner.isEmpty ||
        !box('learners').containsKey(owner) ||
        title.trim().length < 3 ||
        title.trim().length > 80 ||
        body.trim().isEmpty ||
        body.trim().length > 2000 ||
        priority < 1 ||
        priority > 3 ||
        !box('lessons').containsKey(lessonId)) {
      throw const LocalDatabaseException('validation');
    }
    StudyNote? previous;
    if (id != null) {
      final raw = box('notes').get(recordKey(owner, id));
      if (raw == null) throw const LocalDatabaseException('notFound');
      previous = StudyNote.fromMap(Map<String, dynamic>.from(raw as Map));
      if (previous.ownerId != owner) {
        throw const LocalDatabaseException('account');
      }
    }
    final now = DateTime.now();
    final note = StudyNote(
      id:
          id ??
          List.generate(
            16,
            (_) =>
                Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join(),
      ownerId: owner,
      lessonId: lessonId,
      title: title.trim(),
      body: body.trim(),
      priority: priority,
      favorite: favorite,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    await box('notes').put(recordKey(owner, note.id), note.toMap());
    await box('notes').flush();
    return note;
  });
  Future<void> deleteNote(String owner, String id) =>
      protect('delete', () async {
        if (!box('notes').containsKey(recordKey(owner, id))) {
          throw const LocalDatabaseException('notFound');
        }
        await box('notes').delete(recordKey(owner, id));
        await box('notes').flush();
      });
  Future<void> close() async {
    for (final name in [...names, 'remote_posts']) {
      if (hive.isBoxOpen('soyle_v4_$name')) await box(name).close();
    }
  }
}
