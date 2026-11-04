import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'remote_post.dart';

enum RestApiFailure { offline, timeout, server, invalidData, request }

class RestApiException implements Exception {
  const RestApiException(this.failure, [this.statusCode]);
  final RestApiFailure failure;
  final int? statusCode;
}

/// JSONPlaceholder REST client used by the notebook API exercise.
class RemotePostApi {
  RemotePostApi({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static final Uri _postsUri = Uri.https(
    'jsonplaceholder.typicode.com',
    '/posts',
  );
  static const int demoUserId = 1;
  final http.Client _client;
  final Duration timeout;

  Future<List<RemotePost>> getPosts(String ownerId) async {
    final response = await _send(
      () => _client.get(
        _postsUri.replace(queryParameters: {'userId': '$demoUserId'}),
      ),
    );
    if (response.statusCode != 200) _throwStatus(response.statusCode);
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException('Expected a list');
      return List.unmodifiable(
        decoded.map((item) {
          if (item is! Map) throw const FormatException('Expected a post');
          return RemotePost.fromJson(
            Map<String, dynamic>.from(item),
            ownerId: ownerId,
          );
        }),
      );
    } on FormatException {
      throw const RestApiException(RestApiFailure.invalidData);
    } on TypeError {
      throw const RestApiException(RestApiFailure.invalidData);
    }
  }

  Future<RemotePost> createPost({
    required String ownerId,
    required String localId,
    required String title,
    required String body,
    int userId = demoUserId,
  }) async {
    final response = await _send(
      () => _client.post(
        _postsUri,
        headers: _headers,
        body: jsonEncode({'title': title, 'body': body, 'userId': userId}),
      ),
    );
    if (response.statusCode != 201) _throwStatus(response.statusCode);
    try {
      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
      final post = RemotePost.fromJson(decoded, ownerId: ownerId);
      return RemotePost.created(
        localId: localId,
        ownerId: ownerId,
        serverId: post.serverId,
        userId: post.userId,
        title: post.title,
        body: post.body,
      );
    } on RestApiException {
      rethrow;
    } on Object {
      throw const RestApiException(RestApiFailure.invalidData);
    }
  }

  Future<RemotePost> updatePost(
    RemotePost post, {
    required String title,
    required String body,
  }) async {
    final response = await _send(
      () => _client.put(
        _postUri(post.serverId),
        headers: _headers,
        body: jsonEncode({
          'id': post.serverId,
          'title': title,
          'body': body,
          'userId': post.userId,
        }),
      ),
    );
    if (response.statusCode != 200) _throwStatus(response.statusCode);
    try {
      final decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
      final updated = RemotePost.fromJson(decoded, ownerId: post.ownerId);
      return RemotePost(
        localId: post.localId,
        ownerId: post.ownerId,
        serverId: updated.serverId,
        userId: updated.userId,
        title: updated.title,
        body: updated.body,
        syncState: post.syncState == RemotePostSyncState.created
            ? RemotePostSyncState.created
            : RemotePostSyncState.updated,
      );
    } on RestApiException {
      rethrow;
    } on Object {
      throw const RestApiException(RestApiFailure.invalidData);
    }
  }

  Future<void> deletePost(RemotePost post) async {
    final response = await _send(() => _client.delete(_postUri(post.serverId)));
    if (response.statusCode != 200 && response.statusCode != 204) {
      _throwStatus(response.statusCode);
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on RestApiException {
      rethrow;
    } on TimeoutException {
      throw const RestApiException(RestApiFailure.timeout);
    } on http.ClientException {
      throw const RestApiException(RestApiFailure.offline);
    } on FormatException {
      throw const RestApiException(RestApiFailure.invalidData);
    } catch (_) {
      throw const RestApiException(RestApiFailure.request);
    }
  }

  static Uri _postUri(int id) =>
      Uri.https('jsonplaceholder.typicode.com', '/posts/$id');
  static const _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  Never _throwStatus(int statusCode) {
    if (statusCode >= 500) {
      throw RestApiException(RestApiFailure.server, statusCode);
    }
    throw RestApiException(RestApiFailure.request, statusCode);
  }

  void close() => _client.close();
}
