import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';
import 'package:soyle/features/lessons/presentation/widgets/lesson_practice.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/learning_photo.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Lesson) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(tr('notFound'))),
      );
    }
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final lesson = state.lessons.firstWhere(
          (l) => l.id == arg.id,
          orElse: () => arg,
        );
        final saved = state.favorites.contains(lesson.id);
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                lesson.displayTitle,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: tr(saved ? 'unsaveLesson' : 'saveLesson'),
                  onPressed: () => state.update(() {
                    if (saved) {
                      state.favorites.remove(lesson.id);
                    } else {
                      state.favorites.add(lesson.id);
                    }
                  }),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      key: ValueKey(saved),
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                ),
                const LanguageSwitch(),
                const SizedBox(width: 12),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final key in [
                    'overview',
                    'vocabulary',
                    'dialogue',
                    'practice',
                  ])
                    Tab(text: tr(key)),
                ],
              ),
            ),
            body: AdaptiveContent(
              maxWidth: 900,
              child: TabBarView(
                children: [
                  Builder(
                    builder: (context) => ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        Reveal(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: SizedBox(
                              height: 210,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Hero(
                                    tag: 'lesson-photo-${lesson.id}',
                                    child: LearningPhoto(
                                      lessonId: lesson.id,
                                      width: double.infinity,
                                      height: 210,
                                      borderRadius: 0,
                                    ),
                                  ),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xE6102A48),
                                          Color(0xAA102A48),
                                          Color(0x33102A48),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                Text(
                                  '${lesson.level}  ·  ${tr('minutes', {'n': lesson.minutes})}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFD9C59E),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  lesson.displayTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (state.scores.containsKey(lesson.id)) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    tr('bestScore', {
                                      'n': state.scores[lesson.id]!,
                                    }),
                                    style: const TextStyle(
                                      color: Color(0xFFD2DDE8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SectionTitle(tr('grammar')),
                        SelectableText(
                          lesson.rule,
                          style: const TextStyle(height: 1.9, fontSize: 15),
                        ),
                        SectionTitle(tr('examples')),
                        for (final phrase in lesson.words.skip(4))
                          _PhraseTile(phrase: phrase),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.notebook,
                            arguments: lesson.id,
                          ),
                          icon: const Icon(Icons.edit_note),
                          label: Text(tr('lessonNotes')),
                        ),
                        SectionTitle(tr('independent')),
                        for (final key in [
                          'speakTask',
                          'writeTask',
                          'recallTask',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 19,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tr(key),
                                    style: const TextStyle(height: 1.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () =>
                              DefaultTabController.of(context).animateTo(1),
                          child: Text(tr('vocabulary')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.sentenceLab,
                            arguments: lesson,
                          ),
                          child: Text(tr('sentenceBuilder')),
                        ),
                        TextButton(
                          onPressed: () =>
                              DefaultTabController.of(context).animateTo(3),
                          child: Text(tr('goPractice')),
                        ),
                      ],
                    ),
                  ),
                  ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      Text(
                        tr('vocabHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      for (final phrase in lesson.words)
                        _PhraseTile(phrase: phrase),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      Text(
                        tr('dialogueHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      for (final entry
                          in lesson.words.take(4).toList().asMap().entries)
                        Align(
                          alignment: entry.key.isEven
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            margin: const EdgeInsets.only(
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: entry.key.isEven
                                  ? Colors.white
                                  : AppColors.soft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key.isEven ? 'A' : 'B',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  entry.value.kk,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.65,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  entry.value.translation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  LessonPractice(
                    key: ValueKey(lesson.id),
                    lesson: lesson,
                    material: LessonMaterial.forLesson(lesson),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhraseTile extends StatefulWidget {
  const _PhraseTile({required this.phrase});
  final Word phrase;
  @override
  State<_PhraseTile> createState() => _PhraseTileState();
}

class _PhraseTileState extends State<_PhraseTile> {
  bool visible = true;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.phrase.kk,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.65,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            alignment: Alignment.topLeft,
            child: visible
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      widget.phrase.translation,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.7,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          TextButton(
            onPressed: () => setState(() => visible = !visible),
            child: Text(
              tr(visible ? 'hideTranslation' : 'showTranslation'),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
