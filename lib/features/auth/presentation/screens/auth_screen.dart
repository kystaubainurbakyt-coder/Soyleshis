import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/auth/data/auth_service.dart';
import 'package:soyle/features/auth/domain/auth_validators.dart';
import 'package:soyle/shared/widgets/app_text_field.dart';
import 'package:soyle/shared/widgets/brand.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/primary_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.register = false});
  final bool register;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final forms = <String, GlobalKey<FormState>>{};
  GlobalKey<FormState> get form => forms.putIfAbsent(
    AppLocale.instance.language,
    () => GlobalKey<FormState>(),
  );
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  bool hidden = true, busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [name, email, password, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  String? translated(String? message) => message == null ? null : tr(message);
  Future<void> submit() async {
    if (busy) return;
    setState(() => error = null);
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      final state = AppState.instance;
      final account = widget.register
          ? await state.auth.register(name.text, email.text, password.text)
          : await state.auth.login(email.text, password.text);
      await state.openAccount(account);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'authError');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void exitRegistration() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [LanguageSwitch(), SizedBox(width: 20)]),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 32),
          child: AutofillGroup(
            child: Form(
              key: form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: Alignment.centerLeft, child: Brand()),
                  const SizedBox(height: 12),
                  const Reveal(
                    child: SizedBox(
                      height: 54,
                      child: CustomPaint(
                        painter: HeritagePattern(),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    child: Text(
                      tr(widget.register ? 'join' : 'welcome'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(widget.register ? 'registerIntro' : 'loginIntro'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  if (widget.register) ...[
                    AppTextField(
                      controller: name,
                      enabled: !busy,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: tr('name'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? tr('nameTooShort')
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    controller: email,
                    enabled: !busy,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: tr('email'),
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                    validator: (v) => translated(AuthValidators.email(v)),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: password,
                    enabled: !busy,
                    obscureText: hidden,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: [
                      widget.register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textInputAction: widget.register
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: widget.register ? null : (_) => submit(),
                    decoration: InputDecoration(
                      labelText: tr('password'),
                      helperText: tr('passwordHint'),
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: tr(hidden ? 'showPassword' : 'hidePassword'),
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(
                          hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => translated(AuthValidators.password(v)),
                  ),
                  if (widget.register) ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: confirmation,
                      enabled: !busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: tr('confirmPassword'),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      onFieldSubmitted: (_) => submit(),
                      validator: (v) =>
                          v != password.text ? tr('passwordMismatch') : null,
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tr(error!),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: tr(widget.register ? 'register' : 'login'),
                    loading: busy,
                    onPressed: submit,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => widget.register
                              ? exitRegistration()
                              : Navigator.pushNamed(
                                  context,
                                  AppRoutes.register,
                                ),
                    child: Text(
                      tr(widget.register ? 'haveAccount' : 'noAccount'),
                    ),
                  ),
                  if (!widget.register)
                    TextButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: Text(tr('adminLogin')),
                      onPressed: () async {
                        final opened = await launchUrl(
                          Uri.parse('http://127.0.0.1:8766/login'),
                          mode: LaunchMode.externalApplication,
                        );
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('adminUnavailable'))),
                          );
                        }
                      },
                    ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            AppRoutes.onboarding,
                          ),
                    child: Text(tr('intro')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
