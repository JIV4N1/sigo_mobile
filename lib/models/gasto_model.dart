import '../config/api_config.dart';

class ProyectoMini {
  final int id;
  final String nombre;

  ProyectoMini({required this.id, required this.nombre});

  factory ProyectoMini.fromJson(Map<String, dynamic> json) {
    return ProyectoMini(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

class CategoriaMini {
  final int id;
  final String nombre;

  CategoriaMini({required this.id, required this.nombre});

  factory CategoriaMini.fromJson(Map<String, dynamic> json) {
    return CategoriaMini(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

class ProveedorMini {
  final int id;
  final String nombre;

  ProveedorMini({required this.id, required this.nombre});

  factory ProveedorMini.fromJson(Map<String, dynamic> json) {
    return ProveedorMini(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

class UsuarioMini {
  final int id;
  final String nombre;

  UsuarioMini({required this.id, required this.nombre});

  factory UsuarioMini.fromJson(Map<String, dynamic> json) {
    return UsuarioMini(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

class Gasto {
  final int id;
  final int proyectoId;
  final ProyectoMini? proyecto;
  final int categoriaId;
  final CategoriaMini? categoria;
  final int? proveedorId;
  final ProveedorMini? proveedor;
  final double monto;
  final String fecha;
  final String? descripcion;
  final String? comprobanteUrl;
  final UsuarioMini? usuario;
  final DateTime createdAt;
  final DateTime updatedAt;

  Gasto({
    required this.id,
    required this.proyectoId,
    this.proyecto,
    required this.categoriaId,
    this.categoria,
    this.proveedorId,
    this.proveedor,
    required this.monto,
    required this.fecha,
    this.descripcion,
    this.comprobanteUrl,
    this.usuario,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Extensión del archivo del comprobante en minúsculas (sin el punto), o null.
  String? get comprobanteExt {
    final url = comprobanteUrl;
    if (url == null || url.isEmpty) return null;
    final clean = url.split('?').first;
    final dotIndex = clean.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == clean.length - 1) return null;
    return clean.substring(dotIndex + 1).toLowerCase();
  }

  bool get comprobanteEsPdf => comprobanteExt == 'pdf';

  static String? _formatUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  factory Gasto.fromJson(Map<String, dynamic> json) {
    final proyectoRaw = json['proyecto'];
    final categoriaRaw = json['categoria'];
    final proveedorRaw = json['proveedor'];
    final usuarioRaw = json['usuario'] ?? json['capturista'] ?? json['creado_por'];

    return Gasto(
      id: (json['id'] as num).toInt(),
      proyectoId: (json['proyecto_id'] as num?)?.toInt() ??
          (proyectoRaw is Map ? (proyectoRaw['id'] as num?)?.toInt() : null) ??
          0,
      proyecto: proyectoRaw is Map
          ? ProyectoMini.fromJson(proyectoRaw as Map<String, dynamic>)
          : null,
      categoriaId: (json['categoria_id'] as num?)?.toInt() ??
          (categoriaRaw is Map ? (categoriaRaw['id'] as num?)?.toInt() : null) ??
          0,
      categoria: categoriaRaw is Map
          ? CategoriaMini.fromJson(categoriaRaw as Map<String, dynamic>)
          : null,
      proveedorId: (json['proveedor_id'] as num?)?.toInt(),
      proveedor: proveedorRaw is Map
          ? ProveedorMini.fromJson(proveedorRaw as Map<String, dynamic>)
          : null,
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fecha']?.toString() ?? '',
      descripcion: json['descripcion'] as String?,
      comprobanteUrl: _formatUrl(
        json['comprobante_url'] as String? ?? json['comprobante'] as String?,
      ),
      usuario: usuarioRaw is Map
          ? UsuarioMini.fromJson(usuarioRaw as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Resultado paginado de [GastoService.listar].
class GastoListResult {
  final List<Gasto> gastos;
  final int currentPage;
  final int lastPage;
  final int total;

  GastoListResult({
    required this.gastos,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
