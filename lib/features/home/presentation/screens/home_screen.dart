import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/progress/presentation/widgets/progress_widgets.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/app_navigation.dart';
import 'package:soyle/shared/widgets/brand.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/learning_artwork.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) {
      final state = AppState.instance;
      final next = state.lessons.firstWhere(
        (l) => !state.completed.contains(l.id),
        orElse: () => state.lessons.first,
      );
      final dailyPractice = const LessonService().getDailyPractice();
      final word = dailyPractice.word;
      return Scaffold(
        bottomNavigationBar: const AppNavigation(index: 0),
        body: SafeArea(
          child: AdaptiveContent(
            maxWidth: 1120,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Brand(),
                        ),
                      ),
                    ),
                    const LanguageSwitch(),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: tr('profile'),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      icon: const Icon(Icons.account_circle_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Reveal(
                  child: Text(
                    tr('greeting', {'name': state.name}),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Reveal(
                  delay: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF173B64), Color(0xFF102A48)],
                        ),
                      ),
                      child: CustomPaint(
                        painter: const HeritagePattern(),
                        child: Padding(
                          padding: const EdgeInsets.all(26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bilingual(
                                  'КАЗАХСКИЙ ЯЗЫК · В ВАШЕМ ТЕМПЕ',
                                  'KAZAKH · AT YOUR OWN PACE',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFCEBA91),
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                tr('heroTitle'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 30,
                                  height: 1.2,
                                  letterSpacing: -.8,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: Text(
                                  tr('heroSubtitle'),
                                  style: const TextStyle(
                                    color: Color(0xFFCAD6E2),
                                    height: 1.65,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.lessonDetail,
                                  arguments: next,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE7D6B5),
                                  foregroundColor: AppColors.primary,
                                ),
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  tr(
                                    state.completed.isEmpty
                                        ? 'start'
                                        : 'continue',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '${next.level}  ·  ${next.displayTitle}',
                                style: const TextStyle(
                                  color: Color(0xFFD8E1EB),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Reveal(delay: 100, child: ProgressOverview()),
                SectionTitle(
                  tr('explore'),
                  action: tr('allCourses'),
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.lessons),
                ),
                SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(205),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      final level = LessonService.levels[index];
                      final total = state.levelLessons(level).length;
                      final passed = state.levelPassed(level);
                      return SizedBox(
                        width: 230,
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.journey,
                              arguments: level,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      LevelMark(level, size: 42),
                                      const SizedBox(width: 7),
                                      LearningArtwork(
                                        style:
                                            LearningArtworkStyle.values[index %
                                                LearningArtworkStyle
                                                    .values
                                                    .length],
                                        size: 66,
                                        background: const Color(0xFFF0F4F8),
                                        accent: LevelMark.color(level),
                                      ),
                                      const SizedBox(width: 7),
                                      const Icon(
                                        Icons.north_east_rounded,
                                        size: 19,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    tr(level),
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    tr('completedCount', {
                                      'done': passed,
                                      'total': total,
                                    }),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  LinearProgressIndicator(
                                    value: passed / total,
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(4),
                                    color: LevelMark.color(level),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SectionTitle(tr('practice')),
                const LearningHub(),
                SectionTitle(tr('dailyPractice')),
                Reveal(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF102E58), Color(0xFF244C7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20102E58),
                          blurRadius: 20,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.record_voice_over_rounded,
                              color: Color(0xFFE8C98F),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${dailyPractice.lesson.level}  ·  5 MIN',
                              style: const TextStyle(
                                color: Color(0xFFE8C98F),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                              ),
                            ),
                            const Spacer(),
                            LearningArtwork(
                              style: LearningArtworkStyle.speaking,
                              size: 72,
                              background: Colors.white.withValues(alpha: .12),
                              accent: const Color(0xFF315A7D),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tr('dailyPracticeTip'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          word.kk,
                          style: const TextStyle(
                            fontFamily: 'NotoSerif',
                            fontSize: 24,
                            height: 1.45,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          word.translation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.55,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        for (final (index, key) in [
                          'dailyStep1',
                          'dailyStep2',
                          'dailyStep3',
                        ].indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Row(
                              children: [
                                Container(
                                  width: 23,
                                  height: 23,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tr(key),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 7),
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.lessonDetail,
                            arguments: dailyPractice.lesson,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(tr('dailyOpenLesson')),
                          style: FilledButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            backgroundColor: const Color(0xFFFFF8E9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
