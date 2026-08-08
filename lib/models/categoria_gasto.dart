class CategoriaGasto {
  final int id;
  final String nombre;

  CategoriaGasto({required this.id, required this.nombre});

  factory CategoriaGasto.fromJson(Map<String, dynamic> json) {
    return CategoriaGasto(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  static List<CategoriaGasto> fromJsonList(List<dynamic> list) {
    return list
        .map((e) => CategoriaGasto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
