/// Configuración central de endpoints de la API SIGO.
/// Todos los URLs apuntan al backend Laravel con Sanctum.
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.3:8000/api';

  // ─── Autenticación ───────────────────────────────────────────────────────────
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';

  // ─── Proyectos ────────────────────────────────────────────────────────────────
  static const String proyectos = '$baseUrl/proyectos';
  static String proyectoDetail(int id) => '$baseUrl/proyectos/$id';
  static String proyectoActividad(int id) => '$baseUrl/proyectos/$id/actividad';

  // ─── Reportes ─────────────────────────────────────────────────────────────────
  static String reportesPorProyecto(int id) => '$baseUrl/proyectos/$id/reportes';
  static const String reportes = '$baseUrl/reportes';
  static String reporteDetail(int id) => '$baseUrl/reportes/$id';
  static String reporteFotos(int id) => '$baseUrl/reportes/$id/fotos';

  // ─── Incidencias ──────────────────────────────────────────────────────────────
  static String incidenciasPorProyecto(int id) =>
      '$baseUrl/proyectos/$id/incidencias';
  static const String incidencias = '$baseUrl/incidencias';
  static String incidenciaDetail(int id) => '$baseUrl/incidencias/$id';
  static String incidenciaEstado(int id) => '$baseUrl/incidencias/$id/estado';
  static String incidenciaFotos(int id) => '$baseUrl/incidencias/$id/fotos';
  static String incidenciaComentarios(int id) =>
      '$baseUrl/incidencias/$id/comentarios';

  // ─── Asistencia ───────────────────────────────────────────────────────────────
  static const String asistenciaHoy = '$baseUrl/asistencia/hoy';
  static const String asistenciaEntrada = '$baseUrl/asistencia/entrada';
  static const String asistenciaComidaInicio =
      '$baseUrl/asistencia/comida/inicio';
  static const String asistenciaComidaFin = '$baseUrl/asistencia/comida/fin';
  static const String asistenciaSalida = '$baseUrl/asistencia/salida';
  static const String asistenciaHistorial = '$baseUrl/asistencia/historial';
}
