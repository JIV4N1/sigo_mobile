import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SigoBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SigoBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_filled,
              label: 'Inicio',
              index: 0,
            ),
            // Espacio para el FAB flotante central
            const SizedBox(width: 48),
            _buildNavItem(
              icon: Icons.warning_amber_rounded,
              label: 'Incidencias',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textMedium;

    return InkWell(
      onTap: () => onTap(index),
      child: Semantics(
        label: label,
        selected: isSelected,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
