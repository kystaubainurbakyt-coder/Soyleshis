import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';

class SentenceLabScreen extends StatefulWidget {
  const SentenceLabScreen({super.key});
  @override
  State<SentenceLabScreen> createState() => _SentenceLabScreenState();
}

class _SentenceLabScreenState extends State<SentenceLabScreen> {
  int sentence = 0;
  final selected = <int>[];
  bool checked = false;
  @override
  Widget build(BuildContext context) {
    final lesson = ModalRoute.of(context)?.settings.arguments;
    if (lesson is! Lesson) {
      return Scaffold(body: Center(child: Text(tr('notFound'))));
    }
    final phrase = lesson.words[sentence];
    final words = phrase.kk.split(' ').reversed.toList();
    final answer = selected.map((i) => words[i]).join(' ');
    final correct = answer == phrase.kk;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('sentenceBuilder')),
        actions: const [LanguageSwitch(), SizedBox(width: 16)],
      ),
      body: AdaptiveContent(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              tr('sentenceHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 26),
            Text(
              phrase.translation,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 22),
            Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in selected)
                    InputChip(
                      label: Text(words[i]),
                      onDeleted: () => setState(() {
                        selected.remove(i);
                        checked = false;
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (var i = 0; i < words.length; i++)
                  if (!selected.contains(i))
                    ActionChip(
                      label: Text(words[i]),
                      onPressed: () => setState(() {
                        selected.add(i);
                        checked = false;
                      }),
                    ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: selected.length != words.length
                  ? null
                  : () => setState(() => checked = true),
              child: Text(tr('checkSentence')),
            ),
            if (checked) ...[
              const SizedBox(height: 20),
              Text(
                tr(correct ? 'correct' : 'incorrect'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(phrase.kk, style: const TextStyle(height: 1.7)),
              if (correct)
                TextButton(
                  onPressed: () => setState(() {
                    sentence = (sentence + 1) % lesson.words.length;
                    selected.clear();
                    checked = false;
                  }),
                  child: Text(tr('next')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
