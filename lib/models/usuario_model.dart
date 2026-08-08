class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? json['role'] as String? ?? '',
    );
  }
}
