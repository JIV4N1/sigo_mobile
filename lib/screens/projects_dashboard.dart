import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../widgets/project_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/sigo_bottom_nav.dart';
import '../widgets/sigo_button.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../config/api_config.dart';
import 'issues_list_screen.dart';
import 'project_detail_screen.dart';
import 'report_form_screen.dart';
import 'profile_screen.dart';
import 'attendance_screen.dart';
import 'validar_reportes_screen.dart';
import 'gastos/gastos_list_screen.dart';

class _NavEntry {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavEntry(this.route, this.icon, this.activeIcon, this.label);
}

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
      debugPrint('Iniciando carga de proyectos asignados...');
      final projects = await ProjectService.getProyectosAsignados();
      debugPrint('Proyectos cargados exitosamente: ${projects.length}');

      if (!mounted) return;
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
        _isLoading = false;
      });
      _applySearch();
    } on ApiException catch (e) {
      debugPrint('ApiException al cargar proyectos: ${e.message}');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e, stackTrace) {
      debugPrint('Error inesperado al cargar proyectos: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error inesperado al cargar proyectos: $e';
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

    final route = items[index].route;
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
      case 'gastos':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GastosListScreen()));
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

  List<_NavEntry> _getNavItems() {
    switch (widget.rol) {
      case 'supervisor':
        return const [
          _NavEntry('dashboard', Icons.grid_view_outlined, Icons.grid_view, 'Proyectos'),
          _NavEntry('reporte', Icons.fact_check_outlined, Icons.fact_check, 'Avance'),
          _NavEntry('incidencias', Icons.warning_amber_outlined, Icons.warning_amber_rounded, 'Incidencias'),
          _NavEntry('gastos', Icons.receipt_long_outlined, Icons.receipt_long, 'Gastos'),
          _NavEntry('asistencia', Icons.access_time, Icons.access_time_filled, 'Asistencia'),
          _NavEntry('perfil', Icons.person_outline, Icons.person, 'Perfil'),
        ];
      case 'ingeniero':
        return const [
          _NavEntry('dashboard', Icons.grid_view_outlined, Icons.grid_view, 'Proyectos'),
          _NavEntry('reporte', Icons.fact_check_outlined, Icons.fact_check, 'Avance'),
          _NavEntry('incidencias', Icons.warning_amber_outlined, Icons.warning_amber_rounded, 'Incidencias'),
          _NavEntry('gastos', Icons.receipt_long_outlined, Icons.receipt_long, 'Gastos'),
          _NavEntry('asistencia', Icons.access_time, Icons.access_time_filled, 'Asistencia'),
          _NavEntry('perfil', Icons.person_outline, Icons.person, 'Perfil'),
        ];
      case 'gerente':
        return const [
          _NavEntry('dashboard', Icons.grid_view_outlined, Icons.grid_view, 'Proyectos'),
          _NavEntry('incidencias', Icons.warning_amber_outlined, Icons.warning_amber_rounded, 'Incidencias'),
          _NavEntry('gastos', Icons.receipt_long_outlined, Icons.receipt_long, 'Gastos'),
          _NavEntry('asistencia', Icons.access_time, Icons.access_time_filled, 'Asistencia'),
          _NavEntry('validar', Icons.verified_outlined, Icons.verified, 'Validar'),
          _NavEntry('perfil', Icons.person_outline, Icons.person, 'Perfil'),
        ];
      case 'administrador':
      default:
        return const [
          _NavEntry('dashboard', Icons.grid_view_outlined, Icons.grid_view, 'Proyectos'),
          _NavEntry('incidencias', Icons.warning_amber_outlined, Icons.warning_amber_rounded, 'Incidencias'),
          _NavEntry('gastos', Icons.receipt_long_outlined, Icons.receipt_long, 'Gastos'),
          _NavEntry('asistencia', Icons.access_time, Icons.access_time_filled, 'Asistencia'),
          _NavEntry('validar', Icons.verified_outlined, Icons.verified, 'Reportes'),
          _NavEntry('perfil', Icons.person_outline, Icons.person, 'Perfil'),
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
        final theme = Theme.of(context);
        return StatefulBuilder(builder: (context, setStateSheet) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por estado',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : theme.colorScheme.onSurface),
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
    final showFab = widget.rol == 'supervisor' || widget.rol == 'ingeniero';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(child: _buildBody(theme)),
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
      bottomNavigationBar: SigoBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _navigateByNavIndex,
        items: [
          for (final item in navItems)
            SigoNavItem(icon: item.icon, activeIcon: item.activeIcon, label: item.label),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.rol == 'gerente' || widget.rol == 'administrador'
                ? 'Todos los Proyectos'
                : 'Mis Proyectos',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (_filteredProjects.isNotEmpty && !_isLoading)
            Text(
              '${_filteredProjects.length} proyecto(s)',
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
        ],
      ),
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: AppColors.accent,
          child: Text(
            _iniciales.isEmpty ? 'U' : _iniciales,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final borderColor = theme.dividerColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar proyecto...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedStatusFilter != 'Todos'
                    ? theme.colorScheme.primary
                    : borderColor,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
              onPressed: _showFilterBottomSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 72, color: theme.dividerColor),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SigoButton(
                label: 'Reintentar',
                icon: Icons.refresh,
                onPressed: _loadProjects,
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
            Icon(Icons.architecture, size: 80, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              _selectedStatusFilter != 'Todos'
                  ? 'No hay proyectos con estado "$_selectedStatusFilter"'
                  : _searchController.text.isNotEmpty
                      ? 'No se encontraron proyectos'
                      : 'No tienes obras asignadas',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
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
