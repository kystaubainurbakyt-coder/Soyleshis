import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/theme/app_theme.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppLocale.instance,
    builder: (_, _) => DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final code in ['ru', 'en'])
              Semantics(
                selected: AppLocale.instance.language == code,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => AppLocale.instance.setLanguage(code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppLocale.instance.language == code
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      code.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppLocale.instance.language == code
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class LearningScrollBehavior extends MaterialScrollBehavior {
  const LearningScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: Duration(milliseconds: reduced ? 0 : 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: const TextStyle(fontSize: 12)),
          ),
      ],
    ),
  );
}

class LevelMark extends StatelessWidget {
  const LevelMark(this.level, {super.key, this.size = 48});
  final String level;
  final double size;
  static Color color(String level) => switch (level) {
    'A1' => const Color(0xFF286859),
    'A2' => const Color(0xFF2B6585),
    'B1' => const Color(0xFF655C9A),
    'B2' => const Color(0xFF986A39),
    _ => const Color(0xFF7C4D69),
  };
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color(level).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(size * .29),
    ),
    child: Text(
      level,
      style: TextStyle(
        fontSize: size * .31,
        color: color(level),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class HeritagePattern extends CustomPainter {
  const HeritagePattern();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5BC85).withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final radius = math.min(size.height * .39, 38.0);
    if (radius <= 0) return;
    final step = radius * 3.8;
    for (double x = step / 2; x < size.width; x += step) {
      canvas.save();
      canvas.translate(x, size.height / 2);
      for (var turn = 0; turn < 4; turn++) {
        canvas.save();
        canvas.rotate(turn * math.pi / 2);
        final petal = Path()
          ..moveTo(0, 0)
          ..cubicTo(
            -radius * .12,
            -radius * .32,
            -radius * .59,
            -radius * .27,
            -radius * .48,
            -radius * .62,
          )
          ..cubicTo(
            -radius * .37,
            -radius * .91,
            -radius * .06,
            -radius * .73,
            -radius * .19,
            -radius * .52,
          )
          ..quadraticBezierTo(
            -radius * .27,
            -radius * .4,
            -radius * .33,
            -radius * .53,
          )
          ..moveTo(0, 0)
          ..cubicTo(
            radius * .12,
            -radius * .32,
            radius * .59,
            -radius * .27,
            radius * .48,
            -radius * .62,
          )
          ..cubicTo(
            radius * .37,
            -radius * .91,
            radius * .06,
            -radius * .73,
            radius * .19,
            -radius * .52,
          )
          ..quadraticBezierTo(
            radius * .27,
            -radius * .4,
            radius * .33,
            -radius * .53,
          );
        canvas.drawPath(petal, paint);
        canvas.restore();
      }
      final diamond = Path()
        ..moveTo(0, -radius * .15)
        ..lineTo(radius * .15, 0)
        ..lineTo(0, radius * .15)
        ..lineTo(-radius * .15, 0)
        ..close();
      canvas.drawPath(diamond, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
