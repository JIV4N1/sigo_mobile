import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final IssueStatus status;

  const StatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    String label;

    switch (status) {
      case IssueStatus.open:
        bgColor = AppColors.primary.withOpacity(0.1);
        fgColor = AppColors.primary;
        label = 'Abierto';
        break;
      case IssueStatus.inProgress:
        bgColor = AppColors.accent.withOpacity(0.1);
        fgColor = AppColors.accent;
        label = 'En Progreso';
        break;
      case IssueStatus.resolved:
        bgColor = AppColors.success.withOpacity(0.1);
        fgColor = AppColors.success;
        label = 'Resuelto';
        break;
      case IssueStatus.closed:
        bgColor = Colors.grey.shade200;
        fgColor = Colors.grey.shade700;
        label = 'Cerrado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fgColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
