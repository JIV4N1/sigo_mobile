import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Campo de texto estándar de SIGO: borde outline redondeado, label
/// flotante e íconos de validación (éxito/error).
class SigoInput extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool isValid;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;

  const SigoInput({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.isValid = false,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trailing = suffixIcon;
    if (trailing == null && errorText != null) {
      trailing = const Icon(Icons.error_outline, color: AppColors.error);
    } else if (trailing == null && isValid) {
      trailing = const Icon(Icons.check_circle_outline, color: AppColors.success);
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: trailing,
      ),
    );
  }
}
