/// Representa um projeto de planta baixa salvo pelo usuário.
/// É uma classe simples, só com dados (não sabe nada de Flutter).
class Project {
  final String id;
  final String name;

  /// Área total em metros quadrados.
  final double areaM2;

  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.areaM2,
    required this.createdAt,
  });
}