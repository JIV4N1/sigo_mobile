import '../config/api_config.dart';
import 'api_service.dart';

class AsistenciaService {
  /// Obtiene el estado del día actual.
  static Future<Map<String, dynamic>> getEstadoHoy() async {
    return await ApiService.get(ApiConfig.asistenciaHoy);
  }

  /// Registra la entrada del usuario.
  static Future<Map<String, dynamic>> registrarEntrada({
    double? latitud,
    double? longitud,
    int? proyectoId,
  }) async {
    final body = <String, dynamic>{};
    if (latitud != null) body['latitud'] = latitud;
    if (longitud != null) body['longitud'] = longitud;
    if (proyectoId != null) body['proyecto_id'] = proyectoId;

    return await ApiService.post(ApiConfig.asistenciaEntrada, body: body);
  }

  /// Inicia el descanso de comida.
  static Future<Map<String, dynamic>> iniciarComida() async {
    return await ApiService.post(ApiConfig.asistenciaComidaInicio, body: {});
  }

  /// Finaliza el descanso de comida.
  static Future<Map<String, dynamic>> finalizarComida() async {
    return await ApiService.post(ApiConfig.asistenciaComidaFin, body: {});
  }

  /// Registra la salida del usuario.
  static Future<Map<String, dynamic>> registrarSalida({
    double? latitud,
    double? longitud,
  }) async {
    final body = <String, dynamic>{};
    if (latitud != null) body['latitud'] = latitud;
    if (longitud != null) body['longitud'] = longitud;

    return await ApiService.post(ApiConfig.asistenciaSalida, body: body);
  }

  /// Obtiene el historial semanal de asistencia.
  static Future<Map<String, dynamic>> getHistorial() async {
    return await ApiService.get(ApiConfig.asistenciaHistorial);
  }
}
