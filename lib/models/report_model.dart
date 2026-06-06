import 'dart:convert';

class ReportPhoto {
  final String path;
  final String description;
  final String category;
  final bool isMain;
  final DateTime? timestamp;
  final double? latitude;
  final double? longitude;

  ReportPhoto({
    required this.path,
    this.description = '',
    this.category = '',
    this.isMain = false,
    this.timestamp,
    this.latitude,
    this.longitude,
  });

  ReportPhoto copyWith({
    String? path,
    String? description,
    String? category,
    bool? isMain,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
  }) {
    return ReportPhoto(
      path: path ?? this.path,
      description: description ?? this.description,
      category: category ?? this.category,
      isMain: isMain ?? this.isMain,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'description': description,
        'category': category,
        'isMain': isMain,
        'timestamp': timestamp?.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory ReportPhoto.fromJson(Map<String, dynamic> json) => ReportPhoto(
        path: json['path'],
        description: json['description'] ?? '',
        category: json['category'] ?? '',
        isMain: json['isMain'] ?? false,
        timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
        latitude: json['latitude'],
        longitude: json['longitude'],
      );
}

class DailyReport {
  final String? id;
  final String projectId;
  final DateTime date;
  final String shift;
  final String category;
  final int progress;
  final String description;
  final List<ReportPhoto> photos;
  final bool isSynced;

  DailyReport({
    this.id,
    required this.projectId,
    required this.date,
    required this.shift,
    required this.category,
    required this.progress,
    required this.description,
    required this.photos,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date.toIso8601String(),
        'shift': shift,
        'category': category,
        'progress': progress,
        'description': description,
        'photos': photos.map((p) => p.toJson()).toList(),
        'isSynced': isSynced,
      };

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
        id: json['id'],
        projectId: json['projectId'],
        date: DateTime.parse(json['date']),
        shift: json['shift'],
        category: json['category'],
        progress: json['progress'],
        description: json['description'],
        photos: (json['photos'] as List)
            .map((p) => ReportPhoto.fromJson(p))
            .toList(),
        isSynced: json['isSynced'] ?? false,
      );
}
