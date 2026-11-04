import 'package:flutter/widgets.dart';
import 'package:soyle/core/localization/app_locale.dart';

/// Бір сөз немесе тіркес: қазақша, орысша және ағылшынша аудармасымен.
class Word {
  const Word({required this.kk, required this.ru, required this.en});

  final String kk;
  final String ru;
  final String en;
  String get translation => bilingual(ru, en);
}

/// Бір сабақтың моделі.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.level,
    required this.description,
    required this.icon,
    required this.words,
    this.titleRu = '',
    this.titleEn = '',
    this.ruleRu = '',
    this.ruleEn = '',
    this.minutes = 18,
  });

  final int id;
  final String title;
  final String level; // A1, A2, ...
  final String description;
  final IconData icon;
  final List<Word> words;
  final String titleRu, titleEn, ruleRu, ruleEn;
  final int minutes;
  String get displayTitle => bilingual(
    titleRu.isEmpty ? title : titleRu,
    titleEn.isEmpty ? title : titleEn,
  );
  String get rule => bilingual(ruleRu, ruleEn);
}
