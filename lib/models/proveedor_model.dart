class Proveedor {
  final int id;
  final String nombre;

  Proveedor({required this.id, required this.nombre});

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  static List<Proveedor> fromJsonList(List<dynamic> list) {
    return list.map((e) => Proveedor.fromJson(e as Map<String, dynamic>)).toList();
  }
}
