import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../widgets/project_detail/project_header.dart';
import '../widgets/project_detail/kpi_cards_row.dart';
import '../widgets/project_detail/trend_chart_card.dart';
import '../widgets/project_detail/project_action_buttons.dart';
import '../widgets/project_detail/activity_timeline.dart';
import '../widgets/project_detail/project_info_card.dart';
import 'issue_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  /// Objeto proyecto con datos básicos del dashboard.
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  bool _isRefreshing = false;
  bool _hasRefreshError = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  /// Pull-to-refresh: recarga los datos frescos desde la API.
  Future<void> _refreshProject() async {
    setState(() {
      _isRefreshing = true;
      _hasRefreshError = false;
    });

    try {
      final response =
          await ApiService.get(ApiConfig.proyectoDetail(_project.id));
      final data =
          response['data'] as Map<String, dynamic>? ?? response;
      final updatedProject = Project.fromJson(data);

      if (!mounted) return;
      setState(() {
        _project = updatedProject;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proyecto actualizado'),
          duration: Duration(seconds: 2),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _hasRefreshError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.critical,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _hasRefreshError = true;
      });
    }
  }

  void _shareDashboard() {
    String status = 'A Tiempo';
    if (_project.status == ProjectStatus.delayed) status = 'Retrasado';
    if (_project.status == ProjectStatus.critical) status = 'Crítico';

    final text = '''
🏗️ ${_project.name}
📍 ${_project.location}
📊 Avance: ${(_project.progress * 100).round()}%
⚠️ Incidencias: ${_project.activeIssues} (${_project.criticalIssues} críticas)
📅 Días: ${_project.daysElapsed}/${_project.totalDays}
🟢 Estado: $status
''';
    Share.share(text, subject: 'Estado del Proyecto: ${_project.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _refreshProject,
        color: AppColors.accent,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                ProjectHeader(project: _project),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_hasRefreshError)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.wifi_off,
                                size: 16, color: AppColors.warning),
                          ),
                        IconButton(
                          icon: const Icon(Icons.share, color: AppColors.primary),
                          onPressed: _shareDashboard,
                          tooltip: 'Compartir resumen',
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: KPICardsRow(project: _project)),
                SliverToBoxAdapter(child: TrendChartCard(project: _project)),
                SliverToBoxAdapter(child: ProjectActionButtons(project: _project)),
                SliverToBoxAdapter(
                  child: ActivityTimeline(activities: _project.timeline),
                ),
                SliverToBoxAdapter(
                  child: ProjectInfoCard(project: _project),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            // Indicador de recarga en curso
            if (_isRefreshing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueFormScreen(initialProject: _project),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
