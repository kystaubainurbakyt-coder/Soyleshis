class RemotePost {
  const RemotePost({
    required this.localId,
    required this.ownerId,
    required this.serverId,
    required this.userId,
    required this.title,
    required this.body,
    this.syncState = RemotePostSyncState.clean,
  });

  /// Local identity remains stable even when a demo API returns a fake ID.
  final String localId;
  final String ownerId;
  final int serverId;
  final int userId;
  final String title;
  final String body;
  final RemotePostSyncState syncState;

  factory RemotePost.fromJson(
    Map<String, dynamic> json, {
    required String ownerId,
  }) {
    final id = json['id'];
    final userId = json['userId'];
    if (id is! num ||
        userId is! num ||
        json['title'] is! String ||
        json['body'] is! String) {
      throw const FormatException('Invalid post JSON');
    }
    return RemotePost(
      localId: 'server-${id.toInt()}',
      ownerId: ownerId,
      serverId: id.toInt(),
      userId: userId.toInt(),
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  factory RemotePost.fromMap(Map<String, dynamic> map) => RemotePost(
    localId: map['localId'] as String,
    ownerId: map['ownerId'] as String,
    serverId: map['serverId'] as int,
    userId: map['userId'] as int,
    title: map['title'] as String,
    body: map['body'] as String,
    syncState: RemotePostSyncState.values.firstWhere(
      (state) => state.name == map['syncState'],
      orElse: () => RemotePostSyncState.clean,
    ),
  );

  factory RemotePost.created({
    required String localId,
    required String ownerId,
    required int serverId,
    required int userId,
    required String title,
    required String body,
  }) => RemotePost(
    localId: localId,
    ownerId: ownerId,
    serverId: serverId,
    userId: userId,
    title: title,
    body: body,
    syncState: RemotePostSyncState.created,
  );

  Map<String, dynamic> toMap() => {
    'localId': localId,
    'ownerId': ownerId,
    'serverId': serverId,
    'userId': userId,
    'title': title,
    'body': body,
    'syncState': syncState.name,
  };

  RemotePost copyWith({
    String? title,
    String? body,
    RemotePostSyncState? syncState,
  }) => RemotePost(
    localId: localId,
    ownerId: ownerId,
    serverId: serverId,
    userId: userId,
    title: title ?? this.title,
    body: body ?? this.body,
    syncState: syncState ?? this.syncState,
  );
}

enum RemotePostSyncState { clean, created, updated, deleted }
