import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../theme/app_colors.dart';

class SeverityBadge extends StatelessWidget {
  final IssueSeverity severity;
  final bool showLabel;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    String label;
    IconData icon;

    switch (severity) {
      case IssueSeverity.critical:
        bgColor = const Color(0xFFFFEBEE);
        fgColor = const Color(0xFFD32F2F);
        label = 'Crítica';
        icon = Icons.error_outline;
        break;
      case IssueSeverity.high:
        bgColor = const Color(0xFFFFF3E0);
        fgColor = const Color(0xFFFF6D00);
        label = 'Alta';
        icon = Icons.warning_amber_rounded;
        break;
      case IssueSeverity.medium:
        bgColor = const Color(0xFFFFFDE7);
        fgColor = const Color(0xFFFBC02D);
        label = 'Media';
        icon = Icons.info_outline;
        break;
      case IssueSeverity.low:
        bgColor = const Color(0xFFE8F5E9);
        fgColor = const Color(0xFF388E3C);
        label = 'Baja';
        icon = Icons.check_circle_outline;
        break;
    }

    if (!showLabel) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          label[0],
          style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fgColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fgColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SeverityHelper {
  static Color getColor(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return const Color(0xFFD32F2F);
      case IssueSeverity.high:
        return const Color(0xFFFF6D00);
      case IssueSeverity.medium:
        return const Color(0xFFFBC02D);
      case IssueSeverity.low:
        return const Color(0xFF388E3C);
    }
  }
}
