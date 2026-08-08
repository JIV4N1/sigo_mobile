import 'package:flutter/material.dart';
import '../../services/theme_controller.dart';

class PreferenciasCard extends StatelessWidget {
  const PreferenciasCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferencias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: ThemeController.instance,
              builder: (context, _) {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Modo Oscuro', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: ThemeController.instance.isDarkMode,
                  onChanged: (value) => ThemeController.instance.setDarkMode(value),
                  secondary: const Icon(Icons.dark_mode_outlined),
                );
              },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notificaciones Push', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Próximamente', style: TextStyle(color: Colors.orange)),
              value: false,
              onChanged: null,
              secondary: const Icon(Icons.notifications_none),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sincronización Automática', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Próximamente', style: TextStyle(color: Colors.orange)),
              value: false,
              onChanged: null,
              secondary: const Icon(Icons.sync),
            ),
          ],
        ),
      ),
    );
  }
}
