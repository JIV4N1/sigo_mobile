import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SigoButtonType { primary, secondary, accent, danger, outline }

/// Botón estándar de SIGO. Envuelve [ElevatedButton]/[OutlinedButton] con
/// los 5 estilos definidos en el sistema de diseño (ver [SigoButtonType]).
class SigoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SigoButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const SigoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = SigoButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _foreground(context),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          );

    final button = _buildButton(context, child);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _foreground(BuildContext context) {
    switch (type) {
      case SigoButtonType.secondary:
      case SigoButtonType.outline:
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.white;
    }
  }

  Widget _buildButton(BuildContext context, Widget child) {
    final radius = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case SigoButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            padding: padding,
            shape: radius,
          ),
          child: child,
        );
      case SigoButtonType.accent:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: padding,
            shape: radius,
          ),
          child: child,
        );
      case SigoButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: padding,
            shape: radius,
          ),
          child: child,
        );
      case SigoButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
            padding: padding,
            shape: radius,
          ),
          child: child,
        );
      case SigoButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: const BorderSide(color: AppColors.border),
            padding: padding,
            shape: radius,
          ),
          child: child,
        );
    }
  }
}
