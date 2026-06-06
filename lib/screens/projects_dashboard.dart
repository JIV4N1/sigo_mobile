import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../widgets/project_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/sigo_bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import 'issues_list_screen.dart';
import 'project_detail_screen.dart';
import 'report_form_screen.dart';
import 'profile_screen.dart';
import 'attendance_screen.dart';
import 'validar_reportes_screen.dart';

class ProjectsDashboard extends StatefulWidget {
  /// Rol del usuario autenticado en minúsculas.
  final String rol;

  const ProjectsDashboard({super.key, required this.rol});

  @override
  State<ProjectsDashboard> createState() => _ProjectsDashboardState();
}

class _ProjectsDashboardState extends State<ProjectsDashboard> {
  int _currentNavIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];

  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'Todos';
  String _iniciales = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadIniciales();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applySearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIniciales() async {
    final ini = await AuthService.getIniciales();
    if (mounted) setState(() => _iniciales = ini);
  }

  // ─── Carga de datos ───────────────────────────────────────────────────────────

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get(ApiConfig.proyectos);

      // La API retorna: { "status": "success", "data": [...] }
      final rawData = response['data'];
      List<dynamic> list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        // Paginación: { "data": { "data": [...] } }
        list = rawData['data'] as List<dynamic>? ?? [];
      } else {
        list = [];
      }

      final projects = list
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
        _isLoading = false;
      });
      _applySearch();
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
        _errorMessage = 'Error inesperado al cargar proyectos.';
      });
    }
  }

  // ─── Filtros y búsqueda ───────────────────────────────────────────────────────

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    List<Project> filtered = List.from(_projects);

    // Filtro por estado
    if (_selectedStatusFilter != 'Todos') {
      final statusMap = {
        'A Tiempo': ProjectStatus.onTime,
        'Retrasado': ProjectStatus.delayed,
        'Crítico': ProjectStatus.critical,
        'Planeado': ProjectStatus.planned,
        'Completado': ProjectStatus.completed,
      };
      final targetStatus = statusMap[_selectedStatusFilter];
      if (targetStatus != null) {
        filtered = filtered.where((p) => p.status == targetStatus).toList();
      }
    }

    // Búsqueda por nombre o ubicación
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.location.toLowerCase().contains(query) ||
            p.client.toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _filteredProjects = filtered);
  }

  // ─── Navegación ───────────────────────────────────────────────────────────────

  void _onProjectTap(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _navigateByNavIndex(int index) {
    final items = _getNavItems();
    if (index >= items.length) return;

    final route = items[index]['route'] as String;
    switch (route) {
      case 'dashboard':
        setState(() => _currentNavIndex = index);
        break;
      case 'reporte':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ReportFormScreen()));
        break;
      case 'incidencias':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const IssuesListScreen()));
        break;
      case 'validar':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ValidarReportesScreen()));
        break;
      case 'perfil':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      case 'asistencia':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AttendanceScreen()));
        break;
    }
  }

  List<Map<String, dynamic>> _getNavItems() {
    switch (widget.rol) {
      case 'supervisor':
        return [
          {'route': 'dashboard', 'icon': Icons.grid_view, 'label': 'Proyectos'},
          {'route': 'reporte', 'icon': Icons.fact_check_outlined, 'label': 'Avance'},
          {'route': 'incidencias', 'icon': Icons.warning_amber_rounded, 'label': 'Incidencias'},
          {'route': 'perfil', 'icon': Icons.person_outline, 'label': 'Perfil'},
          {'route': 'asistencia', 'icon': Icons.access_time, 'label': 'Asistencia'},
        ];
      case 'ingeniero':
        return [
          {'route': 'dashboard', 'icon': Icons.grid_view, 'label': 'Proyectos'},
          {'route': 'incidencias', 'icon': Icons.warning_amber_rounded, 'label': 'Incidencias'},
          {'route': 'perfil', 'icon': Icons.person_outline, 'label': 'Perfil'},
          {'route': 'asistencia', 'icon': Icons.access_time, 'label': 'Asistencia'},
        ];
      case 'gerente':
        return [
          {'route': 'dashboard', 'icon': Icons.grid_view, 'label': 'Proyectos'},
          {'route': 'incidencias', 'icon': Icons.warning_amber_rounded, 'label': 'Incidencias'},
          {'route': 'validar', 'icon': Icons.verified_outlined, 'label': 'Validar'},
          {'route': 'perfil', 'icon': Icons.person_outline, 'label': 'Perfil'},
          {'route': 'asistencia', 'icon': Icons.access_time, 'label': 'Asistencia'},
        ];
      case 'administrador':
      default:
        return [
          {'route': 'dashboard', 'icon': Icons.grid_view, 'label': 'Proyectos'},
          {'route': 'perfil', 'icon': Icons.person_outline, 'label': 'Perfil'},
          {'route': 'asistencia', 'icon': Icons.access_time, 'label': 'Asistencia'},
        ];
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSheet) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por estado',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    'Todos', 'A Tiempo', 'Retrasado', 'Crítico', 'Planeado', 'Completado'
                  ].map((f) {
                    final sel = _selectedStatusFilter == f;
                    return ChoiceChip(
                      label: Text(f),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : AppColors.textDark),
                      onSelected: (_) {
                        setStateSheet(() {});
                        setState(() {
                          _selectedStatusFilter = f;
                          _applySearch();
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems();
    // Índice del dashboard siempre es 0
    final showFab = widget.rol == 'supervisor';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportFormScreen()),
              ),
              backgroundColor: AppColors.accent,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null,
      floatingActionButtonLocation: showFab
          ? FloatingActionButtonLocation.centerDocked
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _navigateByNavIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMedium,
        items: navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item['icon'] as IconData),
            label: item['label'] as String,
          );
        }).toList(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.rol == 'gerente' || widget.rol == 'administrador'
                ? 'Todos los Proyectos'
                : 'Mis Proyectos',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (_filteredProjects.isNotEmpty && !_isLoading)
            Text(
              '${_filteredProjects.length} proyecto(s)',
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 12,
              ),
            ),
        ],
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            _iniciales.isEmpty ? 'U' : _iniciales,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar proyecto...',
                  hintStyle: TextStyle(color: AppColors.textMedium),
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textMedium),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: _selectedStatusFilter != 'Todos'
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedStatusFilter != 'Todos'
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _selectedStatusFilter != 'Todos'
                    ? AppColors.primary
                    : AppColors.primary,
              ),
              onPressed: _showFilterBottomSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 72, color: AppColors.border),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProjects,
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
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: 4,
        itemBuilder: (context, index) => const ShimmerLoadingCard(),
      );
    }

    if (_filteredProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.architecture, size: 80, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              _selectedStatusFilter != 'Todos'
                  ? 'No hay proyectos con estado "$_selectedStatusFilter"'
                  : _searchController.text.isNotEmpty
                      ? 'No se encontraron proyectos'
                      : 'No tienes proyectos asignados',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.textMedium),
            ),
            if (_selectedStatusFilter != 'Todos' ||
                _searchController.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedStatusFilter = 'Todos');
                  _applySearch();
                },
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _filteredProjects.length,
        itemBuilder: (context, index) {
          final project = _filteredProjects[index];
          return ProjectCard(
            project: project,
            onTap: () => _onProjectTap(project),
          );
        },
      ),
    );
  }
}
