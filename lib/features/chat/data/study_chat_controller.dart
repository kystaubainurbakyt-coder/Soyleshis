import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/study_chat_message.dart';

enum StudyChatStatus { connecting, online, offline }

typedef StudyChatChannelFactory = WebSocketChannel Function(Uri uri);

Uri defaultStudyChatUri() {
  final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
  return Uri(scheme: 'ws', host: host, port: 8767);
}

class StudyChatController extends ChangeNotifier {
  StudyChatController({
    Uri? uri,
    StudyChatChannelFactory? channelFactory,
    this.connectTimeout = const Duration(seconds: 5),
    this.retryBaseDelay = const Duration(seconds: 2),
  }) : uri = uri ?? defaultStudyChatUri(),
       _channelFactory = channelFactory ?? WebSocketChannel.connect {
    connect();
  }

  final Uri uri;
  final StudyChatChannelFactory _channelFactory;
  final Duration connectTimeout;
  final Duration retryBaseDelay;
  final List<StudyChatMessage> messages = [];

  StudyChatStatus status = StudyChatStatus.offline;
  String? error;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _disposed = false;

  Future<void> connect() async {
    if (_disposed ||
        status == StudyChatStatus.connecting ||
        status == StudyChatStatus.online) {
      return;
    }
    _retryTimer?.cancel();
    status = StudyChatStatus.connecting;
    error = null;
    notifyListeners();

    WebSocketChannel channel;
    try {
      channel = _channelFactory(uri);
      _channel = channel;
      await channel.ready.timeout(connectTimeout);
    } catch (exception) {
      _markOffline(exception);
      return;
    }
    if (_disposed || !identical(_channel, channel)) return;

    status = StudyChatStatus.online;
    error = null;
    _retryAttempt = 0;
    notifyListeners();
    _subscription = channel.stream.listen(
      _receive,
      onDone: () => _lostConnection(channel),
      onError: (Object exception, StackTrace stackTrace) =>
          _lostConnection(channel, exception),
    );
  }

  bool send(String author, String text) {
    final cleanedAuthor = author.trim();
    final cleanedText = text.trim();
    final channel = _channel;
    if (status != StudyChatStatus.online || channel == null) return false;
    if (cleanedAuthor.isEmpty ||
        cleanedText.isEmpty ||
        cleanedText.length > 500) {
      error = 'invalidChatMessage';
      notifyListeners();
      return false;
    }
    try {
      channel.sink.add(
        jsonEncode({
          'type': 'chat',
          'author': cleanedAuthor,
          'text': cleanedText,
        }),
      );
      error = null;
      notifyListeners();
      return true;
    } catch (exception) {
      _markOffline(exception);
      return false;
    }
  }

  void _receive(dynamic raw) {
    try {
      final event = jsonDecode(raw as String);
      if (event is! Map) throw const FormatException('Invalid realtime event');
      switch (event['type']) {
        case 'history':
          final items = event['messages'];
          if (items is! List) {
            throw const FormatException('Invalid chat history');
          }
          messages
            ..clear()
            ..addAll(
              items.map(
                (item) => StudyChatMessage.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              ),
            );
          break;
        case 'chat':
        case 'announcement':
          final item = Map<String, dynamic>.from(event['message'] as Map);
          final message = StudyChatMessage.fromJson(item);
          if (!messages.any((existing) => existing.id == message.id)) {
            messages.add(message);
            if (messages.length > 100) messages.removeAt(0);
          }
          break;
        case 'error':
          error = event['message'] is String ? 'chatSendError' : null;
          break;
        default:
          throw const FormatException('Unknown realtime event');
      }
    } catch (exception) {
      error = 'chatDataError';
      debugPrint('SOYLE realtime event rejected: $exception');
    }
    notifyListeners();
  }

  void _lostConnection(WebSocketChannel channel, [Object? exception]) {
    if (!identical(_channel, channel) || _disposed) return;
    _channel = null;
    _subscription = null;
    _markOffline(exception);
  }

  void _markOffline(Object? exception) {
    if (_disposed) return;
    status = StudyChatStatus.offline;
    error = exception == null ? 'chatOffline' : 'chatConnectionError';
    debugPrint('SOYLE realtime connection offline: $exception');
    notifyListeners();
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_disposed || _retryTimer?.isActive == true) return;
    final multiplier = 1 << math.min(_retryAttempt, 4);
    _retryAttempt++;
    final delay = retryBaseDelay * multiplier;
    _retryTimer = Timer(delay, connect);
  }

  Future<void> retryNow() async {
    _retryTimer?.cancel();
    _retryAttempt = 0;
    if (status == StudyChatStatus.offline) {
      await connect();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
