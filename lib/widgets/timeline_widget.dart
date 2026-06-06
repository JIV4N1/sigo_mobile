import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/issue_model.dart';
import '../theme/app_colors.dart';

class TimelineWidget extends StatelessWidget {
  final List<IssueTimelineEntry> entries;

  const TimelineWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Ordenar de más reciente a más antiguo
    final sortedEntries = List<IssueTimelineEntry>.from(entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final isLast = index == sortedEntries.length - 1;
        
        IconData icon;
        Color iconColor;
        switch (entry.type) {
          case 'report':
            icon = Icons.add_circle_outline;
            iconColor = AppColors.primary;
            break;
          case 'status_change':
            icon = Icons.sync;
            iconColor = AppColors.accent;
            break;
          case 'assignment':
            icon = Icons.person_add_alt_1;
            iconColor = AppColors.success;
            break;
          default:
            icon = Icons.info_outline;
            iconColor = AppColors.textMedium;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 14, color: iconColor),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.text, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(
                        timeago.format(entry.timestamp, locale: 'es'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
