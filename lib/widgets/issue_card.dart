import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/issue_model.dart';
import '../theme/app_colors.dart';
import 'severity_badge.dart';
import 'status_chip.dart';

class IssueCard extends StatefulWidget {
  final Issue issue;
  final VoidCallback onTap;

  const IssueCard({
    super.key,
    required this.issue,
    required this.onTap,
  });

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _needsAttention = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    
    // Check si necesita atención (ej: abierto y pasaron > 4 hrs)
    final hoursSinceReport = DateTime.now().difference(widget.issue.reportedAt).inHours;
    _needsAttention = widget.issue.status == IssueStatus.open && hoursSinceReport >= 4;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (_needsAttention) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = SeverityHelper.getColor(widget.issue.severity);
    final isCritical = widget.issue.severity == IssueSeverity.critical;

    return Card(
      elevation: isCritical ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra lateral de severidad
              Container(width: 6, color: severityColor),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.issue.code ?? 'INC-${widget.issue.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Por: ${widget.issue.reporter}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.issue.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_needsAttention)
                            FadeTransition(
                              opacity: _pulseAnimation,
                              child: Container(
                                margin: const EdgeInsets.only(left: 8, top: 4),
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.issue.projectName ?? 'Proyecto'} • ${widget.issue.category} • ${widget.issue.location}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          StatusChip(status: widget.issue.status),
                          const SizedBox(width: 8),
                          SeverityBadge(severity: widget.issue.severity, showLabel: false),
                          const Spacer(),
                          if (widget.issue.photos.isNotEmpty) ...[
                            const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.textMedium),
                            const SizedBox(width: 2),
                            Text('${widget.issue.photos.length}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                            const SizedBox(width: 8),
                          ],
                          if (widget.issue.comments.isNotEmpty) ...[
                            const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textMedium),
                            const SizedBox(width: 2),
                            Text('${widget.issue.comments.length}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeago.format(widget.issue.reportedAt, locale: 'es'),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMedium),
                          ),
                          if (widget.issue.status == IssueStatus.open)
                            const Text(
                              'TOMAR ACCIÓN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
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
    );
  }
}
