import 'dart:io';
import 'api_service.dart';
import 'api_config.dart';
import '../models/issue_model.dart';

class IncidenciaService {
  /// Obtiene todas las incidencias (admin/gerente)
  static Future<List<Issue>> getIncidencias({String? estado, String? severidad}) async {
    final queryParams = _buildQueryParams(estado, severidad);
    final response = await ApiService.get(
      ApiConfig.incidencias,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
    return _parseList(response);
  }

  /// Obtiene las incidencias de un proyecto específico (supervisor)
  static Future<List<Issue>> getIncidenciasPorProyecto(int proyectoId, {String? estado, String? severidad}) async {
    final queryParams = _buildQueryParams(estado, severidad);
    final response = await ApiService.get(
      ApiConfig.incidenciasPorProyecto(proyectoId),
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
    return _parseList(response);
  }

  /// Obtiene las incidencias asignadas a MÍ (ingeniero)
  static Future<List<Issue>> getIncidenciasAsignadas({String? estado, String? severidad}) async {
    final queryParams = _buildQueryParams(estado, severidad);
    final response = await ApiService.get(
      ApiConfig.incidenciasAsignadas,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
    return _parseList(response);
  }

  static Map<String, String> _buildQueryParams(String? estado, String? severidad) {
    final queryParams = <String, String>{};
    if (estado != null && estado != 'Todas') {
      queryParams['estado'] = estado;
    }
    if (severidad != null && severidad != 'Todas') {
      queryParams['severidad'] = severidad;
    }
    return queryParams;
  }

  /// Obtiene el detalle actualizado de una incidencia (incluye historial).
  static Future<Issue> getIncidencia(int id) async {
    final response = await ApiService.get(ApiConfig.incidenciaDetail(id));
    final rawData = response['data'];
    final data = rawData is Map<String, dynamic> ? rawData : response;
    return Issue.fromJson(data);
  }

  static List<Issue> _parseList(Map<String, dynamic> response) {
    final rawData = response['data'];
    List<dynamic> list;
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData.containsKey('data')) {
      list = rawData['data'] as List<dynamic>? ?? [];
    } else {
      list = [];
    }
    return list.map((e) => Issue.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Crea una nueva incidencia enviando multipart/form-data.
  static Future<Map<String, dynamic>> createIncidencia({
    required int proyectoId,
    required String titulo,
    required String descripcion,
    required String categoria,
    required String severidad,
    String? ubicacionDescripcion,
    double? latitud,
    double? longitud,
    List<File>? fotos,
  }) async {
    final fields = <String, String>{
      'proyecto_id': proyectoId.toString(),
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'severidad': severidad,
    };

    if (ubicacionDescripcion != null && ubicacionDescripcion.isNotEmpty) {
      fields['ubicacion_descripcion'] = ubicacionDescripcion;
    }
    if (latitud != null) {
      fields['latitud'] = latitud.toString();
    }
    if (longitud != null) {
      fields['longitud'] = longitud.toString();
    }

    final photoPaths = fotos
            ?.where((f) => f.path.isNotEmpty)
            .map((f) => f.path)
            .toList() ??
        [];

    if (photoPaths.isNotEmpty) {
      return await ApiService.postMultipart(
        ApiConfig.incidencias,
        fields: fields,
        filePaths: photoPaths,
        fileFieldName: 'fotos[]',
      );
    } else {
      // Aunque no tenga fotos, enviamos como multipart o json regular.
      // El requerimiento dice "Usar multipart/form-data (NO JSON)", por lo que
      // usamos postMultipart sin filePaths para forzar form-data.
      return await ApiService.postMultipart(
        ApiConfig.incidencias,
        fields: fields,
        filePaths: [],
      );
    }
  }

  /// Actualiza el estado, el responsable asignado y/o agrega un comentario
  /// de seguimiento a una incidencia. Se usa para atender, resolver, cerrar
  /// y asignar responsable — cualquier combinación de parámetros es válida.
  static Future<Map<String, dynamic>> cambiarEstado(
    int id, {
    required String estado,
    int? asignadoA,
    String? comentario,
  }) async {
    final body = <String, dynamic>{
      'estado': estado,
      if (asignadoA != null) 'asignado_a': asignadoA,
      if (comentario != null) 'comentario': comentario,
    };
    return await ApiService.put(ApiConfig.incidenciaEstado(id), body: body);
  }

  /// Registra la atención de una incidencia: sube fotos de la solución (si
  /// las hay) y actualiza estado + comentario. Reutiliza los endpoints ya
  /// validados de fotos y estado en vez de un endpoint combinado /atender.
  static Future<void> atenderIncidencia(
    int id, {
    required String descripcion,
    required String estado,
    List<File>? fotos,
    String? comentario,
  }) async {
    final photoPaths = fotos
            ?.where((f) => f.path.isNotEmpty)
            .map((f) => f.path)
            .toList() ??
        [];

    if (photoPaths.isNotEmpty) {
      await ApiService.postMultipart(
        ApiConfig.incidenciaFotos(id),
        fields: {'descripcion': descripcion},
        filePaths: photoPaths,
        fileFieldName: 'fotos[]',
      );
    }

    final comentarioCompleto = comentario != null && comentario.trim().isNotEmpty
        ? '$descripcion\n\n${comentario.trim()}'
        : descripcion;

    await cambiarEstado(id, estado: estado, comentario: comentarioCompleto);
  }
}
