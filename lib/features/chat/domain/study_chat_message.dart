class StudyChatMessage {
  const StudyChatMessage({
    required this.id,
    required this.type,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String author;
  final String text;
  final DateTime createdAt;

  bool get isAnnouncement => type == 'announcement';

  factory StudyChatMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final author = json['author'];
    final text = json['text'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        !['chat', 'announcement'].contains(type) ||
        author is! String ||
        text is! String ||
        createdAt is! String) {
      throw const FormatException('Invalid study chat message');
    }
    return StudyChatMessage(
      id: id,
      type: type as String,
      author: author,
      text: text,
      createdAt: DateTime.parse(createdAt),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'type': type,
    'author': author,
    'text': text,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}
