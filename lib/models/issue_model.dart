import 'report_model.dart';
import '../config/api_config.dart';

enum IssueSeverity { critical, high, medium, low }

enum IssueStatus { open, inProgress, resolved, closed }

class IssueTimelineEntry {
  final String id;
  final String type; // 'report', 'status_change', 'comment', 'assignment'
  final String text;
  final String author;
  final DateTime timestamp;

  IssueTimelineEntry({
    required this.id,
    required this.type,
    required this.text,
    required this.author,
    required this.timestamp,
  });

  factory IssueTimelineEntry.fromJson(Map<String, dynamic> json) {
    return IssueTimelineEntry(
      id: json['id']?.toString() ?? '',
      type: json['tipo'] as String? ?? json['type'] as String? ?? 'report',
      text: json['texto'] as String? ?? json['text'] as String? ?? '',
      author: json['autor'] as String? ?? json['author'] as String? ?? '',
      timestamp: DateTime.tryParse(
              json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class IssueComment {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp;
  final String? avatarUrl;

  IssueComment({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
    this.avatarUrl,
  });

  factory IssueComment.fromJson(Map<String, dynamic> json) {
    // El autor puede ser un objeto usuario anidado o un string
    final autorRaw = json['autor'] ?? json['user'] ?? json['usuario'];
    String authorName = '';
    if (autorRaw is Map) {
      authorName = autorRaw['nombre'] as String? ??
          autorRaw['name'] as String? ?? '';
    } else {
      authorName = autorRaw as String? ?? '';
    }

    return IssueComment(
      id: json['id']?.toString() ?? '',
      author: authorName,
      text: json['comentario'] as String? ?? json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(
              json['created_at'] as String? ?? '') ??
          DateTime.now(),
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class Issue {
  final String id;
  final String? code;
  final String title;
  final String description;
  final String category;
  final String location;
  final IssueSeverity severity;
  final IssueStatus status;
  final DateTime reportedAt;
  final DateTime updatedAt;
  final String reporter;
  final String? assignedTo;
  final List<ReportPhoto> photos;
  final List<IssueTimelineEntry> timeline;
  final List<IssueComment> comments;
  final double? latitude;
  final double? longitude;
  final int? projectId;
  final String? projectName;

  Issue({
    required this.id,
    this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.severity,
    required this.status,
    required this.reportedAt,
    required this.updatedAt,
    required this.reporter,
    this.assignedTo,
    this.photos = const [],
    this.timeline = const [],
    this.comments = const [],
    this.latitude,
    this.longitude,
    this.projectId,
    this.projectName,
  });

  static String _formatPhotoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  /// Convierte el string de severidad del backend al enum [IssueSeverity].
  static IssueSeverity _parseSeverity(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'critica':
      case 'critico':
      case 'critical':
        return IssueSeverity.critical;
      case 'alta':
      case 'high':
        return IssueSeverity.high;
      case 'media':
      case 'medium':
        return IssueSeverity.medium;
      case 'baja':
      case 'low':
        return IssueSeverity.low;
      default:
        return IssueSeverity.medium;
    }
  }

  /// Convierte el string de estado del backend al enum [IssueStatus].
  static IssueStatus _parseStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'abierta':
      case 'abierto':
      case 'open':
        return IssueStatus.open;
      case 'en_progreso':
      case 'en progreso':
      case 'in_progress':
        return IssueStatus.inProgress;
      case 'resuelta':
      case 'resuelto':
      case 'resolved':
        return IssueStatus.resolved;
      case 'cerrada':
      case 'cerrado':
      case 'closed':
        return IssueStatus.closed;
      default:
        return IssueStatus.open;
    }
  }

  /// Crea un [Issue] a partir del JSON de la API.
  factory Issue.fromJson(Map<String, dynamic> json) {
    // Reporter — puede ser objeto usuario o string
    final reporterRaw = json['reportado_por'] ?? json['reporter'] ?? json['creador'] ?? json['reportante'];
    String reporterName = '';
    if (reporterRaw is Map) {
      reporterName = reporterRaw['nombre'] as String? ??
          reporterRaw['name'] as String? ?? '';
    } else {
      reporterName = reporterRaw as String? ?? '';
    }

    // Assigned to — puede ser objeto o string
    final assignedRaw = json['asignado_a'] ?? json['assigned_to'];
    String? assignedName;
    if (assignedRaw is Map) {
      assignedName = assignedRaw['nombre'] as String? ??
          assignedRaw['name'] as String?;
    } else {
      assignedName = assignedRaw as String?;
    }

    // Proyecto — puede venir como objeto anidado {id, nombre} o como string
    final proyectoRaw = json['proyecto'];
    String? projName;
    int? projIdFromProyecto;
    if (proyectoRaw is Map) {
      projName = proyectoRaw['nombre'] as String?;
      projIdFromProyecto = (proyectoRaw['id'] as num?)?.toInt();
    } else if (proyectoRaw is String) {
      projName = proyectoRaw;
    }

    // Fotos
    final fotosRaw = json['fotos'] as List<dynamic>? ?? [];
    final photos = fotosRaw
        .map((e) => ReportPhoto(
              path: _formatPhotoUrl((e as Map)['url'] as String? ?? e['path'] as String?),
              description:
                  e['descripcion'] as String? ?? e['description'] as String? ?? '',
              category: e['categoria'] as String? ?? '',
            ))
        .toList();

    // Timeline
    final timelineRaw = json['historial'] as List<dynamic>? ??
        json['timeline'] as List<dynamic>? ?? [];
    final timeline = timelineRaw
        .map((e) =>
            IssueTimelineEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    // Comentarios
    final comentariosRaw = json['comentarios'] as List<dynamic>? ?? [];
    final comments = comentariosRaw
        .map((e) => IssueComment.fromJson(e as Map<String, dynamic>))
        .toList();

    return Issue(
      id: json['id']?.toString() ?? '',
      code: json['codigo']?.toString() ?? json['code']?.toString(),
      title: json['titulo'] as String? ?? json['title'] as String? ?? '',
      description:
          json['descripcion'] as String? ?? json['description'] as String? ?? '',
      category:
          json['categoria'] as String? ?? json['category'] as String? ?? '',
      location: json['ubicacion'] as String? ?? json['location'] as String? ?? '',
      severity: _parseSeverity(
          json['severidad'] as String? ?? json['severity'] as String?),
      status: _parseStatus(
          json['estado'] as String? ?? json['status'] as String?),
      reportedAt: DateTime.tryParse(
              json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      reporter: reporterName,
      assignedTo: assignedName,
      photos: photos,
      timeline: timeline,
      comments: comments,
      latitude: (json['latitud'] ?? json['latitude'])?.toDouble(),
      longitude: (json['longitud'] ?? json['longitude'])?.toDouble(),
      projectId: (json['proyecto_id'] as num?)?.toInt() ??
          (json['project_id'] as num?)?.toInt() ??
          projIdFromProyecto,
      projectName: projName,
    );
  }
}
