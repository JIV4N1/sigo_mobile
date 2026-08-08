import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../models/issue_model.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../widgets/issue_card.dart';
import '../widgets/sigo_button.dart';
import 'issue_detail_screen.dart';
import 'issue_form_screen.dart';
import '../models/project_model.dart';
import '../services/incidencia_service.dart';
import '../widgets/shimmer_loading.dart';

class IssuesListScreen extends StatefulWidget {
  /// Si se proporciona, carga las incidencias de ese proyecto.
  final int? projectId;

  const IssuesListScreen({super.key, this.projectId});

  @override
  State<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  String _selectedStatus = 'Todas';
  String _selectedSeverity = 'Todas';
  String _sortOption = 'Más recientes';
  List<Issue> _allIssues = [];
  List<Issue> _filteredIssues = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _rol = 'supervisor';

  final List<String> _statusFilters = [
    'Todas',
    'Abiertas',
    'En Progreso',
    'Resueltas',
  ];

  final List<String> _severityFilters = [
    'Todas',
    'Baja',
    'Media',
    'Alta',
    'Crítica',
  ];

  @override
  void initState() {
    super.initState();
    _loadRolAndData();
  }

  Future<void> _loadRolAndData() async {
    await _loadRol();
    _loadData();
  }

  Future<void> _loadRol() async {
    final rol = await AuthService.getRol();
    if (mounted) setState(() => _rol = rol);
  }

  String? _getApiStatus(String status) {
    switch (status) {
      case 'Abiertas': return 'abierta';
      case 'En Progreso': return 'en_progreso';
      case 'Resueltas': return 'resuelta';
      default: return null;
    }
  }

  String? _getApiSeverity(String severity) {
    switch (severity) {
      case 'Baja': return 'baja';
      case 'Media': return 'media';
      case 'Alta': return 'alta';
      case 'Crítica': return 'critica';
      default: return null;
    }
  }

  // ─── Carga de datos ───────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final apiStatus = _getApiStatus(_selectedStatus);
      final apiSeverity = _getApiSeverity(_selectedSeverity);
      List<Issue> issues;

      if (widget.projectId != null) {
        issues = await IncidenciaService.getIncidenciasPorProyecto(
          widget.projectId!,
          estado: apiStatus,
          severidad: apiSeverity,
        );
      } else {
        if (_rol == 'administrador' || _rol == 'gerente') {
          issues = await IncidenciaService.getIncidencias(
            estado: apiStatus,
            severidad: apiSeverity,
          );
        } else if (_rol == 'ingeniero') {
          issues = await IncidenciaService.getIncidenciasAsignadas(
            estado: apiStatus,
            severidad: apiSeverity,
          );
        } else {
          issues = await IncidenciaService.getIncidencias(
            estado: apiStatus,
            severidad: apiSeverity,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _allIssues = issues;
        _isLoading = false;
      });
      _applyFilters();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error inesperado al cargar incidencias.';
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _applyFilters() {
    List<Issue> temp = List.from(_allIssues);

    switch (_sortOption) {
      case 'Más antiguas':
        temp.sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
        break;
      case 'Mayor severidad':
        temp.sort((a, b) => a.severity.index.compareTo(b.severity.index));
        break;
      case 'Menor severidad':
        temp.sort((a, b) => b.severity.index.compareTo(a.severity.index));
        break;
      default:
        temp.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    }

    setState(() => _filteredIssues = temp);
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openCount =
        _allIssues.where((i) => i.status == IssueStatus.open).length;
    final canReport = _rol == 'supervisor' ||
        _rol == 'ingeniero' ||
        _rol == 'gerente' ||
        _rol == 'administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidencias'),
        actions: [
          if (canReport)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ActionChip(
                backgroundColor: theme.colorScheme.secondary,
                labelStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                label: const Text('Reportar nueva'),
                avatar: const Icon(Icons.add, color: Colors.white, size: 16),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IssueFormScreen(
                        initialProject: widget.projectId != null
                            ? Project(
                                id: widget.projectId!,
                                name: 'Proyecto',
                                status: ProjectStatus.onTime,
                                location: '',
                                startDate: DateTime.now(),
                                endDate: DateTime.now(),
                                progress: 0,
                                photosCount: 0,
                                issuesCount: 0,
                                workersCount: 0,
                                daysElapsed: 0,
                                totalDays: 0,
                                activeIssues: 0,
                                criticalIssues: 0,
                                weeklyProgress: [],
                                timeline: [],
                                client: '',
                                contract: '',
                                budget: '',
                                manager: '',
                              )
                            : null, // Si es desde lista global, se pasa null
                      ),
                    ),
                  );
                  _refreshData();
                },
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$openCount abiertas',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filtros Estado ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estado:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontSize: 12),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = filter);
                        _loadData();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // ── Filtros Severidad ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Severidad:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _severityFilters.length,
              itemBuilder: (context, index) {
                final filter = _severityFilters[index];
                final isSelected = _selectedSeverity == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontSize: 12),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedSeverity = filter);
                        _loadData();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // ── Ordenamiento ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ordenar por:', style: theme.textTheme.labelMedium),
                DropdownButton<String>(
                  value: _sortOption,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: const SizedBox(),
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _sortOption = v);
                      _applyFilters();
                    }
                  },
                  items: <String>[
                    'Más recientes',
                    'Más antiguas',
                    'Mayor severidad',
                    'Menor severidad'
                  ]
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                ),
              ],
            ),
          ),

          // ── Lista ──────────────────────────────────────────────────────────────
          Expanded(child: _buildList(theme)),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: theme.dividerColor),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              SigoButton(label: 'Reintentar', icon: Icons.refresh, onPressed: _loadData),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) => const ShimmerLoadingCard(),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.accent,
      child: _filteredIssues.isEmpty
          ? ListView(children: [
              const SizedBox(height: 80),
              const Icon(Icons.check_circle_outline,
                  size: 80, color: AppColors.success),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'No hay incidencias que coincidan',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'Todas';
                      _selectedSeverity = 'Todas';
                    });
                    _loadData();
                  },
                  child: const Text('Limpiar filtros'),
                ),
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: _filteredIssues.length,
              itemBuilder: (context, index) {
                final issue = _filteredIssues[index];
                return OpenContainer(
                  transitionType: ContainerTransitionType.fadeThrough,
                  closedElevation: 0,
                  closedColor: Colors.transparent,
                  openColor: theme.colorScheme.surface,
                  closedBuilder: (context, action) =>
                      IssueCard(issue: issue, onTap: action),
                  openBuilder: (context, action) => IssueDetailScreen(
                    issue: issue,
                    rol: _rol,
                    fallbackProjectId: widget.projectId,
                  ),
                );
              },
            ),
    );
  }
}
