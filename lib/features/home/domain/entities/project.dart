/// Representa um projeto de planta baixa salvo pelo usuário.
/// É uma classe simples, só com dados (não sabe nada de Flutter).
class Project {
  final String id;
  final String name;

  /// Área total em metros quadrados.
  final double areaM2;

  final DateTime createdAt;
  final String? backgroundPath;

  const Project({
    required this.id,
    required this.name,
    required this.areaM2,
    required this.createdAt,
    this.backgroundPath,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final area = json['area_m2'];

    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      areaM2: area is num ? area.toDouble() : double.parse(area as String),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      backgroundPath: json['background_path'] as String?,
    );
  }
}
