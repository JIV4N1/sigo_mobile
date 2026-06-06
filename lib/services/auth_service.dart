import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de autenticación basado en Laravel Sanctum.
/// Gestiona el token Bearer y los datos del usuario en SharedPreferences.
class AuthService {
  // Claves de almacenamiento
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  // ─── Token ────────────────────────────────────────────────────────────────────

  /// Guarda el token y datos del usuario tras un login exitoso.
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  /// Borra el token y los datos del usuario (logout).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  /// Retorna el token Bearer guardado, o null si no hay sesión.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Verifica si hay una sesión activa (token guardado).
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Usuario ──────────────────────────────────────────────────────────────────

  /// Retorna los datos del usuario guardado como Map, o null si no hay sesión.
  static Future<Map<String, dynamic>?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_keyUser);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Retorna el rol del usuario en minúsculas.
  /// Valores posibles: 'supervisor', 'ingeniero', 'gerente', 'administrador'.
  /// Retorna 'supervisor' como fallback seguro si no hay datos.
  static Future<String> getRol() async {
    final user = await getUsuario();
    if (user == null) return 'supervisor';

    // El backend puede devolver el rol en el objeto usuario o en un campo 'rol'
    // Intentar diferentes estructuras posibles
    final dynamic rolData = user['rol'] ?? user['role'] ?? user['nombre_rol'];
    if (rolData is Map) {
      return (rolData['nombre'] as String? ?? 'supervisor').toLowerCase();
    }
    return (rolData as String? ?? 'supervisor').toLowerCase();
  }

  /// Retorna el nombre completo del usuario autenticado.
  static Future<String> getNombre() async {
    final user = await getUsuario();
    return user?['nombre'] as String? ??
        user?['name'] as String? ??
        'Usuario';
  }

  /// Retorna las iniciales del nombre para el avatar.
  static Future<String> getIniciales() async {
    final nombre = await getNombre();
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
  }
}
