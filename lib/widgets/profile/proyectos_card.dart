import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';

class ProyectosCard extends StatelessWidget {
  final List<ProyectoAsignado> proyectos;

  const ProyectosCard({Key? key, required this.proyectos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proyectos Asignados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            if (proyectos.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.folder_off_outlined, size: 48, color: mutedColor),
                    const SizedBox(height: 8),
                    Text('No tienes proyectos asignados', style: TextStyle(color: mutedColor)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: proyectos.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final p = proyectos[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.business, color: theme.colorScheme.primary),
                    ),
                    title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Cód: ${p.codigo} • Rol: ${p.rolProyecto}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
