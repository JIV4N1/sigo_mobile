/// Modelo estándar de respuesta de la API SIGO (Laravel).
///
/// Formato de éxito:   {"status":"success","data":{},"message":""}
/// Formato de error:   {"status":"error","message":"","errors":{}}
class ApiResponse {
  final String status;
  final dynamic data;
  final String? message;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.errors,
  });

  /// ¿La respuesta fue exitosa?
  bool get isSuccess => status == 'success';

  /// ¿La respuesta fue un error?
  bool get isError => status == 'error';

  /// Crea un [ApiResponse] desde el JSON decodificado de la API.
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] as String? ?? 'error',
      data: json['data'],
      message: json['message'] as String?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  /// Retorna el primer mensaje de error de validación encontrado.
  String? get firstError {
    if (errors == null || errors!.isEmpty) return message;
    final firstField = errors!.values.first;
    if (firstField is List && firstField.isNotEmpty) {
      return firstField.first as String?;
    }
    return firstField as String?;
  }

  @override
  String toString() =>
      'ApiResponse(status: $status, message: $message, data: $data)';
}
