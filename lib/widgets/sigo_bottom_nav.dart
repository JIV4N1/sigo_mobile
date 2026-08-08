import 'package:flutter/material.dart';

/// Item de [SigoBottomNav]. [activeIcon] se usa cuando el tab está
/// seleccionado (relleno); [icon] cuando no lo está (outline).
class SigoNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const SigoNavItem({required this.icon, this.activeIcon, required this.label});
}

/// BottomNavigationBar estándar de SIGO: sombra sutil, íconos
/// outline/filled según selección, color activo = acento del tema.
class SigoBottomNav extends StatelessWidget {
  final List<SigoNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SigoBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;

    return Container(
      decoration: BoxDecoration(
        color: navTheme.backgroundColor ?? theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: navTheme.selectedItemColor,
          unselectedItemColor: navTheme.unselectedItemColor,
          items: [
            for (var i = 0; i < items.length; i++)
              BottomNavigationBarItem(
                icon: Icon(i == currentIndex
                    ? (items[i].activeIcon ?? items[i].icon)
                    : items[i].icon),
                label: items[i].label,
              ),
          ],
        ),
      ),
    );
  }
}
