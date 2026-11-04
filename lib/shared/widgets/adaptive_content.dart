import 'package:flutter/material.dart';

/// Keeps mobile content readable on tablets and wide windows.
class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
