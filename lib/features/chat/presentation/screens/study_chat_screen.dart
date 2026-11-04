import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/chat/data/study_chat_controller.dart';
import 'package:soyle/features/chat/domain/study_chat_message.dart';

class StudyChatScreen extends StatefulWidget {
  const StudyChatScreen({super.key, this.controller});

  final StudyChatController? controller;

  @override
  State<StudyChatScreen> createState() => _StudyChatScreenState();
}

class _StudyChatScreenState extends State<StudyChatScreen> {
  late final StudyChatController controller;
  late final bool ownsController;
  final input = TextEditingController();

  @override
  void initState() {
    super.initState();
    ownsController = widget.controller == null;
    controller = widget.controller ?? StudyChatController();
  }

  @override
  void dispose() {
    input.dispose();
    if (ownsController) controller.dispose();
    super.dispose();
  }

  void send() {
    if (controller.send(AppState.instance.name, input.text)) input.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('studyRoom')),
      actions: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(child: _ConnectionBadge(status: controller.status)),
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.status == StudyChatStatus.offline &&
                      controller.messages.isEmpty) {
                    return _OfflinePanel(
                      error: controller.error,
                      onRetry: controller.retryNow,
                    );
                  }
                  if (controller.messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.forum_outlined, size: 42),
                            const SizedBox(height: 12),
                            Text(
                              tr('chatWelcome'),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller
                          .messages[controller.messages.length - 1 - index];
                      return _MessageBubble(message: message);
                    },
                  );
                },
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Column(
                children: [
                  if (controller.error != null &&
                      controller.status == StudyChatStatus.online)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tr(controller.error!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: input,
                              enabled:
                                  controller.status == StudyChatStatus.online,
                              maxLength: 500,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => send(),
                              decoration: InputDecoration(
                                hintText: tr('chatInputHint'),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            tooltip: tr('chatSend'),
                            onPressed:
                                controller.status == StudyChatStatus.online
                                ? send
                                : null,
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.status});

  final StudyChatStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StudyChatStatus.connecting => (tr('chatConnecting'), Colors.orange),
      StudyChatStatus.online => (tr('chatOnline'), Colors.green),
      StudyChatStatus.offline => (tr('chatOffline'), Colors.red),
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _OfflinePanel extends StatelessWidget {
  const _OfflinePanel({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 16),
          Text(tr(error ?? 'chatOffline'), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(tr('chatReconnectHint'), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('retry')),
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final StudyChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isAnnouncement) {
      return Card(
        color: AppColors.soft,
        margin: const EdgeInsets.symmetric(vertical: 7),
        child: ListTile(
          leading: const Icon(Icons.campaign_outlined),
          title: Text(tr('adminAnnouncement')),
          subtitle: Text(message.text),
        ),
      );
    }
    final mine = message.author == AppState.instance.name;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? AppColors.soft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.author,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(message.text),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                message.createdAt.toLocal().toString().substring(11, 16),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
