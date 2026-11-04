import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/app_text_field.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final forms = <String, GlobalKey<FormState>>{};
  GlobalKey<FormState> get form => forms.putIfAbsent(
    AppLocale.instance.language,
    () => GlobalKey<FormState>(),
  );
  late final name = TextEditingController(text: AppState.instance.name);
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('settings'))),
    body: AdaptiveContent(
      child: Form(
        key: form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppTextField(
              controller: name,
              decoration: InputDecoration(labelText: tr('editName')),
              validator: (v) => (v?.trim().length ?? 0) < 2
                  ? tr('Атыңыз кемінде 2 таңба болсын')
                  : null,
            ),
            const SizedBox(height: 28),
            Text(
              tr('language'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr('languageHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: LanguageSwitch(),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: tr('save'),
              onPressed: () {
                if (!form.currentState!.validate()) return;
                AppState.instance.update(
                  () => AppState.instance.name = name.text.trim(),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
