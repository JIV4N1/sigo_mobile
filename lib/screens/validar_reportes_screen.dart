import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../widgets/reporte_card.dart';
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

  // Simulación de consumo de endpoint GET /api/proyectos/{id}/reportes?validado=false
  Future<void> _cargarReportes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simular delay de red
      await Future.delayed(const Duration(seconds: 2));
      
      // Datos mock
      setState(() {
        _reportes = [
          Reporte(
            id: '1',
            proyectoNombre: 'Torre Central',
            proyectoCodigo: 'TC-2026',
            supervisorNombre: 'Juan Pérez',
            supervisorFoto: 'https://i.pravatar.cc/150?u=juan',
            fecha: DateTime(2026, 5, 19),
            turno: 'Matutino',
            categoria: 'Estructural',
            avance: 45.0,
            descripcion: 'Se completó el colado de la losa del nivel 4. El clima fue favorable. Se requiere revisión de armados en nivel 5.',
            fotos: [
              'https://picsum.photos/400/300?random=1',
              'https://picsum.photos/400/300?random=2',
              'https://picsum.photos/400/300?random=3',
              'https://picsum.photos/400/300?random=4',
            ],
            estado: 'pendiente',
            fechaEnvio: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          Reporte(
            id: '2',
            proyectoNombre: 'Plaza del Sol',
            proyectoCodigo: 'PS-2025',
            supervisorNombre: 'María García',
            supervisorFoto: 'https://i.pravatar.cc/150?u=maria',
            fecha: DateTime(2026, 5, 18),
            turno: 'Vespertino',
            categoria: 'Albañilería',
            avance: 70.0,
            descripcion: 'Avance en muros de tabique en área comercial. Hubo un retraso por falta de material en la zona B.',
            fotos: [
              'https://picsum.photos/400/300?random=5',
              'https://picsum.photos/400/300?random=6',
            ],
            estado: 'aprobado',
            fechaEnvio: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar reportes';
        _isLoading = false;
      });
    }
  }

  // Simulación de endpoint PUT /api/reportes/{id}/validar
  Future<void> _validarReporte(Reporte reporte, String nuevoEstado, String notas) async {
    // Aquí iría la llamada HTTP real
    
    setState(() {
      final index = _reportes.indexWhere((r) => r.id == reporte.id);
      if (index != -1) {
        // En una app real, el backend actualiza esto. Aquí actualizamos el modelo localmente.
        _reportes[index] = Reporte(
          id: reporte.id,
          proyectoNombre: reporte.proyectoNombre,
          proyectoCodigo: reporte.proyectoCodigo,
          supervisorNombre: reporte.supervisorNombre,
          supervisorFoto: reporte.supervisorFoto,
          fecha: reporte.fecha,
          turno: reporte.turno,
          categoria: reporte.categoria,
          avance: reporte.avance,
          descripcion: reporte.descripcion,
          fotos: reporte.fotos,
          estado: nuevoEstado,
          fechaEnvio: reporte.fechaEnvio,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte ${nuevoEstado.toLowerCase()} exitosamente'),
        backgroundColor: nuevoEstado == 'aprobado' ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Validar Reportes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Badge(
                label: Text('$_cantidadPendientes'),
                backgroundColor: const Color(0xFFFF6D00),
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
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filtroActual = filtro);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF1A237E),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF1A237E) : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));
      // Idealmente, aquí iría un Shimmer Loading (shimmer_cards)
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarReportes,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
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
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              'No hay reportes en esta categoría',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarReportes,
      color: const Color(0xFFFF6D00),
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
