import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';
import '../project_role_badge.dart';

class ProjectHeader extends StatelessWidget {
  final Project project;

  const ProjectHeader({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (project.status) {
      case ProjectStatus.onTime:
        statusColor = AppColors.success;
        statusText = 'En Tiempo';
        break;
      case ProjectStatus.delayed:
        statusColor = AppColors.warning;
        statusText = 'Retrasado';
        break;
      case ProjectStatus.critical:
        statusColor = AppColors.critical;
        statusText = 'Crítico';
        break;
      case ProjectStatus.planned:
        statusColor = AppColors.textMedium;
        statusText = 'Planeado';
        break;
      case ProjectStatus.completed:
        statusColor = AppColors.primary;
        statusText = 'Completado';
        break;
      case ProjectStatus.archived:
        statusColor = AppColors.border;
        statusText = 'Archivado';
        break;
    }

    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'project_image_${project.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Placeholder for image
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, Color(0xFF0D144A)],
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (project.miRol != null && project.miRol!.isNotEmpty) const SizedBox(width: 8),
                        if (project.miRol != null && project.miRol!.isNotEmpty) ProjectRoleBadge(role: project.miRol),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.name,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.location,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
