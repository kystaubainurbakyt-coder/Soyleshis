import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';

class LessonPractice extends StatefulWidget {
  const LessonPractice({
    super.key,
    required this.lesson,
    required this.material,
    this.now,
  });
  final Lesson lesson;
  final LessonMaterial material;
  final DateTime Function()? now;
  @override
  State<LessonPractice> createState() => _LessonPracticeState();
}

class _LessonPracticeState extends State<LessonPractice>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final scroll = ScrollController();
  Timer? timer;
  DateTime? deadline;
  int remaining = 0;
  bool started = false, allowExit = false, askingExit = false, timedOut = false;
  void start() {
    setState(() {
      started = true;
      remaining = widget.lesson.minutes * 60;
      deadline = (widget.now ?? DateTime.now)().add(
        Duration(seconds: remaining),
      );
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || finished) return;
      final seconds = deadline!
          .difference((widget.now ?? DateTime.now)())
          .inMilliseconds;
      setState(
        () => remaining = ((seconds + 999) ~/ 1000).clamp(
          0,
          widget.lesson.minutes * 60,
        ),
      );
      if (remaining == 0) finishExpired();
    });
  }

  void finishExpired() {
    timer?.cancel();
    setState(() {
      timedOut = true;
      while (answers.length < questions.length) {
        answers.add(-1);
      }
      finished = true;
      saveResult();
    });
    returnToTop();
  }

  void saveResult() {
    final correct = List.generate(
      questions.length,
      (i) => answers[i] == questions[i].answer ? 1 : 0,
    ).fold(0, (a, b) => a + b);
    earnedXp = AppState.instance.recordAttempt(
      widget.lesson.id,
      (correct * 100 / questions.length).round(),
    );
  }

  Future<void> confirmExit() async {
    if (askingExit) return;
    askingExit = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(tr('leavePractice')),
        content: Text(tr('leavePracticeHint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(tr('stayPractice')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(tr('leaveNow')),
          ),
        ],
      ),
    );
    askingExit = false;
    if (leave == true && mounted) {
      timer?.cancel();
      setState(() => allowExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    scroll.dispose();
    super.dispose();
  }

  void returnToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.animateTo(
          0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  List<PracticeQuestion> get questions =>
      widget.material.questions(widget.lesson);
  int index = 0, earnedXp = 0;
  int? selected;
  final answers = <int>[];
  bool finished = false;
  void next() {
    if (selected == null) return;
    setState(() {
      answers.add(selected!);
      if (index == questions.length - 1) {
        finished = true;
      } else {
        index++;
        selected = null;
      }
    });
    if (finished) {
      timer?.cancel();
      saveResult();
    }
    returnToTop();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: !started || finished || allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) confirmExit();
      },
      child: buildPractice(context),
    );
  }

  Widget buildPractice(BuildContext context) {
    if (!started) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            tr('startChallenge'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(tr('challengeIntro'), style: const TextStyle(height: 1.7)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in [
                'meaning',
                'grammarSkill',
                'dialogueSkill',
                'syntaxSkill',
              ])
                Chip(label: Text(tr(skill))),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            key: const ValueKey('start-practice'),
            onPressed: start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(tr('startChallenge')),
          ),
        ],
      );
    }

    if (finished) {
      final correct = List.generate(
        questions.length,
        (i) => answers[i] == questions[i].answer ? 1 : 0,
      ).fold(0, (a, b) => a + b);
      final percent = (correct * 100 / questions.length).round();
      return ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: percent >= 70 ? const Color(0xFFE8F1ED) : AppColors.soft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    percent >= 70
                        ? Icons.verified_outlined
                        : Icons.replay_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr(percent >= 70 ? 'lessonComplete' : 'tryAgain'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('result', {
                      'correct': correct,
                      'total': questions.length,
                      'percent': percent,
                    }),
                    textAlign: TextAlign.center,
                  ),
                  if (earnedXp > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      tr('earnedXp', {'n': earnedXp}),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (timedOut)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                tr('timeExpired'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SectionTitle(tr('skillsReport')),
          for (final skill in questions.map((q) => q.skill).toSet())
            Builder(
              builder: (context) {
                final indices = List.generate(
                  questions.length,
                  (i) => i,
                ).where((i) => questions[i].skill == skill).toList();
                final score = indices
                    .where((i) => answers[i] == questions[i].answer)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${tr(skill)}  $score / ${indices.length}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: score / indices.length,
                        borderRadius: BorderRadius.circular(6),
                        minHeight: 6,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Text(
            tr('passHint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (AppState.instance.certificates.containsKey(widget.lesson.level) &&
              percent >= 70)
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(tr('certificateReady')),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.certificate,
                  arguments: widget.lesson.level,
                ),
              ),
            ),
          const SizedBox(height: 20),
          for (var i = 0; i < questions.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${questions[i].prompt}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr('yourAnswer', {
                        'answer': answers[i] < 0
                            ? tr('unanswered')
                            : questions[i].options[answers[i]],
                      }),
                      style: TextStyle(
                        color: answers[i] == questions[i].answer
                            ? const Color(0xFF286859)
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      questions[i].explanation,
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Text(tr('profile')),
          ),
          TextButton(
            onPressed: () => setState(() {
              index = 0;
              selected = null;
              answers.clear();
              finished = false;
              earnedXp = 0;
              started = false;
              timedOut = false;
              allowExit = false;
              returnToTop();
            }),
            child: Text(tr('retry')),
          ),
        ],
      );
    }
    final question = questions[index];
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: remaining < 60 ? const Color(0xFFFCE9E5) : AppColors.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: remaining < 60 ? Colors.red : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('timeLeft', {
                    'time':
                        '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  }),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${index + 1}/${questions.length}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(label: Text(tr(question.skill))),
        ),
        Text(
          tr('questionCount', {'n': index + 1, 'total': questions.length}),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: index / questions.length,
          minHeight: 5,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Align(
            key: ValueKey('${AppLocale.instance.language}-$index'),
            alignment: Alignment.centerLeft,
            child: Text(
              question.prompt,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final option in question.options.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              key: ValueKey('answer-${option.key}'),
              onPressed: selected == null
                  ? () {
                      if (option.key == question.answer) {
                        HapticFeedback.mediumImpact();
                      } else {
                        HapticFeedback.lightImpact();
                      }
                      setState(() => selected = option.key);
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(18),
                disabledForegroundColor: AppColors.textDark,
                backgroundColor: selected == null
                    ? Colors.white
                    : option.key == question.answer
                    ? const Color(0xFFE8F1ED)
                    : option.key == selected
                    ? Theme.of(context).colorScheme.errorContainer
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.value,
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                  if (selected != null &&
                      (option.key == question.answer || option.key == selected))
                    Icon(
                      option.key == question.answer
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: option.key == question.answer
                          ? const Color(0xFF137858)
                          : Theme.of(context).colorScheme.error,
                    ),
                ],
              ),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('feedback-$index'),
              tween: Tween(
                begin: MediaQuery.disableAnimationsOf(context) ? 1 : .85,
                end: 1,
              ),
              duration: Duration(
                milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 450,
              ),
              curve: Curves.easeOutBack,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selected == question.answer
                      ? const Color(0xFF137858)
                      : Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (selected == question.answer
                                  ? const Color(0xFF137858)
                                  : Colors.red)
                              .withValues(alpha: .2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      selected == question.answer
                          ? Icons.auto_awesome
                          : Icons.info_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tr(
                          selected == question.answer ? 'correct' : 'incorrect',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(question.explanation, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 22),
        ],
        ElevatedButton(
          onPressed: selected == null ? null : next,
          child: Text(
            tr(index == questions.length - 1 ? 'seeResults' : 'nextQuestion'),
          ),
        ),
      ],
    );
  }
}
