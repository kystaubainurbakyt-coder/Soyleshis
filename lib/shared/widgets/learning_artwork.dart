import 'dart:math' as math;

import 'package:flutter/material.dart';

enum LearningArtworkStyle { book, speaking, cards, achievement }

/// Lightweight offline artwork for course and practice cards.
class LearningArtwork extends StatelessWidget {
  const LearningArtwork({
    super.key,
    required this.style,
    this.size = 76,
    this.background = const Color(0xFFEAF0F8),
    this.accent = const Color(0xFF315A7D),
  });

  final LearningArtworkStyle style;
  final double size;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .25),
      ),
      child: CustomPaint(
        painter: _LearningArtworkPainter(style: style, accent: accent),
      ),
    ),
  );
}

class _LearningArtworkPainter extends CustomPainter {
  const _LearningArtworkPainter({required this.style, required this.accent});

  final LearningArtworkStyle style;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(
      (size.width / scale - 100) / 2,
      (size.height / scale - 100) / 2,
    );
    switch (style) {
      case LearningArtworkStyle.book:
        _paintBook(canvas);
        break;
      case LearningArtworkStyle.speaking:
        _paintSpeech(canvas);
        break;
      case LearningArtworkStyle.cards:
        _paintCards(canvas);
        break;
      case LearningArtworkStyle.achievement:
        _paintMedal(canvas);
        break;
    }
    canvas.restore();
  }

  void _paintBook(Canvas canvas) {
    final shadow = Paint()..color = const Color(0x14203855);
    final page = Paint()..color = const Color(0xFFFFFEFA);
    final cover = Paint()..color = accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17, 27, 68, 52),
        const Radius.circular(8),
      ),
      shadow,
    );
    final left = Path()
      ..moveTo(20, 25)
      ..quadraticBezierTo(38, 21, 49, 31)
      ..lineTo(49, 77)
      ..quadraticBezierTo(35, 68, 20, 73)
      ..close();
    final right = Path()
      ..moveTo(51, 31)
      ..quadraticBezierTo(66, 21, 82, 25)
      ..lineTo(82, 73)
      ..quadraticBezierTo(65, 68, 51, 77)
      ..close();
    canvas.drawPath(left, cover);
    canvas.drawPath(right, cover);
    final inset = Paint()..color = page.color;
    canvas.drawPath(left.shift(const Offset(3, -3)), inset);
    canvas.drawPath(right.shift(const Offset(-3, -3)), inset);
    final line = Paint()
      ..color = accent.withValues(alpha: .28)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 3; row++) {
      final y = 40.0 + row * 8;
      canvas.drawLine(
        Offset(30.0 + (row.isOdd ? 2 : 0), y),
        Offset(43, y),
        line,
      );
      canvas.drawLine(
        Offset(58, y),
        Offset(72.0 - (row.isOdd ? 3 : 0), y),
        line,
      );
    }
    canvas.drawCircle(
      const Offset(76, 24),
      4,
      Paint()..color = const Color(0xFFE5C88F),
    );
  }

  void _paintSpeech(Canvas canvas) {
    final bubbleA = Paint()..color = accent;
    final bubbleB = Paint()..color = const Color(0xFFE3C58A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 23, 54, 38),
        const Radius.circular(12),
      ),
      bubbleA,
    );
    final tailA = Path()
      ..moveTo(26, 59)
      ..lineTo(22, 70)
      ..lineTo(39, 59)
      ..close();
    canvas.drawPath(tailA, bubbleA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 43, 48, 34),
        const Radius.circular(11),
      ),
      bubbleB,
    );
    final tailB = Path()
      ..moveTo(70, 75)
      ..lineTo(79, 84)
      ..lineTo(80, 73)
      ..close();
    canvas.drawPath(tailB, bubbleB);
    _letter(canvas, 'Ә', const Offset(28, 29), Colors.white, 23);
    _letter(canvas, 'Қ', const Offset(53, 47), const Color(0xFF493B29), 19);
  }

  void _paintCards(Canvas canvas) {
    final shadow = Paint()..color = const Color(0x14203855);
    final colors = [
      accent.withValues(alpha: .64),
      const Color(0xFFE7C989),
      accent,
    ];
    const angles = [-.22, .12, .35];
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(50, 51 + i * 1.5);
      canvas.rotate(angles[i]);
      const rect = Rect.fromLTWH(-19, -27, 38, 54);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(1, 3)),
          const Radius.circular(7),
        ),
        shadow,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        Paint()..color = colors[i],
      );
      canvas.restore();
    }
    _letter(canvas, 'Ә', const Offset(38, 29), Colors.white, 25);
  }

  void _paintMedal(Canvas canvas) {
    final ribbon = Paint()..color = accent;
    final ribbonPath = Path()
      ..moveTo(38, 19)
      ..lineTo(49, 39)
      ..lineTo(38, 45)
      ..lineTo(30, 25)
      ..close()
      ..moveTo(61, 19)
      ..lineTo(50, 39)
      ..lineTo(62, 45)
      ..lineTo(69, 25)
      ..close();
    canvas.drawPath(ribbonPath, ribbon);
    canvas.drawCircle(
      const Offset(50, 56),
      27,
      Paint()..color = const Color(0xFFE7C989),
    );
    canvas.drawCircle(const Offset(50, 56), 20, Paint()..color = accent);
    _star(canvas, const Offset(50, 56), 12, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(79, 28),
      3,
      Paint()..color = const Color(0xFFE7C989),
    );
    canvas.drawCircle(
      const Offset(21, 74),
      2.5,
      Paint()..color = accent.withValues(alpha: .6),
    );
  }

  void _letter(
    Canvas canvas,
    String value,
    Offset position,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontFamily: 'NotoSans',
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .45;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LearningArtworkPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.accent != accent;
}
