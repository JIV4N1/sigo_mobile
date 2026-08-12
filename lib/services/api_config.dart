/// Configuración central de endpoints de la API SIGO.
/// Apunta al backend Laravel desplegado en producción (EasyPanel/IONOS).
class ApiConfig {
  // ─── URL Base ──────────────────────────────────────────────────────────────
  // URL del backend Laravel en producción.
  static const String baseUrl =
      'https://db-sigo-sigo-api.q2llut.easypanel.host/api';

  // ─── Headers base que deben ir en TODAS las peticiones ────────────────────
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── Autenticación ───────────────────────────────────────────────────────────
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';

  // ─── Proyectos ────────────────────────────────────────────────────────────────
  static const String proyectos = '$baseUrl/proyectos';
  static String proyectoDetail(int id) => '$baseUrl/proyectos/$id';
  static String proyectoActividad(int id) => '$baseUrl/proyectos/$id/actividad';
  static String proyectoUsuarios(int id) => '$baseUrl/proyectos/$id/usuarios';

  // ─── Reportes ─────────────────────────────────────────────────────────────────
  static String reportesPorProyecto(int id) => '$baseUrl/proyectos/$id/reportes';
  static const String reportes = '$baseUrl/reportes';
  static String reporteDetail(int id) => '$baseUrl/reportes/$id';
  static String reporteFotos(int id) => '$baseUrl/reportes/$id/fotos';
  static String reporteEstado(int id) => '$baseUrl/reportes/$id/estado';

  // ─── Incidencias ──────────────────────────────────────────────────────────────
  static String incidenciasPorProyecto(int id) =>
      '$baseUrl/proyectos/$id/incidencias';
  static const String incidencias = '$baseUrl/incidencias';
  static const String incidenciasAsignadas = '$baseUrl/incidencias-asignadas';
  static String incidenciaDetail(int id) => '$baseUrl/incidencias/$id';
  static String incidenciaEstado(int id) => '$baseUrl/incidencias/$id/estado';
  static String incidenciaFotos(int id) => '$baseUrl/incidencias/$id/fotos';
  static String incidenciaComentarios(int id) =>
      '$baseUrl/incidencias/$id/comentarios';

  // ─── Gastos de Obra ──────────────────────────────────────────────────────────
  static const String gastosObra = '$baseUrl/gastos-obra';
  static String gastoObraDetail(int id) => '$baseUrl/gastos-obra/$id';
  static const String gastosObraResumen = '$baseUrl/gastos-obra/resumen';
  static const String gastosObraCategorias = '$baseUrl/gastos-obra/categorias';

  // ─── Proveedores ──────────────────────────────────────────────────────────────
  static const String proveedores = '$baseUrl/proveedores';

  // ─── Asistencia ───────────────────────────────────────────────────────────────
  static const String asistenciaHoy = '$baseUrl/asistencia/hoy';
  static const String asistenciaEntrada = '$baseUrl/asistencia/entrada';
  static const String asistenciaComidaInicio =
      '$baseUrl/asistencia/comida/inicio';
  static const String asistenciaComidaFin = '$baseUrl/asistencia/comida/fin';
  static const String asistenciaSalida = '$baseUrl/asistencia/salida';
  static const String asistenciaHistorial = '$baseUrl/asistencia/historial';
}