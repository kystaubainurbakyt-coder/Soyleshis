import 'package:flutter/material.dart';

/// Қосымшадағы негізгі әрекет батырмасы (барлық экранда бірдей көрінеді).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ElevatedButton(
        onPressed: null,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (icon == null) {
      return ElevatedButton(onPressed: onPressed, child: Text(label));
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
