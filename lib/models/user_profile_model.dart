/// Proyecto asignado al usuario, para mostrar en el perfil.
class ProyectoAsignado {
  final String id;
  final String codigo;
  final String nombre;
  final String rolProyecto;

  ProyectoAsignado({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.rolProyecto,
  });

  factory ProyectoAsignado.fromJson(Map<String, dynamic> json) {
    return ProyectoAsignado(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo'] as String? ??
          json['codigo_contrato'] as String? ?? '',
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? '',
      rolProyecto: json['rol_proyecto'] as String? ??
          json['pivot']?['rol'] as String? ?? '',
    );
  }
}

/// Perfil completo del usuario autenticado.
class UserProfile {
  final String id;
  final String nombreCompleto;
  final String email;
  final String telefono;
  final String rolGlobal; // Supervisor, Ingeniero, Gerente, Administrador
  final String? fotoUrl;
  final List<ProyectoAsignado> proyectos;

  UserProfile({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.telefono,
    required this.rolGlobal,
    this.fotoUrl,
    required this.proyectos,
  });

  /// Crea un [UserProfile] a partir del JSON de la API (/auth/me).
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // El rol puede ser un objeto o un string
    final rolRaw = json['rol'] ?? json['role'];
    String rolNombre = '';
    if (rolRaw is Map) {
      rolNombre = rolRaw['nombre'] as String? ??
          rolRaw['name'] as String? ?? '';
    } else {
      rolNombre = rolRaw as String? ?? '';
    }

    // Proyectos asignados (opcional en el endpoint /me)
    final proyectosRaw = json['proyectos'] as List<dynamic>? ?? [];
    final proyectos = proyectosRaw
        .map((e) => ProyectoAsignado.fromJson(e as Map<String, dynamic>))
        .toList();

    return UserProfile(
      id: json['id']?.toString() ?? '',
      nombreCompleto:
          json['nombre'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefono: json['telefono'] as String? ?? json['phone'] as String? ?? '',
      rolGlobal: rolNombre,
      fotoUrl: json['foto_url'] as String? ?? json['avatar'] as String?,
      proyectos: proyectos,
    );
  }
}
