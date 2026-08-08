import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../services/api_service.dart';
import '../services/reportes_service.dart';
import '../theme/app_colors.dart';
import '../widgets/reporte_card.dart';
import '../widgets/sigo_button.dart';
import '../widgets/validacion_bottom_sheet.dart';

class ValidarReportesScreen extends StatefulWidget {
  const ValidarReportesScreen({Key? key}) : super(key: key);

  @override
  State<ValidarReportesScreen> createState() => _ValidarReportesScreenState();
}

class _ValidarReportesScreenState extends State<ValidarReportesScreen> {
  String _filtroActual = 'Todos';
  bool _isLoading = true;
  String? _error;
  List<Reporte> _reportes = [];

  final List<String> _filtros = ['Todos', 'Pendientes', 'Aprobados', 'Rechazados'];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  String? _mapFiltroToApiEstado(String filtro) {
    switch (filtro) {
      case 'Pendientes':
        return 'pendiente';
      case 'Aprobados':
        return 'aprobado';
      case 'Rechazados':
        return 'rechazado';
      default:
        return null; // 'Todos'
    }
  }

  Future<void> _cargarReportes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reportes = await ReportesService.getReportes(
        estado: _mapFiltroToApiEstado(_filtroActual),
      );
      if (!mounted) return;
      setState(() {
        _reportes = reportes;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar reportes';
        _isLoading = false;
      });
    }
  }

  Future<void> _validarReporte(Reporte reporte, String nuevoEstado, String notas) async {
    try {
      await ReportesService.validarReporte(
        int.parse(reporte.id),
        estado: nuevoEstado,
        notas: notas,
      );

      if (!mounted) return;
      // Recargamos desde el backend en vez de mutar localmente, para reflejar
      // el estado real (el backend pudo aplicar reglas adicionales).
      await _cargarReportes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte ${nuevoEstado.toLowerCase()} exitosamente'),
          backgroundColor: nuevoEstado == 'aprobado' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _mostrarBottomSheet(Reporte reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ValidacionBottomSheet(
        reporte: reporte,
        onValidar: (estado, notas) => _validarReporte(reporte, estado, notas),
      ),
    );
  }

  List<Reporte> get _reportesFiltrados {
    if (_filtroActual == 'Todos') return _reportes;
    return _reportes.where((r) => r.estado.toLowerCase() == _filtroActual.toLowerCase().replaceAll('s', '')).toList();
  }

  int get _cantidadPendientes {
    return _reportes.where((r) => r.estado.toLowerCase() == 'pendiente').length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Reportes'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Badge(
                label: Text('$_cantidadPendientes'),
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.notifications),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filtros.map((filtro) {
                final isSelected = _filtroActual == filtro;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filtro,
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filtroActual = filtro);
                      _cargarReportes();
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Contenido principal
          Expanded(
            child: _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary));
      // Idealmente, aquí iría un Shimmer Loading (shimmer_cards)
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            SigoButton(label: 'Reintentar', onPressed: _cargarReportes),
          ],
        ),
      );
    }

    final reportes = _reportesFiltrados;

    if (reportes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'No hay reportes en esta categoría',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarReportes,
      color: AppColors.accent,
      child: ListView.builder(
        itemCount: reportes.length,
        itemBuilder: (context, index) {
          final reporte = reportes[index];
          return ReporteCard(
            reporte: reporte,
            onTap: () => _mostrarBottomSheet(reporte),
          );
        },
      ),
    );
  }
}
