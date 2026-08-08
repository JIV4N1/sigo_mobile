import 'api_service.dart';
import 'api_config.dart';
import '../models/usuario_model.dart';

class UsuarioService {
  /// Obtiene los usuarios asignados a un proyecto, opcionalmente filtrados por rol.
  static Future<List<Usuario>> getUsuariosPorProyecto(
    int proyectoId, {
    String? rol,
  }) async {
    final response = await ApiService.get(
      ApiConfig.proyectoUsuarios(proyectoId),
      queryParams: rol != null ? {'rol': rol} : null,
    );
    final rawData = response['data'];
    final list = rawData is List ? rawData : <dynamic>[];
    return list
        .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
