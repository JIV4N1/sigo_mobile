/// Roles posibles en el sistema SIGO.
enum UserRole {
  supervisor,
  gerente,
  ingeniero,
  administrador,
}

/// Extensión para convertir string a [UserRole] y viceversa.
extension UserRoleExtension on UserRole {
  String get nombre {
    switch (this) {
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.gerente:
        return 'gerente';
      case UserRole.ingeniero:
        return 'ingeniero';
      case UserRole.administrador:
        return 'administrador';
    }
  }

  static UserRole fromString(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'gerente':
        return UserRole.gerente;
      case 'ingeniero':
        return UserRole.ingeniero;
      case 'administrador':
        return UserRole.administrador;
      case 'supervisor':
      default:
        return UserRole.supervisor;
    }
  }
}

/// Modelo de usuario autenticado en SIGO.
///
/// Corresponde al objeto `user` que retorna el endpoint POST /auth/login
/// y GET /auth/me.
class UserModel {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? fotoUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.fotoUrl,
  });

  /// Retorna las iniciales del nombre para usar en avatares.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  /// Retorna el nombre del rol en minúsculas como string.
  String get roleName => role.nombre;

  /// Crea un [UserModel] desde el JSON retornado por la API.
  ///
  /// El backend puede devolver el rol como string o como objeto:
  ///   - String: "supervisor"
  ///   - Objeto: {"id": 1, "nombre": "supervisor"}
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extraer rol — puede ser string u objeto
    final rolRaw = json['rol'] ?? json['role'];
    String rolString = '';
    if (rolRaw is Map) {
      rolString = rolRaw['nombre'] as String? ??
          rolRaw['name'] as String? ?? '';
    } else {
      rolString = rolRaw as String? ?? '';
    }

    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['nombre'] as String? ??
          json['name'] as String? ?? 'Usuario',
      email: json['email'] as String? ?? '',
      role: UserRoleExtension.fromString(rolString),
      phone: json['telefono'] as String? ?? json['phone'] as String?,
      fotoUrl: json['foto_url'] as String? ?? json['avatar'] as String?,
    );
  }

  /// Serializa el modelo a Map para guardarlo en SharedPreferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': name,
        'email': email,
        'rol': roleName,
        'telefono': phone,
        'foto_url': fotoUrl,
      };

  /// Alias de toJson() para compatibilidad.
  Map<String, dynamic> toMap() => toJson();

  /// Crea un [UserModel] desde el JSON guardado en SharedPreferences.
  /// Equivalente a [fromJson] pero garantiza que lee los campos serializados
  /// por [toJson].
  factory UserModel.fromStorage(Map<String, dynamic> json) =>
      UserModel.fromJson(json);

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, role: $roleName)';
}
