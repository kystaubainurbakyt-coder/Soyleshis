import 'package:flutter/material.dart';

/// Shared form field: decoration and error states come from AppTheme.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.decoration = const InputDecoration(),
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
  });

  final TextEditingController? controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: decoration,
    validator: validator,
    enabled: enabled,
    obscureText: obscureText,
    autocorrect: autocorrect,
    enableSuggestions: enableSuggestions,
    autofillHints: autofillHints,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    onFieldSubmitted: onFieldSubmitted,
    onChanged: onChanged,
  );
}
