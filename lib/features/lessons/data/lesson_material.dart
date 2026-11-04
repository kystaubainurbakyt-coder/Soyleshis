import 'package:soyle/core/localization/app_locale.dart';
import '../domain/models/lesson.dart';

class PracticeQuestion {
  const PracticeQuestion(
    this.prompt,
    this.options,
    this.answer,
    this.explanation, {
    this.skill = 'meaning',
  });
  final String prompt, explanation;
  final String skill;
  final List<String> options;
  final int answer;
}

class LessonMaterial {
  const LessonMaterial({
    required this.goal,
    required this.rule,
    required this.examples,
    required this.dialogue,
    required this.check,
    this.minutes = 18,
  });
  final String goal, rule;
  final List<String> examples, dialogue;
  final PracticeQuestion check;
  final int minutes;
  static LessonMaterial forLesson(Lesson lesson) => LessonMaterial(
    goal: lesson.displayTitle,
    rule: lesson.rule,
    minutes: lesson.minutes,
    examples: lesson.words
        .map((w) => '${w.kk}\n${w.translation}')
        .take(3)
        .toList(),
    dialogue: lesson.words.take(4).map((w) => w.kk).toList(),
    check: PracticeQuestion(
      tr('chooseKazakh', {'phrase': lesson.words.first.translation}),
      lesson.words.take(4).map((w) => w.kk).toList(),
      0,
      '${lesson.words.first.kk} — ${lesson.words.first.translation}',
    ),
  );

  List<PracticeQuestion> questions(Lesson lesson) {
    final result = <PracticeQuestion>[];
    for (var i = 0; i < 8; i++) {
      final index = i % lesson.words.length;
      final word = lesson.words[index];
      var skill = 'meaning';
      var prompt = tr('chooseTranslation', {'phrase': word.kk});
      var correct = word.translation;
      List<String> distractors = lesson.words
          .where((w) => w.kk != word.kk)
          .take(3)
          .map((w) => w.translation)
          .toList();
      if (i == 1 || i == 5) {
        final tokens = word.kk.split(' ');
        final missing = tokens.length ~/ 2;
        correct = tokens[missing];
        final sentence = [...tokens]..[missing] = '_____';
        prompt = tr('taskGap', {
          'phrase': sentence.join(' '),
          'hint': word.translation,
        });
        skill = 'grammarSkill';
        distractors = lesson.words
            .expand((w) => w.kk.split(' '))
            .where((w) => w != correct)
            .toSet()
            .take(3)
            .toList();
      } else if (i == 2 || i == 6) {
        final turn = i == 2 ? 1 : 3;
        final previous = lesson.words[turn - 1];
        final reply = lesson.words[turn];
        skill = 'dialogueSkill';
        correct = reply.kk;
        prompt = tr('taskDialogue', {
          'phrase': previous.kk,
          'hint': reply.translation,
        });
        distractors = lesson.words
            .where((w) => w.kk != correct)
            .take(3)
            .map((w) => w.kk)
            .toList();
      } else if (i == 3 || i == 7) {
        final tokens = word.kk.split(' ');
        if (tokens.length > 1) {
          skill = 'syntaxSkill';
          correct = word.kk;
          prompt = tr('taskOrder', {'phrase': tokens.reversed.join(' / ')});
          distractors = [
            tokens.reversed.join(' '),
            [...tokens.skip(1), tokens.first].join(' '),
            [tokens.last, ...tokens.take(tokens.length - 1)].join(' '),
          ].where((v) => v != correct).toSet().toList();
          for (final other in lesson.words) {
            if (distractors.length >= 3) break;
            if (other.kk != correct && !distractors.contains(other.kk)) {
              distractors.add(other.kk);
            }
          }
        }
      }
      final options = [correct, ...distractors.take(3)];
      final shift = (lesson.id + i) % options.length;
      final rotated = [...options.skip(shift), ...options.take(shift)];
      final explanation = skill == 'dialogueSkill'
          ? '${lesson.words[i == 2 ? 1 : 3].kk}\n${lesson.words[i == 2 ? 1 : 3].translation}'
          : '${word.kk}\n${word.translation}';
      result.add(
        PracticeQuestion(
          prompt,
          rotated,
          rotated.indexOf(correct),
          explanation,
          skill: skill,
        ),
      );
    }
    return result;
  }
}
