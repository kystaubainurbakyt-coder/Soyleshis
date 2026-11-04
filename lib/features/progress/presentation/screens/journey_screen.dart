import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/lessons/presentation/widgets/lesson_card.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});
  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  String level = 'A1';
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (LessonService.levels.contains(arg)) level = arg as String;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) {
      final state = AppState.instance;
      final lessons = state.levelLessons(level);
      final passed = state.levelPassed(level);
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('journey')),
          actions: const [LanguageSwitch(), SizedBox(width: 18)],
        ),
        body: AdaptiveContent(
          maxWidth: 900,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Reveal(
                child: Row(
                  children: [
                    LevelMark(level, size: 62),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(level),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('lessonsCount', {'n': lessons.length}),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('levelLocked'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final l in LessonService.levels)
                    ChoiceChip(
                      label: Text('${state.levelUnlocked(l) ? '' : '🔒 '}$l'),
                      selected: l == level,
                      onSelected: (_) => setState(() => level = l),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                tr('completedCount', {'done': passed, 'total': lessons.length}),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: passed / lessons.length,
                minHeight: 5,
                borderRadius: BorderRadius.circular(5),
                color: LevelMark.color(level),
              ),
              const SizedBox(height: 22),
              for (final lesson in lessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LessonCard(
                    lesson: lesson,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.lessonDetail,
                      arguments: lesson,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEDF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium_outlined,
                      size: 42,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$level · ${tr('courseCertificate')}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state.certificates.containsKey(level)
                          ? tr('certificateReady')
                          : tr('certificateThreshold'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.certificate,
                        arguments: level,
                      ),
                      child: Text(
                        tr(
                          state.certificates.containsKey(level)
                              ? 'openCertificate'
                              : 'certificate',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
