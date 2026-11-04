import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/lessons/data/lesson_material.dart';

void main() {
  test('Export source content for editable Figma design', () async {
    final lessons = const LessonService().getLessons();
    final data = lessons.map((l) {
      final m = LessonMaterial.forLesson(l);
      return {
        'id': l.id,
        'title': l.title,
        'level': l.level,
        'description': l.description,
        'goal': m.goal,
        'rule': m.rule,
        'minutes': m.minutes,
        'examples': m.examples,
        'dialogue': m.dialogue,
        'words': l.words
            .map((w) => {'kk': w.kk, 'ru': w.ru, 'en': w.en})
            .toList(),
        'questions': m
            .questions(l)
            .map(
              (q) => {
                'prompt': q.prompt,
                'options': q.options,
                'answer': q.answer,
                'explanation': q.explanation,
              },
            )
            .toList(),
      };
    }).toList();
    await File(
      'docs/figma-content.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  });
}
