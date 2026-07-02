import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';
import '../../screens/report_form_screen.dart';
import '../../screens/issues_list_screen.dart';
import '../../screens/validar_reportes_screen.dart';

class ProjectActionButtons extends StatelessWidget {
  final Project project;

  const ProjectActionButtons({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final allowedActions = project.getAccionesPermitidas();

    if (allowedActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> buttons = [];

    if (allowedActions.contains('reporte_diario')) {
      buttons.add(
        _ActionBtn(
          icon: Icons.post_add,
          label: 'Reporte\nDiario',
          bgColor: Colors.blue.shade50,
          fgColor: AppColors.primary,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormScreen()));
          },
        ),
      );
    }

    if (allowedActions.contains('incidencias') || allowedActions.contains('atender_incidencias')) {
      buttons.add(
        _ActionBtn(
          icon: Icons.flag_outlined,
          label: 'Incidencias',
          bgColor: Colors.orange.shade50,
          fgColor: AppColors.accent,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const IssuesListScreen()));
          },
        ),
      );
    }

    if (allowedActions.contains('asistencia')) {
      buttons.add(
        _ActionBtn(
          icon: Icons.access_time,
          label: 'Asistencia',
          bgColor: Colors.green.shade50,
          fgColor: AppColors.success,
          onTap: () {
            // Se asume que el usuario sabe cómo llegar a Asistencia, si no la abrimos aquí:
            // Por el momento mostramos un SnackBar de Asistencia local a la obra
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abriendo Registro de Asistencia...')),
            );
          },
        ),
      );
    }

    if (allowedActions.contains('kpis')) {
      buttons.add(
        _ActionBtn(
          icon: Icons.analytics_outlined,
          label: 'Ver KPIs',
          bgColor: Colors.purple.shade50,
          fgColor: Colors.purple,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Los KPIs se visualizan en los gráficos del dashboard.')),
            );
          },
        ),
      );
    }

    if (allowedActions.contains('validar_reportes')) {
      buttons.add(
        _ActionBtn(
          icon: Icons.verified_outlined,
          label: 'Validar\nReportes',
          bgColor: Colors.teal.shade50,
          fgColor: Colors.teal,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ValidarReportesScreen()));
          },
        ),
      );
    }

    if (allowedActions.contains('asignar_incidencias')) {
      buttons.add(
        _ActionBtn(
          icon: Icons.assignment_ind_outlined,
          label: 'Asignar\nIncidencias',
          bgColor: Colors.indigo.shade50,
          fgColor: Colors.indigo,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad de asignar incidencias en desarrollo...')),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: buttons,
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
