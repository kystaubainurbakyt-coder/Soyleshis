// Real PBKDF2 hashes are intentionally expensive, especially during release builds.
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soyle/features/auth/data/auth_service.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/auth/domain/auth_validators.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppState.instance.signOut();
  });
  test('Email rejects missing @, malformed domains and spaces', () {
    for (final email in [
      '',
      'namegmail.com',
      'name@gmail',
      'name@@gmail.com',
      'name@ gmail.com',
      'name@gmail..com',
      '.name@gmail.com',
      'name.@gmail.com',
      'name@gmail.c',
      'name@-gmail.com',
    ]) {
      expect(AuthValidators.email(email), isNotNull, reason: email);
    }
    for (final email in [
      'name@gmail.com',
      'Student.Name+kk@example.org',
      ' name@gmail.com ',
    ]) {
      expect(AuthValidators.email(email), isNull, reason: email);
    }
  });
  test('Password needs six characters and an uppercase letter', () {
    for (final password in ['', '123456', 'abcdef', 'Abc12', 'Abc 123']) {
      expect(AuthValidators.password(password), isNotNull, reason: password);
    }
    for (final password in ['Abc123', 'Қазақ1', 'Үйрену7']) {
      expect(AuthValidators.password(password), isNull);
    }
  });
  test(
    'Registration, duplicate rejection, wrong password, restart and correct login',
    () async {
      final auth = AuthService();
      final account = await auth.register(
        'Айдана',
        'Student@Gmail.com',
        'Password1',
      );
      expect(account['email'], 'student@gmail.com');
      await expectLater(
        auth.register('Басқа', ' student@gmail.com ', 'Password1'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        auth.login('student@gmail.com', 'WrongPass1'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        auth.login('unknown@gmail.com', 'Password1'),
        throwsA(isA<AuthException>()),
      );
      final saved = await const FlutterSecureStorage().read(
        key: 'soyle.accounts.v1',
      );
      expect(saved, isNot(contains('Password1')));
      final raw = jsonDecode(saved!) as Map;
      expect(raw['student@gmail.com']['salt'], isNotEmpty);
      expect(raw['student@gmail.com']['hash'], isNotEmpty);
      final restored = await AuthService().login(
        'STUDENT@gmail.com',
        'Password1',
      );
      expect(restored['name'], 'Айдана');
    },
  );
  test('Repeated failed logins are temporarily blocked', () async {
    final auth = AuthService();
    for (var i = 0; i < 5; i++) {
      await expectLater(
        auth.login('absent@gmail.com', 'Password1'),
        throwsA(isA<AuthException>()),
      );
    }
    await expectLater(
      auth.login('absent@gmail.com', 'Password1'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          equals('tooManyLoginAttempts'),
        ),
      ),
    );
  });
  test(
    'Progress persists across logout and is isolated between accounts',
    () async {
      final state = AppState.instance;
      final first = await state.auth.register(
        'Бірінші',
        'first@gmail.com',
        'Password1',
      );
      await state.openAccount(first);
      state.update(() {
        state.favorites.add(1);
        state.completed.add(1);
        state.scores[1] = 100;
        state.name = 'Жаңа ат';
      });
      await state.flush();
      await state.signOut();
      expect(state.authenticated, isFalse);
      final second = await state.auth.register(
        'Екінші',
        'second@gmail.com',
        'Password2',
      );
      await state.openAccount(second);
      expect(state.completed, isEmpty);
      expect(state.favorites, isEmpty);
      await state.signOut();
      await state.openAccount(
        await state.auth.login('first@gmail.com', 'Password1'),
      );
      expect(state.completed, contains(1));
      expect(state.favorites, contains(1));
      expect(state.scores[1], 100);
      expect(state.name, 'Жаңа ат');
    },
  );
  test('Every built-in lesson has teaching content and valid exercises', () {
    final lessons = const LessonService().getLessons();
    expect(lessons.length, 75);
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
    for (final lesson in lessons) {
      final material = LessonMaterial.forLesson(lesson);
      expect(material.rule.length, greaterThan(60), reason: lesson.title);
      expect(material.dialogue.length, 4, reason: lesson.title);
      expect(material.examples.length, 3, reason: lesson.title);
      final questions = material.questions(lesson);
      expect(questions.length, 8);
      for (final q in questions) {
        expect(q.answer, inInclusiveRange(0, q.options.length - 1));
        expect(q.options.toSet().length, q.options.length);
      }
    }
  });
}
