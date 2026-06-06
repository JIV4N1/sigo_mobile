import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';

class ActivityTimeline extends StatelessWidget {
  final List<ProjectActivity> activities;

  const ActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actividad Reciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Ver todo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(activity, index == (activities.length > 5 ? 4 : activities.length - 1));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ProjectActivity activity, bool isLast) {
    IconData icon;
    Color iconColor;
    switch (activity.type) {
      case 'report':
        icon = Icons.edit_document;
        iconColor = AppColors.primary;
        break;
      case 'photo':
        icon = Icons.camera_alt;
        iconColor = Colors.purple;
        break;
      case 'issue_new':
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.warning;
        break;
      case 'issue_resolved':
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case 'personnel':
        icon = Icons.person_add;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.info;
        iconColor = AppColors.textMedium;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              Icon(icon, size: 16, color: iconColor),
              if (!isLast)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.description, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(
                    timeago.format(activity.timestamp, locale: 'es'),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
