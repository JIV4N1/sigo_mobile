import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';

class KPICardsRow extends StatelessWidget {
  final Project project;

  const KPICardsRow({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildProgressCard()),
          const SizedBox(width: 8),
          Expanded(child: _buildTimeCard()),
          const SizedBox(width: 8),
          Expanded(child: _buildIssuesCard()),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    Color progressColor;
    if (project.progress < 0.3) {
      progressColor = AppColors.critical;
    } else if (project.progress < 0.7) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    final percentage = (project.progress * 100).toInt();

    return _BaseKPICard(
      iconWidget: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 18,
                sections: [
                  PieChartSectionData(
                    value: project.progress,
                    color: progressColor,
                    radius: 6,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 1 - project.progress,
                    color: Colors.grey.shade200,
                    radius: 6,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      value: '$percentage%',
      label: 'Avance general',
    );
  }

  Widget _buildTimeCard() {
    int delay = project.daysElapsed > project.totalDays ? project.daysElapsed - project.totalDays : 0;
    
    return _BaseKPICard(
      iconWidget: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.timer_outlined, color: AppColors.primary),
      ),
      value: '${project.daysElapsed}/${project.totalDays}',
      label: 'Días transcurridos',
      subtitle: delay > 0 ? '$delay días de retraso' : null,
      subtitleColor: AppColors.critical,
    );
  }

  Widget _buildIssuesCard() {
    Color issuesColor;
    if (project.activeIssues == 0) {
      issuesColor = AppColors.success;
    } else if (project.activeIssues <= 5) {
      issuesColor = AppColors.warning;
    } else {
      issuesColor = AppColors.critical;
    }

    return _BaseKPICard(
      iconWidget: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: issuesColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.warning_amber_rounded, color: issuesColor),
      ),
      value: '${project.activeIssues}',
      label: 'Incidencias activas',
      subtitle: project.criticalIssues > 0 ? '${project.criticalIssues} críticas' : null,
      subtitleColor: AppColors.critical,
    );
  }
}

class _BaseKPICard extends StatelessWidget {
  final Widget iconWidget;
  final String value;
  final String label;
  final String? subtitle;
  final Color? subtitleColor;

  const _BaseKPICard({
    required this.iconWidget,
    required this.value,
    required this.label,
    this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            iconWidget,
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
