import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../models/issue_model.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../widgets/issue_card.dart';
import 'issue_detail_screen.dart';

class IssuesListScreen extends StatefulWidget {
  /// Si se proporciona, carga las incidencias de ese proyecto.
  final int? projectId;

  const IssuesListScreen({super.key, this.projectId});

  @override
  State<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  String _selectedFilter = 'Todas';
  String _sortOption = 'Más recientes';
  List<Issue> _allIssues = [];
  List<Issue> _filteredIssues = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _rol = 'supervisor';

  final List<String> _filters = [
    'Todas',
    'Abiertas',
    'En Progreso',
    'Resueltas',
    'Críticas',
    'Asignadas a mí',
  ];

  @override
  void initState() {
    super.initState();
    _loadRol();
    _loadData();
  }

  Future<void> _loadRol() async {
    final rol = await AuthService.getRol();
    if (mounted) setState(() => _rol = rol);
  }

  // ─── Carga de datos ───────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final url = widget.projectId != null
          ? ApiConfig.incidenciasPorProyecto(widget.projectId!)
          : ApiConfig.incidencias;

      // Pasar filtro activo como query param si aplica
      final queryParams = _buildQueryParams();
      final response = await ApiService.get(url, queryParams: queryParams);

      final rawData = response['data'];
      List<dynamic> list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        list = rawData['data'] as List<dynamic>? ?? [];
      } else {
        list = [];
      }

      final issues = list
          .map((e) => Issue.fromJson(e as Map<String, dynamic>))
          .toList();

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

  Map<String, String>? _buildQueryParams() {
    final params = <String, String>{};
    switch (_selectedFilter) {
      case 'Abiertas':
        params['estado'] = 'abierta';
        break;
      case 'En Progreso':
        params['estado'] = 'en_progreso';
        break;
      case 'Resueltas':
        params['estado'] = 'resuelta';
        break;
      case 'Críticas':
        params['severidad'] = 'critica';
        break;
    }
    return params.isEmpty ? null : params;
  }

  // ─── Filtros locales ──────────────────────────────────────────────────────────

  void _applyFilters() {
    List<Issue> temp = List.from(_allIssues);

    switch (_selectedFilter) {
      case 'Abiertas':
        temp = temp.where((i) => i.status == IssueStatus.open).toList();
        break;
      case 'En Progreso':
        temp = temp.where((i) => i.status == IssueStatus.inProgress).toList();
        break;
      case 'Resueltas':
        temp = temp.where((i) => i.status == IssueStatus.resolved).toList();
        break;
      case 'Críticas':
        temp = temp.where((i) => i.severity == IssueSeverity.critical).toList();
        break;
      case 'Asignadas a mí':
        // Filtrar por nombre del usuario autenticado (comparación local)
        temp = temp.where((i) => i.assignedTo != null).toList();
        break;
    }

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
    final openCount =
        _allIssues.where((i) => i.status == IssueStatus.open).length;
    final canReport =
        _rol == 'supervisor' || _rol == 'ingeniero' || _rol == 'gerente';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Incidencias',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          if (canReport)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ActionChip(
                backgroundColor: AppColors.accent,
                labelStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                label: const Text('Reportar nueva'),
                avatar: const Icon(Icons.add, color: Colors.white, size: 16),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Abriendo formulario de nueva incidencia...'),
                  ));
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
                      color: AppColors.warning.withOpacity(0.1),
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
          // ── Filtros ────────────────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                        _applyFilters();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // ── Ordenamiento ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ordenar por:',
                    style: TextStyle(
                        color: AppColors.textMedium, fontSize: 13)),
                DropdownButton<String>(
                  value: _sortOption,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppColors.textDark),
                  underline: const SizedBox(),
                  style: const TextStyle(
                      color: AppColors.textDark,
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
          Expanded(child: _buildList(canReport)),
        ],
      ),
    );
  }

  Widget _buildList(bool canReport) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMedium)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.accent));
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
                    setState(() => _selectedFilter = 'Todas');
                    _applyFilters();
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
                  openColor: AppColors.surface,
                  closedBuilder: (context, action) =>
                      IssueCard(issue: issue, onTap: action),
                  openBuilder: (context, action) => IssueDetailScreen(
                    issue: issue,
                    rol: _rol,
                  ),
                );
              },
            ),
    );
  }
}
