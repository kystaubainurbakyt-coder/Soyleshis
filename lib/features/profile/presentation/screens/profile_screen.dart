import 'package:flutter/material.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/app_navigation.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) {
      final state = AppState.instance;
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('profile')),
          actions: const [LanguageSwitch(), SizedBox(width: 18)],
        ),
        bottomNavigationBar: const AppNavigation(index: 4),
        body: AdaptiveContent(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Reveal(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.soft,
                        child: Text(
                          state.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        state.email,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${tr('rank${(state.rank - 1).clamp(0, 3)}')}  ·  ${state.xp} XP',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: Text(tr('scanLessonQr')),
                  subtitle: Text(tr('scanLessonQrHint')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.qrScanner),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(tr('studyRoom')),
                  subtitle: Text(tr('chatWelcome')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.studyRoom),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: Text(tr('notebook')),
                  subtitle: Text(tr('notebookIntro')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notebook),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(tr('completedLessons')),
                      trailing: Text('${state.completed.length}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.bookmark_border),
                      title: Text(tr('saved')),
                      trailing: Text('${state.favorites.length}'),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.favorites),
                    ),
                  ],
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(tr('achievements')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.achievements),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(tr('settings')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await state.signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  );
                },
                child: Text(tr('logout')),
              ),
              const SizedBox(height: 18),
              Text(
                tr('localAccount'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );
}
