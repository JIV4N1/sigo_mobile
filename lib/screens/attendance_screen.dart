import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/asistencia_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../widgets/asistencia/reloj_widget.dart';
import '../widgets/asistencia/boton_asistencia.dart';
import '../widgets/asistencia/resumen_jornada.dart';
import '../widgets/asistencia/historial_semanal.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  late RegistroAsistencia _registroHoy;
  List<ResumenDia> _historial = [];

  @override
  void initState() {
    super.initState();
    // Inicializar con registro vacío para evitar null errors durante la carga
    _registroHoy = RegistroAsistencia(fecha: DateTime.now());
    _cargarDatos();
  }

  // ─── Carga de datos ───────────────────────────────────────────────────────────

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Cargar estado del día actual y el historial en paralelo
      final results = await Future.wait([
        ApiService.get(ApiConfig.asistenciaHoy),
        ApiService.get(ApiConfig.asistenciaHistorial),
      ]);

      final hoyResponse = results[0];
      final historialResponse = results[1];

      // Parsear registro de hoy
      final hoyData = hoyResponse['data'];
      RegistroAsistencia registro;
      if (hoyData != null) {
        registro = RegistroAsistencia.fromJson(
            hoyData is Map ? hoyData as Map<String, dynamic> : {});
      } else {
        registro = RegistroAsistencia(fecha: DateTime.now());
      }

      // Parsear historial
      final historialData = historialResponse['data'];
      List<ResumenDia> historial = [];
      if (historialData is List) {
        historial = historialData
            .map((e) =>
                ResumenDia.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _registroHoy = registro;
        _historial = historial;
        _isLoading = false;
      });
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
        _errorMessage = 'Error inesperado al cargar asistencia.';
      });
    }
  }

  // ─── Geolocalización ──────────────────────────────────────────────────────────

  /// Obtiene la posición actual del usuario.
  /// Retorna null si no se tiene permiso o no está disponible.
  Future<Position?> _getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Registro de acciones ─────────────────────────────────────────────────────

  Future<void> _registrarAccion(String tipoAccion) async {
    // Mostrar loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00))),
    );

    try {
      // Obtener geolocalización
      final position = await _getPosition();
      final body = <String, dynamic>{
        if (position != null) ...{
          'latitud': position.latitude,
          'longitud': position.longitude,
        },
      };

      // Seleccionar el endpoint según el tipo de acción
      String url;
      switch (tipoAccion) {
        case 'entrada':
          url = ApiConfig.asistenciaEntrada;
          break;
        case 'inicio_comida':
          url = ApiConfig.asistenciaComidaInicio;
          break;
        case 'fin_comida':
          url = ApiConfig.asistenciaComidaFin;
          break;
        case 'salida':
          url = ApiConfig.asistenciaSalida;
          break;
        default:
          throw Exception('Tipo de acción desconocido: $tipoAccion');
      }

      final response = await ApiService.post(url, body: body);

      // La respuesta debe contener el registro actualizado
      final data = response['data'];
      RegistroAsistencia updatedRegistro;
      if (data != null && data is Map) {
        updatedRegistro = RegistroAsistencia.fromJson(
            data as Map<String, dynamic>);
      } else {
        // Actualización optimista si la API no retorna el objeto
        updatedRegistro = _buildOptimisticRegistro(tipoAccion);
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loader

      setState(() => _registroHoy = updatedRegistro);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${_getActionLabel(tipoAccion)} registrado exitosamente'),
          ]),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Actualización optimista del registro si la API no retorna el objeto actualizado.
  RegistroAsistencia _buildOptimisticRegistro(String tipoAccion) {
    final now = DateTime.now();
    switch (tipoAccion) {
      case 'entrada':
        return RegistroAsistencia(
            fecha: _registroHoy.fecha,
            entrada: now);
      case 'inicio_comida':
        return RegistroAsistencia(
            fecha: _registroHoy.fecha,
            entrada: _registroHoy.entrada,
            inicioComida: now);
      case 'fin_comida':
        return RegistroAsistencia(
            fecha: _registroHoy.fecha,
            entrada: _registroHoy.entrada,
            inicioComida: _registroHoy.inicioComida,
            finComida: now);
      case 'salida':
        return RegistroAsistencia(
            fecha: _registroHoy.fecha,
            entrada: _registroHoy.entrada,
            inicioComida: _registroHoy.inicioComida,
            finComida: _registroHoy.finComida,
            salida: now);
      default:
        return _registroHoy;
    }
  }

  String _getActionLabel(String tipoAccion) {
    switch (tipoAccion) {
      case 'entrada': return 'Entrada';
      case 'inicio_comida': return 'Inicio de comida';
      case 'fin_comida': return 'Fin de comida';
      case 'salida': return 'Salida';
      default: return tipoAccion;
    }
  }

  Widget _buildEstadoChip() {
    Color color;
    IconData icono;
    switch (_registroHoy.estadoActual) {
      case 'En jornada laboral':
        color = Colors.green;
        icono = Icons.work;
        break;
      case 'En horario de comida':
        color = Colors.orange;
        icono = Icons.restaurant;
        break;
      case 'Jornada finalizada':
        color = Colors.red;
        icono = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        icono = Icons.access_time;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          _registroHoy.estadoActual,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6D00))),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Asistencia'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Asistencia',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: const Color(0xFFFF6D00),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            // ── Reloj ────────────────────────────────────────────────────────────
            const RelojWidget(),
            const SizedBox(height: 16),
            _buildEstadoChip(),
            const SizedBox(height: 32),

            // ── Botones de acción ────────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                BotonAsistencia(
                  titulo: 'Registrar Entrada',
                  icono: Icons.login,
                  colorBase: Colors.green[800]!,
                  habilitado: !_registroHoy.haEntrado,
                  subtitulo: _registroHoy.haEntrado ? 'Registrado' : null,
                  onPressed: () => _registrarAccion('entrada'),
                ),
                BotonAsistencia(
                  titulo: 'Iniciar Comida',
                  icono: Icons.restaurant,
                  colorBase: const Color(0xFFFF6D00),
                  habilitado: _registroHoy.haEntrado &&
                      !_registroHoy.haIniciadoComida &&
                      !_registroHoy.haSalido,
                  subtitulo:
                      _registroHoy.haIniciadoComida ? 'Inició' : null,
                  onPressed: () => _registrarAccion('inicio_comida'),
                ),
                BotonAsistencia(
                  titulo: 'Fin de Comida',
                  icono: Icons.restaurant_menu,
                  colorBase: Colors.blue[800]!,
                  habilitado: _registroHoy.haIniciadoComida &&
                      !_registroHoy.haTerminadoComida &&
                      !_registroHoy.haSalido,
                  subtitulo: _registroHoy.haTerminadoComida
                      ? 'Terminó'
                      : null,
                  onPressed: () => _registrarAccion('fin_comida'),
                ),
                BotonAsistencia(
                  titulo: 'Registrar Salida',
                  icono: Icons.logout,
                  colorBase: Colors.red[800]!,
                  habilitado: _registroHoy.haEntrado &&
                      !_registroHoy.haSalido,
                  subtitulo:
                      _registroHoy.haSalido ? 'Registrado' : null,
                  onPressed: () => _registrarAccion('salida'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Resumen de jornada ───────────────────────────────────────────────
            ResumenJornada(registro: _registroHoy),
            const SizedBox(height: 24),

            // ── Historial semanal ────────────────────────────────────────────────
            HistorialSemanal(historial: _historial),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
