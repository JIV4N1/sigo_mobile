import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'navigation_service.dart';
import '../screens/login_screen.dart';

/// Excepción personalizada para errores de la API SIGO.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}

/// Servicio HTTP genérico para comunicación con el backend Laravel.
///
/// - Inyecta el token Bearer automáticamente en cada petición.
/// - Si la respuesta es 401, cierra sesión y navega al login.
/// - Si la respuesta tiene `"status": "error"`, lanza [ApiException].
/// - Timeout de 15 segundos por petición.
class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  // ─── Headers ──────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Manejo de respuesta ──────────────────────────────────────────────────────

  /// Decodifica la respuesta HTTP y maneja errores comunes.
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // 401 — Token inválido o expirado: cerrar sesión y volver al login
    if (response.statusCode == 401) {
      _handleUnauthorized();
      throw ApiException('Sesión expirada. Por favor inicia sesión de nuevo.',
          statusCode: 401);
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Error al procesar la respuesta del servidor.',
        statusCode: response.statusCode,
      );
    }

    // La API retorna { "status": "error", "message": "...", "errors": {...} }
    if (body['status'] == 'error') {
      throw ApiException(
        body['message'] as String? ?? 'Error desconocido del servidor.',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }

    // Códigos de error HTTP que no retornan estructura estándar
    if (response.statusCode >= 400) {
      throw ApiException(
        body['message'] as String? ?? 'Error del servidor (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    return body;
  }

  /// Maneja el caso de respuesta 401: limpia sesión y navega al login.
  static void _handleUnauthorized() {
    AuthService.clearSession();
    NavigationService.navigateAndRemoveAll(const LoginScreen());
  }

  // ─── Métodos públicos ─────────────────────────────────────────────────────────

  /// GET a [url], retorna el cuerpo de la respuesta ya decodificado.
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(url).replace(
      queryParameters: queryParams,
    );

    try {
      final headers = await _getHeaders();
      final response =
          await http.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw ApiException('Error de comunicación con el servidor.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// POST a [url] con [body] en formato JSON.
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw ApiException('Error de comunicación con el servidor.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// PUT a [url] con [body] en formato JSON.
  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw ApiException('Error de comunicación con el servidor.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// POST multipart para envío de archivos (fotos).
  ///
  /// [fields] contiene los campos de texto.
  /// [filePaths] contiene rutas de archivos a adjuntar con el [fileFieldName].
  static Future<Map<String, dynamic>> postMultipart(
    String url, {
    Map<String, String> fields = const {},
    List<String> filePaths = const [],
    String fileFieldName = 'fotos[]',
  }) async {
    final uri = Uri.parse(url);

    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest('POST', uri);

      // Headers de autenticación (sin Content-Type, lo asigna multipart)
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // Campos de texto
      request.fields.addAll(fields);

      // Archivos adjuntos
      for (final path in filePaths) {
        if (path.isNotEmpty && File(path).existsSync()) {
          request.files.add(await http.MultipartFile.fromPath(
            fileFieldName,
            path,
          ));
        }
      }

      final streamedResponse =
          await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Sin conexión a internet. Verifica tu red.');
    } catch (e) {
      throw ApiException('Error al subir archivos: ${e.toString()}');
    }
  }
}
