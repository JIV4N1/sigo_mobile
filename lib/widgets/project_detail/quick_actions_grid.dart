import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/report_form_screen.dart';
import '../../screens/issues_list_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5, // Botones anchos
        children: [
          _ActionBtn(
            icon: Icons.post_add,
            label: 'Nuevo Reporte\nde Avance',
            bgColor: Colors.blue.shade50,
            fgColor: AppColors.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormScreen()));
            },
          ),
          _ActionBtn(
            icon: Icons.flag_outlined,
            label: 'Reportar\nIncidencia',
            bgColor: Colors.orange.shade50,
            fgColor: AppColors.accent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IssuesListScreen()));
            },
          ),
          _ActionBtn(
            icon: Icons.photo_library_outlined,
            label: 'Ver Galería\nde Fotos',
            bgColor: Colors.grey.shade100,
            fgColor: AppColors.textDark,
            onTap: () {
              // Va a PhotoManagementScreen cuando se conecte
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo Galería de Fotos...')));
            },
          ),
          _ActionBtn(
            icon: Icons.groups_outlined,
            label: 'Equipo en\nObra',
            bgColor: Colors.green.shade50,
            fgColor: AppColors.success,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cargando lista de personal...')));
            },
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(icon, color: fgColor, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
