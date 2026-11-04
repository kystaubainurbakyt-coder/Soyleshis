import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/primary_button.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<Word> queue;
  late final int total;
  int mastered = 0, reward = 0;
  bool revealed = false, finished = false;
  @override
  void initState() {
    super.initState();
    final state = AppState.instance;
    final preferred = state.lessons.where(
      (l) => state.favorites.contains(l.id) || state.completed.contains(l.id),
    );
    final seen = <String>{};
    queue = [
      ...preferred.expand((l) => l.words),
      ...state.lessons.expand((l) => l.words),
    ].where((w) => seen.add(w.kk.toLowerCase())).take(12).toList();
    total = queue.length;
  }

  void answer(bool known) {
    if (!revealed || queue.isEmpty) return;
    setState(() {
      final word = queue.removeAt(0);
      if (known) {
        mastered++;
      } else {
        queue.add(word);
      }
      revealed = false;
      if (queue.isEmpty) {
        finished = true;
        reward = AppState.instance.finishReview();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('review')),
      actions: const [LanguageSwitch(), SizedBox(width: 18)],
    ),
    body: AdaptiveContent(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (finished || queue.isEmpty) ...[
            const SizedBox(height: 35),
            const Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: AppColors.accent,
            ),
            const SizedBox(height: 24),
            Text(
              tr('reviewDone'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              tr('reviewResult', {'n': mastered, 'xp': reward}),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              tr(reward == 0 ? 'bonusClaimed' : 'bonusEarned'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: tr('done'),
              onPressed: () => Navigator.pop(context),
            ),
          ] else ...[
            Text(
              tr('reviewTitle'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            Text(
              tr('reviewInstructions'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text(
              tr('mastered', {'done': mastered, 'total': total}),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: mastered / total,
              minHeight: 5,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 24),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => revealed = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(minHeight: 260),
                decoration: BoxDecoration(
                  color: revealed ? const Color(0xFF244E5C) : AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey(
                      '${queue.first.kk}-$revealed-${AppLocale.instance.language}',
                    ),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('kazakh'),
                        style: const TextStyle(
                          color: Color(0xFFD7C5A3),
                          fontSize: 10,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        queue.first.kk,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        revealed ? queue.first.translation : tr('tapReveal'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD4DFE7),
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!revealed)
              PrimaryButton(
                label: tr('showTranslation'),
                onPressed: () => setState(() => revealed = true),
              )
            else ...[
              PrimaryButton(
                label: tr('know'),
                icon: Icons.check_rounded,
                onPressed: () => answer(true),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => answer(false),
                icon: const Icon(Icons.replay_rounded),
                label: Text(tr('again')),
              ),
            ],
          ],
        ],
      ),
    ),
  );
}
