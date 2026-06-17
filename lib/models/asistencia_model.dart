/// Modelo de registro de asistencia del día actual.
class RegistroAsistencia {
  final int? id;
  final int? usuarioId;
  final int? empresaId;
  final DateTime fecha;
  final DateTime? entrada;
  final DateTime? inicioComida;
  final DateTime? finComida;
  final DateTime? salida;
  final double? latitudEntrada;
  final double? longitudEntrada;
  final double? latitudSalida;
  final double? longitudSalida;
  final String? horasTrabajadas;
  final String? estado;

  RegistroAsistencia({
    this.id,
    this.usuarioId,
    this.empresaId,
    required this.fecha,
    this.entrada,
    this.inicioComida,
    this.finComida,
    this.salida,
    this.latitudEntrada,
    this.longitudEntrada,
    this.latitudSalida,
    this.longitudSalida,
    this.horasTrabajadas,
    this.estado,
  });

  /// Crea un [RegistroAsistencia] a partir del JSON de la API.
  factory RegistroAsistencia.fromJson(Map<String, dynamic> json) {
    return RegistroAsistencia(
      id: (json['id'] as num?)?.toInt(),
      usuarioId: (json['usuario_id'] as num?)?.toInt(),
      empresaId: (json['empresa_id'] as num?)?.toInt(),
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      entrada: json['entrada'] != null
          ? DateTime.tryParse(json['entrada'] as String)
          : null,
      inicioComida: json['comida_inicio'] != null
          ? DateTime.tryParse(json['comida_inicio'] as String)
          : null,
      finComida: json['comida_fin'] != null
          ? DateTime.tryParse(json['comida_fin'] as String)
          : null,
      salida: json['salida'] != null
          ? DateTime.tryParse(json['salida'] as String)
          : null,
      latitudEntrada: (json['latitud_entrada'] as num?)?.toDouble(),
      longitudEntrada: (json['longitud_entrada'] as num?)?.toDouble(),
      latitudSalida: (json['latitud_salida'] as num?)?.toDouble(),
      longitudSalida: (json['longitud_salida'] as num?)?.toDouble(),
      horasTrabajadas: json['horas_trabajadas'] as String?,
      estado: json['estado'] as String?,
    );
  }
}

/// Resumen de asistencia de un día para el historial semanal.
class ResumenDia {
  final DateTime fecha;
  final String estado; // Completo, Incompleto, Sin registrar
  final Duration horasTrabajadas;

  ResumenDia({
    required this.fecha,
    required this.estado,
    required this.horasTrabajadas,
  });

  /// Crea un [ResumenDia] a partir del JSON de la API.
  factory ResumenDia.fromJson(Map<String, dynamic> json) {
    // Horas trabajadas pueden venir como minutos o como string "HH:MM"
    Duration workedDuration = Duration.zero;
    final rawMinutes = json['minutos_trabajados'] ?? json['horas_trabajadas'];
    if (rawMinutes is num) {
      workedDuration = Duration(minutes: rawMinutes.toInt());
    } else if (rawMinutes is String) {
      // Formato "HH:MM"
      final parts = rawMinutes.split(':');
      if (parts.length == 2) {
        workedDuration = Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return ResumenDia(
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      estado: json['estado'] as String? ?? 'Sin registrar',
      horasTrabajadas: workedDuration,
    );
  }
}
