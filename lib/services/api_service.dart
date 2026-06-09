import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'navigation_service.dart';
import '../screens/login_screen.dart';

/// Excepción personalizada para errores de la API SIGO.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}

/// Servicio HTTP genérico para comunicación con el backend Laravel.
///
/// ## Metodología de conexión
///
/// 1. **Protocolo**: HTTPS sobre ngrok-free (TLS terminado en ngrok).
/// 2. **Autenticación**: Bearer Token (Laravel Sanctum). El token se guarda en
///    SharedPreferences y se inyecta automáticamente en cada request.
/// 3. **Headers obligatorios**:
///    - `Content-Type: application/json`
///    - `Accept: application/json`
///    - `ngrok-skip-browser-warning: true` → evita que ngrok sirva HTML en vez de JSON.
///    - `Authorization: Bearer <token>` → sólo cuando hay sesión activa.
/// 4. **Formato de respuesta esperado**:
///    - Éxito: `{"status":"success","data":{...},"message":""}`
///    - Error:  `{"status":"error","message":"...","errors":{...}}`
/// 5. **Timeout**: 20 segundos (ngrok puede añadir latencia extra).
/// 6. **Error 401**: cierra sesión automáticamente y navega al LoginScreen.
/// 7. **Multipart**: para subida de fotos con el campo `fotos[]`.
class ApiService {
  static const Duration _timeout = Duration(seconds: 20);

  // ─── Headers ──────────────────────────────────────────────────────────────────

  /// Construye los headers base incluyendo el token Bearer si hay sesión activa.
  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
  }) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (requiresAuth) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ─── Manejo de respuesta ──────────────────────────────────────────────────────

  /// Decodifica la respuesta HTTP y maneja errores comunes.
  ///
  /// Lanza [ApiException] si:
  /// - El código HTTP es 401 (sesión expirada).
  /// - El campo `status` en el JSON es `"error"`.
  /// - El código HTTP >= 400 y no es estructura estándar.
  /// - La respuesta no puede decodificarse como JSON.
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // 401 — Token inválido o expirado
    if (response.statusCode == 401) {
      _handleUnauthorized();
      throw const ApiException(
        'Sesión expirada. Por favor inicia sesión de nuevo.',
        statusCode: 401,
      );
    }

    // Intentar parsear JSON
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      // Si la respuesta es HTML (ej. la advertencia de ngrok sin el header)
      // o no es JSON válido
      throw ApiException(
        'Respuesta inesperada del servidor (¿HTML en vez de JSON?). '
        'Verifica que el header ngrok-skip-browser-warning esté activo.',
        statusCode: response.statusCode,
      );
    }

    // Error de negocio: {"status":"error","message":"...","errors":{...}}
    if (body['status'] == 'error') {
      throw ApiException(
        body['message'] as String? ?? 'Error desconocido del servidor.',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }

    // Otros códigos HTTP de error que no retornan estructura estándar
    if (response.statusCode >= 400) {
      throw ApiException(
        body['message'] as String? ??
            'Error del servidor (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    return body;
  }

  /// Limpia la sesión y navega al LoginScreen cuando el token ya no es válido.
  static void _handleUnauthorized() {
    AuthService.clearSession();
    NavigationService.navigateAndRemoveAll(const LoginScreen());
  }

  // ─── Métodos públicos ─────────────────────────────────────────────────────────

  /// GET a [url], con query params opcionales.
  /// Retorna el body completo decodificado (incluyendo `status`, `data`, etc.).
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response =
          await http.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw const ApiException('Error de comunicación con el servidor.');
    } on TimeoutException {
      throw const ApiException(
          'El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// POST a [url] con [body] en formato JSON.
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
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
      throw const ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw const ApiException('Error de comunicación con el servidor.');
    } on TimeoutException {
      throw const ApiException(
          'El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// PUT a [url] con [body] en formato JSON.
  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
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
      throw const ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw const ApiException('Error de comunicación con el servidor.');
    } on TimeoutException {
      throw const ApiException(
          'El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// PATCH a [url] con [body] en formato JSON.
  static Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw const ApiException('Error de comunicación con el servidor.');
    } on TimeoutException {
      throw const ApiException(
          'El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// DELETE a [url].
  static Future<Map<String, dynamic>> delete(
    String url, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response =
          await http.delete(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw const ApiException('Error de comunicación con el servidor.');
    } on TimeoutException {
      throw const ApiException(
          'El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  /// POST multipart para envío de archivos (fotos).
  ///
  /// - [fields]: campos de texto adicionales.
  /// - [filePaths]: rutas locales de las imágenes a subir.
  /// - [fileFieldName]: nombre del campo en el formulario (por defecto `fotos[]`).
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

      // Headers de autenticación (SIN Content-Type — lo asigna multipart automáticamente)
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      // Campos de texto
      request.fields.addAll(fields);

      // Archivos adjuntos — sólo los que existen en disco
      for (final path in filePaths) {
        if (path.isNotEmpty && File(path).existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(fileFieldName, path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw const ApiException(
          'El servidor tardó demasiado subiendo los archivos.');
    } catch (e) {
      throw ApiException('Error al subir archivos: ${e.toString()}');
    }
  }
}


