import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soyle/features/notebook/data/remote_post.dart';
import 'package:soyle/features/notebook/data/remote_post_api.dart';

void main() {
  const owner = 'api-test@example.com';

  test('GET downloads posts and converts JSON to RemotePost models', () async {
    late http.Request request;
    final api = RemotePostApi(
      client: MockClient((value) async {
        request = value;
        return http.Response(
          jsonEncode([
            {'id': 4, 'userId': 1, 'title': 'Hello', 'body': 'World'},
          ]),
          200,
        );
      }),
    );

    final posts = await api.getPosts(owner);
    expect(request.method, 'GET');
    expect(request.url.path, '/posts');
    expect(request.url.queryParameters['userId'], '1');
    expect(posts.single, isA<RemotePost>());
    expect(posts.single.ownerId, owner);
    expect(posts.single.serverId, 4);
    expect(posts.single.title, 'Hello');
    api.close();
  });

  test('POST sends a new JSON record and parses the server response', () async {
    late http.Request request;
    final api = RemotePostApi(
      client: MockClient((value) async {
        request = value;
        return http.Response(
          jsonEncode({'id': 101, 'userId': 1, 'title': 'New', 'body': 'Text'}),
          201,
        );
      }),
    );

    final post = await api.createPost(
      ownerId: owner,
      localId: 'local-1',
      title: 'New',
      body: 'Text',
    );
    expect(request.method, 'POST');
    expect(request.url.path, '/posts');
    expect(jsonDecode(request.body), {
      'title': 'New',
      'body': 'Text',
      'userId': 1,
    });
    expect(post.serverId, 101);
    expect(post.localId, 'local-1');
    expect(post.syncState, RemotePostSyncState.created);
    api.close();
  });

  test('PUT updates an existing record', () async {
    late http.Request request;
    final api = RemotePostApi(
      client: MockClient((value) async {
        request = value;
        return http.Response(
          jsonEncode({
            'id': 4,
            'userId': 1,
            'title': 'Updated',
            'body': 'Body 2',
          }),
          200,
        );
      }),
    );
    const old = RemotePost(
      localId: 'server-4',
      ownerId: owner,
      serverId: 4,
      userId: 1,
      title: 'Old',
      body: 'Body',
    );

    final updated = await api.updatePost(old, title: 'Updated', body: 'Body 2');
    expect(request.method, 'PUT');
    expect(request.url.path, '/posts/4');
    expect(jsonDecode(request.body), {
      'id': 4,
      'title': 'Updated',
      'body': 'Body 2',
      'userId': 1,
    });
    expect(updated.title, 'Updated');
    expect(updated.syncState, RemotePostSyncState.updated);
    api.close();
  });

  test('DELETE sends the resource ID', () async {
    late http.Request request;
    final api = RemotePostApi(
      client: MockClient((value) async {
        request = value;
        return http.Response('', 200);
      }),
    );

    await api.deletePost(
      const RemotePost(
        localId: 'server-4',
        ownerId: owner,
        serverId: 4,
        userId: 1,
        title: 'Old',
        body: 'Body',
      ),
    );
    expect(request.method, 'DELETE');
    expect(request.url.path, '/posts/4');
    api.close();
  });

  test('HTTP server errors are reported separately', () async {
    final api = RemotePostApi(
      client: MockClient((_) async => http.Response('server error', 503)),
    );
    await expectLater(
      api.getPosts(owner),
      throwsA(
        isA<RestApiException>()
            .having((e) => e.failure, 'failure', RestApiFailure.server)
            .having((e) => e.statusCode, 'statusCode', 503),
      ),
    );
    api.close();
  });

  test('offline and invalid JSON errors are mapped', () async {
    final offline = RemotePostApi(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      offline.getPosts(owner),
      throwsA(
        isA<RestApiException>().having(
          (e) => e.failure,
          'failure',
          RestApiFailure.offline,
        ),
      ),
    );
    offline.close();

    final malformed = RemotePostApi(
      client: MockClient((_) async => http.Response('not json', 200)),
    );
    await expectLater(
      malformed.getPosts(owner),
      throwsA(
        isA<RestApiException>().having(
          (e) => e.failure,
          'failure',
          RestApiFailure.invalidData,
        ),
      ),
    );
    malformed.close();
  });

  test('request timeout is surfaced', () async {
    final completer = Completer<http.Response>();
    final api = RemotePostApi(
      client: MockClient((_) => completer.future),
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      api.getPosts(owner),
      throwsA(
        isA<RestApiException>().having(
          (e) => e.failure,
          'failure',
          RestApiFailure.timeout,
        ),
      ),
    );
    completer.complete(http.Response('[]', 200));
    api.close();
  });
}
