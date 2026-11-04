import 'core/database/learning_repository.dart';
import 'core/state/app_state.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/localization/app_locale.dart';

export 'app/app.dart' show SoyleApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.instance.initialize();
  try {
    AppState.instance.repository = await LearningRepository.openFlutter();
    runApp(const SoyleApp());
  } catch (error, stackTrace) {
    debugPrint('SOYLE startup failed: $error\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('databaseError'), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: main, child: Text(tr('retry'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
