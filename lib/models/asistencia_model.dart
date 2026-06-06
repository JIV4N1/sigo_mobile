/// Modelo de registro de asistencia del día actual.
class RegistroAsistencia {
  final int? id;
  final DateTime fecha;
  final DateTime? entrada;
  final DateTime? inicioComida;
  final DateTime? finComida;
  final DateTime? salida;

  RegistroAsistencia({
    this.id,
    required this.fecha,
    this.entrada,
    this.inicioComida,
    this.finComida,
    this.salida,
  });

  bool get haEntrado => entrada != null;
  bool get haIniciadoComida => inicioComida != null;
  bool get haTerminadoComida => finComida != null;
  bool get haSalido => salida != null;

  String get estadoActual {
    if (haSalido) return 'Jornada finalizada';
    if (haIniciadoComida && !haTerminadoComida) return 'En horario de comida';
    if (haEntrado && !haSalido) return 'En jornada laboral';
    return 'Fuera de jornada';
  }

  Duration get horasTrabajadas {
    if (!haEntrado) return Duration.zero;

    DateTime endTime = salida ?? DateTime.now();
    Duration total = endTime.difference(entrada!);

    if (haIniciadoComida) {
      DateTime finDescanso = finComida ?? DateTime.now();
      Duration descanso = finDescanso.difference(inicioComida!);
      total = total - descanso;
    }

    return total;
  }

  /// Crea un [RegistroAsistencia] a partir del JSON de la API.
  factory RegistroAsistencia.fromJson(Map<String, dynamic> json) {
    return RegistroAsistencia(
      id: (json['id'] as num?)?.toInt(),
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      entrada: json['hora_entrada'] != null
          ? DateTime.tryParse(json['hora_entrada'] as String)
          : null,
      inicioComida: json['hora_inicio_comida'] != null
          ? DateTime.tryParse(json['hora_inicio_comida'] as String)
          : null,
      finComida: json['hora_fin_comida'] != null
          ? DateTime.tryParse(json['hora_fin_comida'] as String)
          : null,
      salida: json['hora_salida'] != null
          ? DateTime.tryParse(json['hora_salida'] as String)
          : null,
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
