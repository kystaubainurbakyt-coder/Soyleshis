import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import '../widgets/progress_widgets.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) {
      final state = AppState.instance;
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('achievements')),
          actions: const [LanguageSwitch(), SizedBox(width: 18)],
        ),
        body: AdaptiveContent(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Reveal(child: ProgressOverview()),
              SectionTitle(
                '${tr('badges')} · ${state.badges.where((b) => b.earned).length}/${state.badges.length}',
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 330 ? 1 : 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: state.badges
                        .map(
                          (badge) => SizedBox(
                            width:
                                (constraints.maxWidth - 12 * (columns - 1)) /
                                columns,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: badge.earned
                                    ? const Color(0xFFF3EEDF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: badge.earned
                                      ? const Color(0xFFD7C5A3)
                                      : AppColors.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    badge.earned
                                        ? Icons.verified_rounded
                                        : Icons.lock_outline,
                                    color: badge.earned
                                        ? const Color(0xFF927947)
                                        : AppColors.textMuted,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    badge.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    badge.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    tr(
                                      badge.earned
                                          ? 'badgeEarned'
                                          : 'badgeLocked',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              SectionTitle(tr('certificates')),
              for (final level in LessonService.levels)
                Card(
                  child: ListTile(
                    leading: LevelMark(level, size: 38),
                    title: Text(
                      '$level · ${tr('certificate')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      state.certificates.containsKey(level)
                          ? tr('certificateReady')
                          : tr('completedCount', {
                              'done': state.levelPassed(level),
                              'total': state.levelLessons(level).length,
                            }),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.certificate,
                      arguments: level,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
