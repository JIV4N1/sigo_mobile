import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Servicio de autenticación basado en Laravel Sanctum.
///
/// ## Claves en SharedPreferences
/// - `auth_token`  → token Bearer para las peticiones a la API.
/// - `user_data`   → JSON serializado del usuario autenticado ([UserModel]).
///
/// ## Flujo
/// 1. Login exitoso → [saveSession] guarda el token y el usuario.
/// 2. Cada request  → [getToken] inyecta el Bearer en el header.
/// 3. Logout / 401  → [clearSession] borra ambas claves.
class AuthService {
  // ─── Claves de almacenamiento ──────────────────────────────────────────────
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data'; // clave requerida por el sistema

  // ─── Sesión ────────────────────────────────────────────────────────────────

  /// Guarda el token Bearer y los datos del usuario tras un login exitoso.
  ///
  /// [user] puede ser un [Map] raw de la API o ya serializado mediante
  /// [UserModel.toJson]. Ambos formatos son aceptados por [UserModel.fromJson].
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  /// Borra el token y los datos del usuario (logout o sesión expirada).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  // ─── Token ─────────────────────────────────────────────────────────────────

  /// Retorna el token Bearer guardado, o null si no hay sesión activa.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Verifica si hay una sesión activa (token guardado y no vacío).
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Usuario ───────────────────────────────────────────────────────────────

  /// Retorna el [UserModel] guardado, o null si no hay sesión.
  static Future<UserModel?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_keyUser);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromStorage(map);
    } catch (_) {
      return null;
    }
  }

  /// Retorna los datos del usuario como Map crudo, o null si no hay sesión.
  /// Útil para pantallas que ya manejan el JSON directamente.
  static Future<Map<String, dynamic>?> getUsuarioMap() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_keyUser);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Retorna el nombre del rol en minúsculas.
  ///
  /// Valores posibles: `supervisor`, `ingeniero`, `gerente`, `administrador`.
  /// Retorna `'supervisor'` como fallback seguro.
  static Future<String> getRol() async {
    final user = await getUsuario();
    return user?.roleName ?? 'supervisor';
  }

  /// Retorna el nombre completo del usuario autenticado.
  static Future<String> getNombre() async {
    final user = await getUsuario();
    return user?.name ?? 'Usuario';
  }

  /// Retorna las iniciales del nombre para usar en avatares.
  static Future<String> getIniciales() async {
    final user = await getUsuario();
    return user?.initials ?? 'U';
  }

  /// Actualiza únicamente los datos del usuario en SharedPreferences
  /// (útil después de un GET /auth/me para refrescar perfil sin nuevo login).
  static Future<void> updateUsuario(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user));
  }
}
