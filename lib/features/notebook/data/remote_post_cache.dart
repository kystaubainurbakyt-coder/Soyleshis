import 'package:hive_ce_flutter/hive_flutter.dart';

import 'remote_post.dart';

/// Device cache joined to a signed-in SOYLE account.
class RemotePostCache {
  const RemotePostCache(this._box);
  final Box<dynamic> _box;

  List<RemotePost> read(String ownerId) => List.unmodifiable(
    _box.values
        .map(
          (value) =>
              RemotePost.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .where(
          (post) =>
              post.ownerId == ownerId &&
              post.syncState != RemotePostSyncState.deleted,
        ),
  );

  Future<void> save(RemotePost post) async {
    await _box.put(_key(post.ownerId, post.localId), post.toMap());
    await _box.flush();
  }

  Future<void> delete(RemotePost post) =>
      save(post.copyWith(syncState: RemotePostSyncState.deleted));

  /// Updates the local snapshot while preserving local CRUD overlays because
  /// JSONPlaceholder fakes writes rather than persisting them on the server.
  Future<List<RemotePost>> mergeServerSnapshot(
    String ownerId,
    List<RemotePost> serverPosts,
  ) async {
    final local = readIncludingDeleted(ownerId);
    final overlays = local.where(
      (post) => post.syncState != RemotePostSyncState.clean,
    );
    final overlayByServerId = {
      for (final post in overlays) post.serverId: post,
    };
    final result = <RemotePost>[];

    for (final serverPost in serverPosts) {
      final overlay = overlayByServerId[serverPost.serverId];
      if (overlay?.syncState == RemotePostSyncState.deleted) continue;
      final post = overlay ?? serverPost;
      result.add(post);
      if (overlay == null) await save(serverPost);
    }

    for (final post in overlays) {
      if (post.syncState == RemotePostSyncState.created &&
          !result.any((item) => item.localId == post.localId)) {
        result.add(post);
      }
    }
    return List.unmodifiable(result);
  }

  List<RemotePost> readIncludingDeleted(String ownerId) => List.unmodifiable(
    _box.values
        .map(
          (value) =>
              RemotePost.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .where((post) => post.ownerId == ownerId),
  );

  static String _key(String ownerId, String localId) => '$ownerId/$localId';
}
