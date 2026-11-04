import 'dart:async';
import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/shared/widgets/brand.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await AppState.instance.restoreSession();
    if (!mounted) return;
    timer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppState.instance.authenticated ? AppRoutes.home : AppRoutes.login,
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primary,
    body: CustomPaint(
      painter: const HeritagePattern(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Reveal(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FittedBox(child: Brand(light: true, large: true)),
                const SizedBox(height: 24),
                Text(
                  tr('learningOnly'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD5DFE8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
