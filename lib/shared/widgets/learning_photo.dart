import 'package:flutter/material.dart';

/// Small offline photos used in lesson and course cards.
class LearningPhoto extends StatelessWidget {
  const LearningPhoto({
    super.key,
    required this.lessonId,
    this.width = 72,
    this.height = 72,
    this.borderRadius = 18,
  });

  final int lessonId;
  final double? width;
  final double? height;
  final double borderRadius;

  static String assetFor(int id) => switch (id.abs() % 3) {
    0 => 'assets/learning/study-notes.jpg',
    1 => 'assets/learning/reading-book.jpg',
    _ => 'assets/learning/book-desk.jpg',
  };

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        assetFor(lessonId),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.menu_book_rounded),
        ),
      ),
    ),
  );
}
