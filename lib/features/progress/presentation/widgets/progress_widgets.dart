import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/shared/widgets/learning_artwork.dart';

class ProgressOverview extends StatelessWidget {
  const ProgressOverview({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 26,
            runSpacing: 16,
            children: [
              _Metric(Icons.bolt_rounded, '${s.xp}', tr('totalXp')),
              _Metric(
                Icons.local_fire_department_outlined,
                tr('days', {'n': s.streak}),
                tr('streak'),
              ),
              _Metric(
                Icons.stars_outlined,
                tr('rank', {'n': s.rank}),
                tr('rank${(s.rank - 1).clamp(0, 3)}'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('dailyGoal'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${s.todayXp.clamp(0, s.dailyGoal)} / ${s.dailyGoal} XP',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (s.todayXp / s.dailyGoal).clamp(0, 1)),
            duration: const Duration(milliseconds: 600),
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              borderRadius: BorderRadius.circular(5),
              color: const Color(0xFF9B865F),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value, this.caption);
  final IconData icon;
  final String value, caption;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        caption,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
    ],
  );
}

class LearningHubCard extends StatelessWidget {
  const LearningHubCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.gold = false,
    this.artwork = LearningArtworkStyle.cards,
  });
  final String title, subtitle, route;
  final IconData icon;
  final bool gold;
  final LearningArtworkStyle artwork;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gold ? const Color(0xFFF3EEDF) : AppColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                LearningArtwork(
                  style: artwork,
                  size: 68,
                  background: gold
                      ? const Color(0xFFFFF8E8)
                      : const Color(0xFFEAF0F8),
                  accent: gold ? const Color(0xFF9A6D36) : AppColors.primary,
                ),
                const Positioned(
                  right: 1,
                  bottom: 1,
                  child: Icon(Icons.north_east_rounded, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class LearningHub extends StatelessWidget {
  const LearningHub({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      LearningHubCard(
        title: tr('review'),
        subtitle: tr('reviewHint'),
        icon: Icons.style_outlined,
        route: AppRoutes.review,
        artwork: LearningArtworkStyle.cards,
      ),
      const SizedBox(height: 8),
      LearningHubCard(
        title: tr('achievements'),
        subtitle: tr('achievementsHint'),
        icon: Icons.workspace_premium_outlined,
        route: AppRoutes.achievements,
        gold: true,
        artwork: LearningArtworkStyle.achievement,
      ),
    ],
  );
}
