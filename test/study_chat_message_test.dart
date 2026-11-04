import 'package:flutter_test/flutter_test.dart';
import 'package:soyle/features/chat/data/study_chat_controller.dart';
import 'package:soyle/features/chat/domain/study_chat_message.dart';

void main() {
  final sentAt = DateTime.utc(2026, 11, 4, 12, 30);

  test('parses a normal chat message from the WebSocket server', () {
    final message = StudyChatMessage.fromJson({
      'id': 'abc123',
      'type': 'chat',
      'author': 'Айдана',
      'text': 'Сәлем!',
      'createdAt': sentAt.toIso8601String(),
    });
    expect(message.author, 'Айдана');
    expect(message.text, 'Сәлем!');
    expect(message.isAnnouncement, isFalse);
  });

  test('recognizes administrator announcements separately from chat', () {
    final message = StudyChatMessage.fromJson({
      'id': 'notice1',
      'type': 'announcement',
      'author': 'SOYLE',
      'text': 'Жаңа сабақ дайын.',
      'createdAt': sentAt.toIso8601String(),
    });
    expect(message.isAnnouncement, isTrue);
  });

  test('serializes and parses a message without losing its timestamp', () {
    final original = StudyChatMessage(
      id: 'roundtrip',
      type: 'chat',
      author: 'Student',
      text: 'Hello',
      createdAt: sentAt,
    );
    final parsed = StudyChatMessage.fromJson(original.toJson());
    expect(parsed.toJson(), original.toJson());
  });

  test('rejects unsupported event types', () {
    expect(
      () => StudyChatMessage.fromJson({
        'id': 'x',
        'type': 'command',
        'author': 'Student',
        'text': 'run',
        'createdAt': sentAt.toIso8601String(),
      }),
      throwsFormatException,
    );
  });

  test('rejects messages missing an id, author, or timestamp', () {
    expect(
      () => StudyChatMessage.fromJson({'type': 'chat', 'text': 'Hello'}),
      throwsFormatException,
    );
  });

  test('builds a WebSocket endpoint on the app host and service port', () {
    final endpoint = defaultStudyChatUri();
    expect(endpoint.scheme, 'ws');
    expect(endpoint.host, isNotEmpty);
    expect(endpoint.port, 8767);
  });
}
