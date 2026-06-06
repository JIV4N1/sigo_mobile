import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FormStepperHeader extends StatelessWidget {
  final int currentStep; // 0, 1, or 2

  const FormStepperHeader({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(0, 'Info'),
          _buildLine(0),
          _buildStep(1, 'Avance'),
          _buildLine(1),
          _buildStep(2, 'Evidencia'),
        ],
      ),
    );
  }

  Widget _buildStep(int stepIndex, String title) {
    bool isCompleted = stepIndex < currentStep;
    bool isActive = stepIndex == currentStep;
    
    Color circleColor = isCompleted ? AppColors.success : (isActive ? AppColors.accent : AppColors.border);
    Color textColor = isActive || isCompleted ? AppColors.textDark : AppColors.textMedium;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int fromStep) {
    bool isCompleted = fromStep < currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        color: isCompleted ? AppColors.success : AppColors.border,
      ),
    );
  }
}
