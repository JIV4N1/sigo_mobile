import 'package:flutter/material.dart';

/// Card estándar de SIGO: bordes redondeados, sombra sutil y ripple opcional.
class SigoCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const SigoCard({
    super.key,
    required this.child,
    this.elevation,
    this.padding,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(12);

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    return Card(
      elevation: elevation ?? 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius),
      color: gradient != null ? Colors.transparent : theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: gradient != null
            ? Container(decoration: BoxDecoration(gradient: gradient), child: content)
            : content,
      ),
    );
  }
}
