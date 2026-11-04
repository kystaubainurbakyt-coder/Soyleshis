import 'package:flutter/material.dart';
import '../domain/models/lesson.dart';
import 'curriculum_data.dart';

class LessonService {
  const LessonService();
  static const levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
  static final _lessons = List<Lesson>.unmodifiable(
    curriculumData.map((item) {
      final title = item['title'] as Map;
      final rule = item['rule'] as Map;
      return Lesson(
        id: item['id'] as int,
        title: title['kk'] as String,
        titleRu: title['ru'] as String,
        titleEn: title['en'] as String,
        level: item['level'] as String,
        description: rule['ru'] as String,
        ruleRu: rule['ru'] as String,
        ruleEn: rule['en'] as String,
        minutes: item['minutes'] as int,
        icon: Icons.auto_stories_outlined,
        words: List<Word>.unmodifiable(
          (item['phrases'] as List).map(
            (p) => Word(
              kk: p['kk'] as String,
              ru: p['ru'] as String,
              en: p['en'] as String,
            ),
          ),
        ),
      );
    }),
  );
  List<Lesson> getLessons() => _lessons;
  ({Lesson lesson, Word word}) getDailyPractice() {
    final lessons = _lessons
        .where((lesson) => lesson.level == 'A1' && lesson.id != 7)
        .toList();
    final today = DateTime.now();
    final day = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(2026)).inDays.abs();
    final lesson = lessons[day % lessons.length];
    final word = lesson.words[(day ~/ lessons.length) % lesson.words.length];
    return (lesson: lesson, word: word);
  }

  Word getWordOfTheDay() => getDailyPractice().word;
}
