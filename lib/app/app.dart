import 'package:flutter/material.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/constants/app_strings.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:provider/provider.dart';

class SoyleApp extends StatelessWidget {
  const SoyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: AppState.instance),
        ChangeNotifierProvider<AppLocale>.value(value: AppLocale.instance),
      ],
      child: Consumer<AppState>(
        builder: (context, _, _) => Consumer<AppLocale>(
          builder: (context, _, _) => MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: Locale(AppLocale.instance.language),
            supportedLocales: const [Locale('ru'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            scrollBehavior: const LearningScrollBehavior(),
            builder: (context, child) => ListenableBuilder(
              listenable: AppState.instance,
              builder: (context, _) => Column(
                children: [
                  if (AppState.instance.storageError != null)
                    SafeArea(
                      bottom: false,
                      child: Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            tr('storageError'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: child ?? const SizedBox()),
                ],
              ),
            ),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}
