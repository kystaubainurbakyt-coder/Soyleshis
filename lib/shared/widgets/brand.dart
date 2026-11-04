import 'package:flutter/material.dart';
import 'package:soyle/core/theme/app_theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false, this.large = false});
  final bool light;
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 58 : 36,
        height: large ? 58 : 36,
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: .12) : AppColors.soft,
          borderRadius: BorderRadius.circular(large ? 19 : 12),
          border: light
              ? Border.all(color: Colors.white.withValues(alpha: .18))
              : null,
        ),
        child: Icon(
          Icons.graphic_eq_rounded,
          color: light ? const Color(0xFFE8CA91) : AppColors.primary,
          size: large ? 32 : 22,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'SOYLE',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: large ? 34 : 20,
          letterSpacing: large ? 5 : 3,
          fontWeight: FontWeight.w700,
          color: light ? Colors.white : AppColors.primary,
        ),
      ),
    ],
  );
}
