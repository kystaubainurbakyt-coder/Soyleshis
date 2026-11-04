import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/learning_artwork.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.lesson, required this.onTap});
  final Lesson lesson;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final passed = AppState.instance.completed.contains(lesson.id);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: AppState.instance.levelUnlocked(lesson.level)
            ? onTap
            : () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(tr('levelLocked')))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              LearningArtwork(
                style: LearningArtworkStyle
                    .values[lesson.id % LearningArtworkStyle.values.length],
                size: 66,
                background: LevelMark.color(lesson.level).withValues(alpha: .1),
                accent: LevelMark.color(lesson.level),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${tr('minutes', {'n': lesson.minutes})}  ·  ${passed ? tr('completed') : tr('practice')}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                !AppState.instance.levelUnlocked(lesson.level)
                    ? Icons.lock_outline
                    : passed
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                size: 20,
                color: passed ? const Color(0xFF286859) : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
