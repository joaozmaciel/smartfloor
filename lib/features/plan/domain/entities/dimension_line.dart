/// Lado da construção em que uma cota é desenhada.
enum DimensionSide { top, bottom, left, right }

/// Uma cota externa (um trecho medido, ou a cota total de um lado).
///
/// Guardamos só coordenadas em METROS ao longo do lado. Onde a cota é
/// desenhada na tela (afastamento, tracejado, texto) é decisão do painter.
class DimensionLine {
  final DimensionSide side;

  /// Início e fim ao longo do lado: X para topo/base, Y para esquerda/direita.
  final double from;
  final double to;

  /// Coordenada do contorno da construção neste lado
  /// (Y no topo/base, X na esquerda/direita): de onde saem as linhas de chamada.
  final double edgeCoord;

  /// 0 = camada mais próxima da parede; 1 = camada de fora.
  final int tier;

  /// true para a cota TOTAL do lado.
  final bool isOverall;

  const DimensionLine({
    required this.side,
    required this.from,
    required this.to,
    required this.edgeCoord,
    required this.tier,
    this.isOverall = false,
  });

  double get lengthM => (to - from).abs();

  bool get isHorizontal =>
      side == DimensionSide.top || side == DimensionSide.bottom;
}
