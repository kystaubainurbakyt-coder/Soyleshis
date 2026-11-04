import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soyle/core/database/learning_repository.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/notebook/presentation/screens/rest_api_screen.dart';
import 'package:soyle/features/notebook/data/remote_post_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LearningRepository repository;
  const owner = 'rest-ui@example.com';

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('soyle-rest-ui-');
    Hive.init(directory.path);
    repository = LearningRepository(Hive);
    await repository.initialize();
    AppState.instance.repository = repository;
    AppState.instance.email = owner;
    await AppLocale.instance.setLanguage('en');
  });

  tearDown(() async {
    AppState.instance.repository = null;
    await AppState.instance.signOut();
    await repository.close();
    expect(
      directory.absolute.path.startsWith(Directory.systemTemp.absolute.path),
      isTrue,
    );
    await directory.delete(recursive: true);
  });

  testWidgets(
    'GET, POST, PUT and DELETE update the screen and Hive account cache',
    (tester) async {
      var getCount = 0;
      final api = RemotePostApi(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            getCount++;
            return http.Response(
              jsonEncode([
                {
                  'id': 1,
                  'userId': 1,
                  'title': 'Server post',
                  'body': 'From GET',
                },
              ]),
              200,
            );
          }
          if (request.method == 'POST') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(jsonEncode({...body, 'id': 101}), 201);
          }
          if (request.method == 'PUT') return http.Response(request.body, 200);
          if (request.method == 'DELETE') return http.Response('', 200);
          return http.Response('unsupported', 405);
        }),
      );
      addTearDown(api.close);

      await tester.pumpWidget(
        MaterialApp(home: RestApiScreen(apiOverride: api)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Server post'), findsOneWidget);

      await tester.tap(find.text(tr('apiAdd')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('api-post-title')),
        'Created post',
      );
      await tester.enterText(
        find.byKey(const ValueKey('api-post-body')),
        'Created body',
      );
      await tester.tap(find.text(tr('noteSave')));
      await tester.pumpAndSettle();
      expect(find.text('Created post'), findsOneWidget);

      await tester.tap(find.byTooltip(tr('editNote')).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('api-post-title')),
        'Updated post',
      );
      await tester.enterText(
        find.byKey(const ValueKey('api-post-body')),
        'Updated body',
      );
      await tester.tap(find.text(tr('noteSave')));
      await tester.pumpAndSettle();
      expect(find.text('Updated post'), findsOneWidget);

      await tester.tap(find.byTooltip(tr('noteDelete')).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr('noteDelete')));
      await tester.pumpAndSettle();
      expect(find.text('Updated post'), findsNothing);

      await tester.tap(find.byTooltip(tr('apiRefresh')));
      await tester.pumpAndSettle();
      expect(getCount, 2);
      expect(find.text('Server post'), findsOneWidget);
      expect(find.text('Updated post'), findsNothing);
      final cached = repository.hive
          .box<dynamic>('soyle_v4_remote_posts')
          .values
          .map((value) => Map<String, dynamic>.from(value as Map))
          .where((value) => value['ownerId'] == owner)
          .toList();
      expect(cached, hasLength(2));
      expect(cached.any((value) => value['syncState'] == 'deleted'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
