import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/database/learning_repository.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';

void main() {
  late Directory directory;
  late LearningRepository repository;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('soyle-notebook-ui-');
    Hive.init(directory.path);
    repository = LearningRepository(Hive);
    await repository.initialize();
    AppState.instance.repository = repository;
    await AppState.instance.openAccount({
      'name': 'Anna',
      'email': 'notes@example.com',
    });
    await AppLocale.instance.setLanguage('en');
  });
  tearDown(() async {
    await AppState.instance.flush();
    AppState.instance.repository = null;
    await AppState.instance.signOut();
    await repository.close();
    expect(
      directory.absolute.path.startsWith(Directory.systemTemp.absolute.path),
      isTrue,
    );
    await directory.delete(recursive: true);
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        onGenerateInitialRoutes: (_) => [
          AppRoutes.onGenerateRoute(
            const RouteSettings(name: AppRoutes.notebook),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, tr('noteSave')),
    );
    await tester.runAsync(() async {
      final result = Function.apply(button.onPressed!, []);
      if (result is Future) await result;
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Learner creates, validates, edits, searches and confirms deletion of a personal note',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester);
      expect(find.text(tr('notesEmpty')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-note')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.text(tr('noteTitleError')), findsOneWidget);
      expect(find.text(tr('noteBodyError')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('note-title')),
        'My greeting',
      );
      await tester.enterText(
        find.byKey(const ValueKey('note-body')),
        'Practice this useful phrase tomorrow.',
      );
      await save(tester);
      expect(find.text('My greeting'), findsOneWidget);
      expect(repository.queryNotes('notes@example.com'), hasLength(1));
      await tester.tap(find.text(tr('editNote')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('note-title')),
        'Updated greeting',
      );
      await save(tester);
      expect(find.text('Updated greeting'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('notes-search')),
        'missing',
      );
      await tester.pumpAndSettle();
      expect(find.text(tr('noResults')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('notes-search')),
        'greeting',
      );
      await tester.pumpAndSettle();
      expect(find.text('Updated greeting'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text(tr('deleteNote')), findsOneWidget);
      await tester.tap(find.text(tr('noteCancel')));
      await tester.pumpAndSettle();
      expect(repository.queryNotes('notes@example.com'), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Database failure shows a clear retry state instead of an empty list',
    (tester) async {
      await tester.runAsync(() => repository.box('notes').close());
      await open(tester);
      expect(find.text(tr('databaseError')), findsOneWidget);
      expect(find.byKey(const ValueKey('add-note')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
