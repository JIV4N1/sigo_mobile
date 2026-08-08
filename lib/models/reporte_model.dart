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

  factory Reporte.fromJson(Map<String, dynamic> json) {
    // Proyecto — puede venir como objeto anidado o strings sueltos
    final proyectoRaw = json['proyecto'];
    String proyectoNombre = '';
    String proyectoCodigo = '';
    if (proyectoRaw is Map) {
      proyectoNombre = proyectoRaw['nombre'] as String? ?? '';
      proyectoCodigo = proyectoRaw['codigo'] as String? ?? '';
    }
    proyectoNombre = proyectoNombre.isNotEmpty
        ? proyectoNombre
        : (json['proyecto_nombre'] as String? ?? '');
    proyectoCodigo = proyectoCodigo.isNotEmpty
        ? proyectoCodigo
        : (json['proyecto_codigo'] as String? ?? '');

    // Supervisor — puede venir como objeto anidado (reportado_por/supervisor/usuario) o strings sueltos
    final supervisorRaw = json['supervisor'] ??
        json['reportado_por'] ??
        json['usuario'];
    String supervisorNombre = '';
    String supervisorFoto = '';
    if (supervisorRaw is Map) {
      supervisorNombre = supervisorRaw['nombre'] as String? ?? '';
      supervisorFoto = supervisorRaw['foto'] as String? ??
          supervisorRaw['avatar_url'] as String? ?? '';
    }
    supervisorNombre = supervisorNombre.isNotEmpty
        ? supervisorNombre
        : (json['supervisor_nombre'] as String? ?? '');
    supervisorFoto = supervisorFoto.isNotEmpty
        ? supervisorFoto
        : (json['supervisor_foto'] as String? ?? '');

    // Fotos — lista de objetos {url,...} o strings sueltos
    final fotosRaw = json['fotos'] as List<dynamic>? ?? [];
    final fotos = fotosRaw
        .map((e) => e is Map ? (e['url'] as String? ?? '') : e.toString())
        .where((url) => url.isNotEmpty)
        .toList();

    return Reporte(
      id: json['id']?.toString() ?? '',
      proyectoNombre: proyectoNombre,
      proyectoCodigo: proyectoCodigo,
      supervisorNombre: supervisorNombre,
      supervisorFoto: supervisorFoto,
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      turno: json['turno'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      avance: (json['avance'] as num?)?.toDouble() ?? 0.0,
      descripcion: json['descripcion'] as String? ?? '',
      fotos: fotos,
      estado: json['estado'] as String? ?? 'pendiente',
      fechaEnvio: DateTime.tryParse(
              json['fecha_envio'] as String? ?? json['created_at'] as String? ?? '') ??
          DateTime.now(),
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );
  }
}
