import '../models/project_model.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ProjectService {
  /// Obtiene la lista de proyectos asignados al usuario actual.
  /// La API ya filtra automáticamente por el usuario autenticado.
  static Future<List<Project>> getProyectosAsignados() async {
    final response = await ApiService.get(ApiConfig.proyectos);
    
    final rawData = response['data'];
    List<dynamic> list = [];
    
    if (rawData == null) {
      return [];
    }

    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map<String, dynamic> || rawData is Map) {
      // Paginación de Laravel: { "current_page": 1, "data": [...] }
      if ((rawData as Map).containsKey('data') && (rawData as Map)['data'] is List) {
        list = (rawData as Map)['data'] as List<dynamic>;
      } else {
        list = [];
      }
    }

    return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Obtiene el rol del usuario en un proyecto específico.
  /// Se obtiene del detalle del proyecto, que debe incluir `mi_rol`.
  static Future<String?> getMiRolEnProyecto(int projectId) async {
    final response = await ApiService.get(ApiConfig.proyectoDetail(projectId));
    final data = response['data'] as Map<String, dynamic>? ?? response;
    
    // Asumiendo que el objeto devuelto tiene la propiedad mi_rol
    return data['mi_rol'] as String?;
  }
}
