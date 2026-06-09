import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_colors.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (project.status) {
      case ProjectStatus.onTime:
        return AppColors.success;
      case ProjectStatus.delayed:
        return AppColors.warning;
      case ProjectStatus.critical:
        return AppColors.critical;
      case ProjectStatus.planned:
        return AppColors.textMedium;
      case ProjectStatus.completed:
        return AppColors.primary;
      case ProjectStatus.archived:
        return AppColors.border;
    }
  }

  String _getStatusText() {
    switch (project.status) {
      case ProjectStatus.onTime:
        return 'A Tiempo';
      case ProjectStatus.delayed:
        return 'Retrasado';
      case ProjectStatus.critical:
        return 'Crítico';
      case ProjectStatus.planned:
        return 'Planeado';
      case ProjectStatus.completed:
        return 'Completado';
      case ProjectStatus.archived:
        return 'Archivado';
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return AppColors.critical;
    if (progress <= 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final progressColor = _getProgressColor(project.progress);
    final progressPercent = (project.progress * 100).toInt();

    return Dismissible(
      key: Key(project.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        color: AppColors.accent,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Nuevo Reporte',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // // TODO: Implementar con datos reales
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Acción rápida: Nuevo reporte para ${project.name}')),
        );
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () {
          _showContextMenu(context);
        },
        child: Semantics(
          label: 'Proyecto ${project.name}, Estado: ${_getStatusText()}, $progressPercent por ciento completado',
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: statusColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Hero(
                                  tag: 'project-title-${project.id}',
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Text(
                                      project.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: statusColor, width: 1),
                                ),
                                child: Text(
                                  _getStatusText(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppColors.textMedium),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  project.location,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.textMedium),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_formatDate(project.startDate)} - ${_formatDate(project.endDate)}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: project.progress,
                                    minHeight: 8,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$progressPercent%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCompactIndicator(
                                icon: Icons.camera_alt_outlined,
                                text: '${project.photosCount} fotos hoy',
                              ),
                              _buildCompactIndicator(
                                icon: Icons.warning_amber_rounded,
                                text: '${project.issuesCount} incidencias',
                              ),
                              _buildCompactIndicator(
                                icon: Icons.people_outline,
                                text: '${project.workersCount} personal',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIndicator({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMedium),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Ver en mapa'),
                onTap: () {
                  Navigator.pop(context);
                  // // TODO: Implementar con datos reales
                  print('Ver en mapa: ${project.location}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Llamar a encargado'),
                onTap: () {
                  Navigator.pop(context);
                  // // TODO: Implementar con datos reales
                  print('Llamar a encargado del proyecto: ${project.name}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  // // TODO: Implementar con datos reales
                  print('Compartiendo proyecto: ${project.name}');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
