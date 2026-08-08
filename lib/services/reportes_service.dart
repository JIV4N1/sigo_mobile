import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'api_config.dart';
import '../models/reporte_model.dart';

class ReportesService {
  /// Obtiene todos los reportes diarios (admin/gerente), opcionalmente filtrados por estado.
  static Future<List<Reporte>> getReportes({String? estado}) async {
    final response = await ApiService.get(
      ApiConfig.reportes,
      queryParams: _buildQueryParams(estado),
    );
    return _parseList(response);
  }

  /// Obtiene los reportes de un proyecto específico.
  static Future<List<Reporte>> getReportesPorProyecto(int proyectoId, {String? estado}) async {
    final response = await ApiService.get(
      ApiConfig.reportesPorProyecto(proyectoId),
      queryParams: _buildQueryParams(estado),
    );
    return _parseList(response);
  }

  /// Aprueba o rechaza un reporte diario.
  ///
  /// [estado] es el estado resultante ('aprobado'/'rechazado', igual que en
  /// el resto de la app); la API espera el verbo de acción ('accion':
  /// 'aprobar'/'rechazar'), así que la traducción se hace aquí.
  static Future<void> validarReporte(int id, {required String estado, String? notas}) async {
    final accion = estado == 'aprobado' ? 'aprobar' : 'rechazar';
    final body = {
      'accion': accion,
      if (notas != null && notas.isNotEmpty) 'notas': notas,
    };
    debugPrint('ReportesService.validarReporte($id): body=$body');
    await ApiService.put(ApiConfig.reporteEstado(id), body: body);
  }

  static Map<String, String>? _buildQueryParams(String? estado) {
    if (estado == null || estado.isEmpty) return null;
    return {'estado': estado};
  }

  static List<Reporte> _parseList(Map<String, dynamic> response) {
    final rawData = response['data'];
    List<dynamic> list;
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData.containsKey('data')) {
      list = rawData['data'] as List<dynamic>? ?? [];
    } else {
      list = [];
    }
    return list.map((e) => Reporte.fromJson(e as Map<String, dynamic>)).toList();
  }
}
