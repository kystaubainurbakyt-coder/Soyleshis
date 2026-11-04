import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:soyle/core/database/learning_repository.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/database/models/local_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LearningRepository repository;
  const owner = 'anna@example.com';
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('soyle-v4-');
    Hive.init(directory.path);
    repository = LearningRepository(Hive);
    await repository.initialize();
    await repository.writeSnapshot(owner, {
      'name': 'Anna',
      'favorites': <int>[],
      'completed': <int>[],
      'scores': <String, int>{},
    });
  });
  tearDown(() async {
    await repository.close();
    final root = Directory.systemTemp.absolute.path;
    expect(directory.absolute.path.startsWith(root), isTrue);
    await directory.delete(recursive: true);
  });
  test(
    'Six collections persist the curriculum and its course relationships',
    () {
      expect(LearningRepository.names, hasLength(6));
      final lessons = repository.readLessons();
      expect(lessons, hasLength(75));
      expect(repository.box('courses').length, 5);
      for (final lesson in lessons) {
        expect(repository.box('courses').containsKey(lesson.level), isTrue);
        expect(lesson.words, hasLength(6));
      }
    },
  );
  test(
    'Offline CRUD survives close and reopen and is isolated by account',
    () async {
      final lesson = repository.readLessons().first;
      final note = await repository.saveNote(
        owner,
        lessonId: lesson.id,
        title: 'Useful greeting',
        body: 'Remember this phrase',
        priority: 2,
      );
      expect(repository.queryNotes(owner).single.id, note.id);
      expect(repository.queryNotes('other@example.com'), isEmpty);
      final edited = await repository.saveNote(
        owner,
        id: note.id,
        lessonId: lesson.id,
        title: 'Updated greeting',
        body: 'Updated example',
        favorite: true,
        priority: 3,
      );
      expect(edited.createdAt, note.createdAt);
      await repository.close();
      Hive.init(directory.path);
      repository = LearningRepository(Hive);
      await repository.initialize();
      final restored = repository.queryNotes(owner).single;
      expect(restored.title, 'Updated greeting');
      expect(restored.favorite, isTrue);
      expect(restored.priority, 3);
      await expectLater(
        repository.deleteNote('other@example.com', note.id),
        throwsA(isA<LocalDatabaseException>()),
      );
      expect(repository.queryNotes(owner), hasLength(1));
      await repository.deleteNote(owner, note.id);
      await repository.close();
      Hive.init(directory.path);
      repository = LearningRepository(Hive);
      await repository.initialize();
      expect(repository.queryNotes(owner), isEmpty);
    },
  );
  test(
    'Search, level, favorite and lesson filters combine with three sorts',
    () async {
      final a1 = repository.readLessons().firstWhere((l) => l.level == 'A1');
      final a2 = repository.readLessons().firstWhere((l) => l.level == 'A2');
      final first = await repository.saveNote(
        owner,
        lessonId: a1.id,
        title: 'Zebra',
        body: 'Important EXAMPLE',
        favorite: true,
        priority: 3,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.saveNote(
        owner,
        lessonId: a2.id,
        title: 'Alpha',
        body: 'Cafe example',
        priority: 1,
      );
      expect(repository.queryNotes(owner, query: 'EXAMPLE'), hasLength(2));
      expect(
        repository
            .queryNotes(owner, level: 'A1', favoritesOnly: true)
            .single
            .id,
        first.id,
      );
      expect(
        repository.queryNotes(owner, lessonId: a2.id).single.title,
        'Alpha',
      );
      expect(
        repository.queryNotes(owner, sort: NoteSort.title).first.title,
        'Alpha',
      );
      expect(
        repository.queryNotes(owner, sort: NoteSort.priority).first.title,
        'Zebra',
      );
      expect(
        repository.queryNotes(owner, sort: NoteSort.updated).first.title,
        'Alpha',
      );
      expect(repository.queryNotes(owner, query: 'missing'), isEmpty);
    },
  );
  test(
    'Invalid input, missing relations, foreign updates and storage failures are explicit',
    () async {
      for (final input in [('', 7), ('Valid title', -1)]) {
        await expectLater(
          repository.saveNote(
            owner,
            lessonId: input.$2,
            title: input.$1,
            body: 'Example',
          ),
          throwsA(isA<LocalDatabaseException>()),
        );
      }
      final note = await repository.saveNote(
        owner,
        lessonId: repository.readLessons().first.id,
        title: 'My note',
        body: 'Example',
      );
      await expectLater(
        repository.saveNote(
          'other@example.com',
          id: note.id,
          lessonId: note.lessonId,
          title: 'Override',
          body: 'Invalid',
        ),
        throwsA(isA<LocalDatabaseException>()),
      );
      await repository.box('notes').close();
      expect(
        () => repository.queryNotes(owner),
        throwsA(isA<LocalDatabaseException>()),
      );
      await expectLater(
        repository.saveNote(
          owner,
          lessonId: note.lessonId,
          title: 'New note',
          body: 'Example',
        ),
        throwsA(isA<LocalDatabaseException>()),
      );
    },
  );
  test(
    'Legacy secure-storage progress migrates to Hive with favorites and restart persistence',
    () async {
      final id = repository.readLessons().first.id;
      await const FlutterSecureStorage().write(
        key: 'soyle.progress.v1.$owner',
        value: jsonEncode({
          'name': 'Anna',
          'favorites': [id],
          'completed': [id],
          'scores': {'$id': 85},
        }),
      );
      await repository.box('learners').delete(owner);
      final state = AppState()..repository = repository;
      await state.openAccount({'name': 'Anna', 'email': owner});
      expect(state.favorites, contains(id));
      expect(repository.readSnapshot(owner)!['scores'], {'$id': 85});
      state.update(() {
        state.favorites.clear();
        state.name = 'Anna Updated';
      });
      await state.flush();
      expect(state.storageError, isNull);
      await repository.close();
      Hive.init(directory.path);
      repository = LearningRepository(Hive);
      await repository.initialize();
      final restored = AppState()..repository = repository;
      await restored.openAccount({'name': 'Anna', 'email': owner});
      expect(restored.favorites, isEmpty);
      expect(restored.name, 'Anna Updated');
      expect(restored.scores[id], 85);
      final other = AppState()..repository = repository;
      await other.openAccount({'name': 'Other', 'email': 'other@example.com'});
      expect(other.completed, isEmpty);
      expect(other.favorites, isEmpty);
      await other.flush();
      await restored.flush();
      state.dispose();
      restored.dispose();
      other.dispose();
    },
  );
}
