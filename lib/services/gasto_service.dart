import 'dart:io';
import 'api_service.dart';
import 'api_config.dart';
import '../models/gasto_model.dart';
import '../models/categoria_gasto.dart';
import '../models/proveedor_model.dart';

class GastoService {
  static Future<GastoListResult> listar({
    int? proyectoId,
    int? categoriaId,
    String? desde,
    String? hasta,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{'page': page.toString()};
    if (proyectoId != null) queryParams['proyecto_id'] = proyectoId.toString();
    if (categoriaId != null) queryParams['categoria_id'] = categoriaId.toString();
    if (desde != null && desde.isNotEmpty) queryParams['desde'] = desde;
    if (hasta != null && hasta.isNotEmpty) queryParams['hasta'] = hasta;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await ApiService.get(ApiConfig.gastosObra, queryParams: queryParams);
    return _parsePaginated(response, page);
  }

  static GastoListResult _parsePaginated(Map<String, dynamic> response, int page) {
    final rawData = response['data'];

    List<dynamic> list;
    int currentPage = page;
    int lastPage = page;
    int total;

    if (rawData is Map && rawData.containsKey('data')) {
      list = rawData['data'] as List<dynamic>? ?? [];
      currentPage = (rawData['current_page'] as num?)?.toInt() ?? page;
      lastPage = (rawData['last_page'] as num?)?.toInt() ?? page;
      total = (rawData['total'] as num?)?.toInt() ?? list.length;
    } else if (rawData is List) {
      list = rawData;
      total = list.length;
    } else {
      list = [];
      total = 0;
    }

    return GastoListResult(
      gastos: list.map((e) => Gasto.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  static Future<Gasto> obtener(int id) async {
    final response = await ApiService.get(ApiConfig.gastoObraDetail(id));
    return Gasto.fromJson(response['data'] as Map<String, dynamic>);
  }

  static Map<String, String> _buildFields({
    required int proyectoId,
    required int categoriaId,
    int? proveedorId,
    required double monto,
    required String fecha,
    String? descripcion,
  }) {
    final fields = <String, String>{
      'proyecto_id': proyectoId.toString(),
      'categoria_id': categoriaId.toString(),
      'monto': monto.toString(),
      'fecha': fecha,
    };
    if (proveedorId != null) fields['proveedor_id'] = proveedorId.toString();
    if (descripcion != null && descripcion.isNotEmpty) fields['descripcion'] = descripcion;
    return fields;
  }

  /// Crea un nuevo gasto. El `usuario_id` se toma del token en el backend.
  static Future<Gasto> crear({
    required int proyectoId,
    required int categoriaId,
    int? proveedorId,
    required double monto,
    required String fecha,
    String? descripcion,
    File? comprobante,
  }) async {
    final fields = _buildFields(
      proyectoId: proyectoId,
      categoriaId: categoriaId,
      proveedorId: proveedorId,
      monto: monto,
      fecha: fecha,
      descripcion: descripcion,
    );

    final response = await ApiService.postMultipart(
      ApiConfig.gastosObra,
      fields: fields,
      filePaths: comprobante != null ? [comprobante.path] : [],
      fileFieldName: 'comprobante',
    );
    return Gasto.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Actualiza un gasto existente. Usa spoofing `_method=PUT` sobre POST
  /// multipart, ya que PHP no parsea cuerpos multipart en peticiones PUT.
  static Future<Gasto> actualizar(
    int id, {
    required int proyectoId,
    required int categoriaId,
    int? proveedorId,
    required double monto,
    required String fecha,
    String? descripcion,
    File? comprobante,
  }) async {
    final fields = _buildFields(
      proyectoId: proyectoId,
      categoriaId: categoriaId,
      proveedorId: proveedorId,
      monto: monto,
      fecha: fecha,
      descripcion: descripcion,
    );
    fields['_method'] = 'PUT';

    final response = await ApiService.postMultipart(
      ApiConfig.gastoObraDetail(id),
      fields: fields,
      filePaths: comprobante != null ? [comprobante.path] : [],
      fileFieldName: 'comprobante',
    );
    return Gasto.fromJson(response['data'] as Map<String, dynamic>);
  }

  static Future<void> eliminar(int id) async {
    await ApiService.delete(ApiConfig.gastoObraDetail(id));
  }

  static Future<Map<String, dynamic>> resumen({
    int? proyectoId,
    String? desde,
    String? hasta,
  }) async {
    final queryParams = <String, String>{};
    if (proyectoId != null) queryParams['proyecto_id'] = proyectoId.toString();
    if (desde != null && desde.isNotEmpty) queryParams['desde'] = desde;
    if (hasta != null && hasta.isNotEmpty) queryParams['hasta'] = hasta;

    final response = await ApiService.get(
      ApiConfig.gastosObraResumen,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  static Future<List<CategoriaGasto>> listarCategorias() async {
    final response = await ApiService.get(ApiConfig.gastosObraCategorias);
    final rawData = response['data'];
    final list = rawData is List
        ? rawData
        : (rawData is Map ? rawData['data'] as List<dynamic>? ?? [] : []);
    return CategoriaGasto.fromJsonList(list);
  }

  static Future<List<Proveedor>> listarProveedores({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await ApiService.get(
      ApiConfig.proveedores,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
    final rawData = response['data'];
    final list = rawData is List
        ? rawData
        : (rawData is Map ? rawData['data'] as List<dynamic>? ?? [] : []);
    return Proveedor.fromJsonList(list);
  }
}
