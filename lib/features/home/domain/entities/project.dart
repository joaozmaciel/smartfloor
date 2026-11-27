/// Representa um projeto de planta baixa salvo pelo usuário.
/// É uma classe simples, só com dados (não sabe nada de Flutter).
class Project {
  final String id;
  final String name;

  /// Área total em metros quadrados.
  final double areaM2;
  final double? widthM;
  final double? lengthM;
  final double? heightM;

  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.areaM2,
    required this.createdAt,
    this.widthM,
    this.lengthM,
    this.heightM,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final area = json['area_m2'];

    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      areaM2: area is num ? area.toDouble() : double.parse(area as String),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      widthM: _optionalDouble(json['width_m']),
      lengthM: _optionalDouble(json['length_m']),
      heightM: _optionalDouble(json['height_m']),
    );
  }

  static double? _optionalDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.parse(value as String);
  }
}