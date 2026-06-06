class Reporte {
  final String id;
  final String proyectoNombre;
  final String proyectoCodigo;
  final String supervisorNombre;
  final String supervisorFoto;
  final DateTime fecha;
  final String turno;
  final String categoria;
  final double avance;
  final String descripcion;
  final List<String> fotos;
  final String estado; // pendiente, aprobado, rechazado
  final DateTime fechaEnvio;
  final double? latitud;
  final double? longitud;

  Reporte({
    required this.id,
    required this.proyectoNombre,
    required this.proyectoCodigo,
    required this.supervisorNombre,
    required this.supervisorFoto,
    required this.fecha,
    required this.turno,
    required this.categoria,
    required this.avance,
    required this.descripcion,
    required this.fotos,
    required this.estado,
    required this.fechaEnvio,
    this.latitud,
    this.longitud,
  });
}
