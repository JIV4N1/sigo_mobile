import 'package:flutter/material.dart';

class PreferenciasCard extends StatelessWidget {
  const PreferenciasCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo Oscuro', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Próximamente', style: TextStyle(color: Colors.orange)),
              value: false,
              onChanged: null,
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notificaciones Push', style: TextStyle(fontWeight: FontWeight.w500)),
              value: false,
              onChanged: null,
              secondary: const Icon(Icons.notifications_none),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sincronización Automática', style: TextStyle(fontWeight: FontWeight.w500)),
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
