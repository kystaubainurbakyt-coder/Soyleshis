import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const primary = Color(0xFF102E58);
  static const accent = Color(0xFFC9A66B);
  static const background = Color(0xFFF5F6F7);
  static const surface = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF182A43);
  static const textMuted = Color(0xFF6C7C92);
  static const border = Color(0xFFDFE6F0);
  static const soft = Color(0xFFE8EFF9);
}

class AppTheme {
  AppTheme._();
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, fontFamily: 'NotoSans');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textDark,
      ),
      scaffoldBackgroundColor: AppColors.background,
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(5),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.primary.withValues(
            alpha: states.contains(WidgetState.hovered) ? .45 : .2,
          ),
        ),
      ),
      dividerColor: AppColors.border,
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textDark,
            displayColor: AppColors.textDark,
          )
          .copyWith(
            titleLarge: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.textDark,
            ),
            headlineMedium: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
              color: AppColors.textDark,
            ),
            titleMedium: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w600,
              letterSpacing: -.3,
              color: AppColors.textDark,
            ),
            bodyMedium: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 14,
              height: 1.6,
              color: AppColors.textDark,
            ),
            bodySmall: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
          color: AppColors.textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 19,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        prefixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.soft,
          disabledForegroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: shape,
          textStyle: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          side: const BorderSide(color: AppColors.border),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.all(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        indicatorColor: AppColors.soft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.soft,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: shape,
      ),
    );
  }
}
