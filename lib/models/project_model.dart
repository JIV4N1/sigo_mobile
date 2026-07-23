import 'package:flutter/material.dart';

enum ProjectStatus {
  onTime,
  delayed,
  critical,
  planned,
  completed,
  archived,
}

/// Entrada de actividad reciente del proyecto.
class ProjectActivity {
  final String id;
  final String type; // 'report', 'photo', 'issue_new', 'issue_resolved', 'personnel'
  final String description;
  final DateTime timestamp;
  final String? imageUrl;

  ProjectActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.imageUrl,
  });

  factory ProjectActivity.fromJson(Map<String, dynamic> json) {
    return ProjectActivity(
      id: json['id']?.toString() ?? '',
      type: json['tipo'] as String? ?? json['type'] as String? ?? 'report',
      description: json['descripcion'] as String? ??
          json['description'] as String? ?? '',
      timestamp: DateTime.tryParse(
              json['created_at'] as String? ?? json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      imageUrl: json['imagen_url'] as String? ?? json['image_url'] as String?,
    );
  }
}

class Project {
  final int id;
  final String name;
  final ProjectStatus status;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final double progress; // 0.0 to 1.0
  final int photosCount;
  final int issuesCount;
  final int workersCount;
  final int daysElapsed;
  final int totalDays;
  final int activeIssues;
  final int criticalIssues;
  final List<double> weeklyProgress;
  final List<ProjectActivity> timeline;
  final String client;
  final String contract;
  final String budget;
  final String manager;
  final String? miRol;

  Project({
    required this.id,
    required this.name,
    required this.status,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.photosCount,
    required this.issuesCount,
    required this.workersCount,
    required this.daysElapsed,
    required this.totalDays,
    required this.activeIssues,
    required this.criticalIssues,
    required this.weeklyProgress,
    required this.timeline,
    required this.client,
    required this.contract,
    required this.budget,
    required this.manager,
    this.miRol,
  });

  /// Retorna las acciones permitidas para el usuario actual en base a `miRol`
  List<String> getAccionesPermitidas() {
    final rol = miRol?.toLowerCase() ?? '';
    if (rol == 'supervisor') {
      return ['reporte_diario', 'incidencias', 'asistencia'];
    } else if (rol == 'ingeniero') {
      return ['atender_incidencias', 'asistencia'];
    } else if (rol == 'gerente') {
      return ['kpis', 'validar_reportes', 'asignar_incidencias'];
    } else if (rol == 'administrador') {
      return [
        'reporte_diario',
        'incidencias',
        'asistencia',
        'kpis',
        'validar_reportes',
        'asignar_incidencias'
      ];
    }
    return ['incidencias', 'asistencia']; // Acciones por defecto
  }

  /// Convierte el string de estado del backend al enum [ProjectStatus].
  static ProjectStatus _parseStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'a_tiempo':
        return ProjectStatus.onTime;
      case 'retrasado':
        return ProjectStatus.delayed;
      case 'critico':
        return ProjectStatus.critical;
      case 'planeado':
        return ProjectStatus.planned;
      case 'completado':
        return ProjectStatus.completed;
      case 'archivado':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.onTime;
    }
  }

  /// Crea un [Project] a partir del JSON de la API.
  factory Project.fromJson(Map<String, dynamic> json) {
    try {
      // Fechas
      final startDate = DateTime.tryParse(
              json['fecha_inicio']?.toString() ?? '') ??
          DateTime.now();
      final endDate = DateTime.tryParse(
              json['fecha_fin']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30));
      final now = DateTime.now();

    // Días transcurridos y totales
    final daysElapsed = now.isAfter(startDate)
        ? now.difference(startDate).inDays
        : 0;
    final totalDays = endDate.difference(startDate).inDays.abs().clamp(1, 9999);

    // Avance: puede venir como 0-100 o 0.0-1.0
    final rawProgress = (json['avance'] ?? json['porcentaje_avance'] ?? 0);
    final double progress = rawProgress is double
        ? (rawProgress > 1 ? rawProgress / 100 : rawProgress)
        : (rawProgress as num).toDouble() / 100;

      // Actividad reciente
      final actividadRaw = json['actividad'] as List<dynamic>? ?? [];
      final timeline = actividadRaw
          .map((e) => ProjectActivity.fromJson(e as Map<String, dynamic>))
          .toList();

      // Progreso semanal
      final semanalRaw = json['progreso_semanal'] as List<dynamic>? ?? [];
      final weeklyProgress = semanalRaw
          .map((e) {
            final v = (e as num).toDouble();
            return v > 1 ? v / 100 : v;
          })
          .toList();

    // Cliente — puede ser objeto o string
    final clienteRaw = json['cliente'];
    String clientName = '';
    if (clienteRaw is Map) {
      clientName = clienteRaw['nombre'] as String? ?? '';
    } else {
      clientName = clienteRaw as String? ?? '';
    }

    // Gerente — puede ser objeto usuario o string
    final gerenteRaw = json['gerente'] ?? json['responsable'];
    String managerName = '';
    if (gerenteRaw is Map) {
      managerName = gerenteRaw['nombre'] as String? ??
          gerenteRaw['name'] as String? ?? '';
    } else {
      managerName = gerenteRaw as String? ?? '';
    }

      return Project(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
        status: _parseStatus(json['estado']?.toString()),
        location: json['ubicacion']?.toString() ?? json['location']?.toString() ?? '',
      startDate: startDate,
      endDate: endDate,
      progress: progress.clamp(0.0, 1.0),
      photosCount: (json['fotos_count'] ?? json['total_fotos'] ?? 0) as int,
      issuesCount: (json['incidencias_count'] ?? json['total_incidencias'] ?? 0) as int,
      workersCount: (json['trabajadores_count'] ?? json['total_trabajadores'] ?? 0) as int,
      daysElapsed: daysElapsed,
      totalDays: totalDays,
      activeIssues: (json['incidencias_abiertas'] ?? json['active_issues'] ?? 0) as int,
      criticalIssues: (json['incidencias_criticas'] ?? json['critical_issues'] ?? 0) as int,
      weeklyProgress: weeklyProgress,
      timeline: timeline,
      client: clientName,
      contract: json['contrato']?.toString() ?? json['codigo_contrato']?.toString() ?? '',
      budget: json['presupuesto']?.toString() ?? json['budget']?.toString() ?? '',
      manager: managerName,
      miRol: json['mi_rol']?.toString(),
    );
    } catch (e, stackTrace) {
      debugPrint('Error parseando Project: $e\n$stackTrace');
      debugPrint('JSON problemático: $json');
      rethrow;
    }
  }
}
