import 'package:flutter/material.dart';

class ProjectRoleBadge extends StatelessWidget {
  final String? role;

  const ProjectRoleBadge({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    if (role == null || role!.isEmpty) return const SizedBox.shrink();

    Color bgColor;
    String displayRole = role!.toLowerCase();
    String label = role![0].toUpperCase() + role!.substring(1);

    switch (displayRole) {
      case 'supervisor':
        bgColor = const Color(0xFF2E7D32); // Verde
        break;
      case 'ingeniero':
        bgColor = const Color(0xFF1A237E); // Azul
        break;
      case 'gerente':
        bgColor = const Color(0xFFFF6D00); // Naranja
        break;
      case 'administrador':
        bgColor = const Color(0xFF6A1B9A); // Morado
        break;
      default:
        bgColor = Colors.grey.shade700; // Por defecto
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
