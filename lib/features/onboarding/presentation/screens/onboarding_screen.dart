import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  void finish() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [LanguageSwitch(), SizedBox(width: 20)]),
    body: AdaptiveContent(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Column(
            key: ValueKey(step),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  [
                    Icons.translate_rounded,
                    Icons.forum_outlined,
                    Icons.workspace_premium_outlined,
                  ][step],
                  size: 70,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                tr('onboard${step + 1}'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                tr('onboard${step + 1}Hint'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == step ? 24 : 7,
                    height: 7,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: i == step ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: tr(step == 2 ? 'login' : 'next'),
                onPressed: () => step == 2 ? finish() : setState(() => step++),
              ),
              TextButton(onPressed: finish, child: Text(tr('skip'))),
            ],
          ),
        ),
      ),
    ),
  );
}
