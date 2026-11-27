import '../entities/dimension_line.dart';
import '../entities/floor_plan.dart';
import '../entities/plan.dart';
import '../entities/point_2d.dart';

/// Gera as cotas EXTERNAS a partir da geometria dos cômodos.
///
/// Para cada lado (topo, base, esquerda, direita):
///   - camada 0: cadeia de trechos (ex.: 4 m + 6 m), a partir dos cantos
///     de cômodos que encostam no contorno daquele lado;
///   - camada seguinte: cota TOTAL do lado (ex.: 10 m).
/// Se o lado não tem divisões, só a cota total é gerada (na camada 0).
class DimensionBuilder {
  const DimensionBuilder();

  static const double _tolerance = 0.01; // 1 cm: "está na linha do contorno"
  static const double _minSegmentM = 0.05; // ignora trechos menores que 5 cm

  List<DimensionLine> build(FloorPlan plan) {
    final Plan? box = plan.buildingBoundingBox();
    if (box == null) return const [];

    final List<Point2D> vertices = [
      for (final Plan room in plan.rooms) ...room.vertices,
    ];

    return [
      for (final DimensionSide side in DimensionSide.values)
        ..._forSide(side, vertices, box),
    ];
  }

  List<DimensionLine> _forSide(
    DimensionSide side,
    List<Point2D> vertices,
    Plan box,
  ) {
    final bool horizontal =
        side == DimensionSide.top || side == DimensionSide.bottom;

    // Coordenada do contorno neste lado e extensão ao longo dele.
    final double edge = switch (side) {
      DimensionSide.top => box.minY,
      DimensionSide.bottom => box.maxY,
      DimensionSide.left => box.minX,
      DimensionSide.right => box.maxX,
    };
    final double axisMin = horizontal ? box.minX : box.minY;
    final double axisMax = horizontal ? box.maxX : box.maxY;

    // Posições (ao longo do lado) dos cantos que estão EM CIMA do contorno.
    final List<double> positions = [
      for (final Point2D v in vertices)
        if (((horizontal ? v.y : v.x) - edge).abs() <= _tolerance)
          horizontal ? v.x : v.y,
    ]..sort();

    // Remove repetidos (dois cômodos compartilham o mesmo canto).
    final List<double> unique = [];
    for (final double p in positions) {
      if (unique.isEmpty || (p - unique.last).abs() > _tolerance) unique.add(p);
    }

    // A cadeia só vale se começa e termina nas extremidades do lado
    // e tem pelo menos 2 trechos.
    final bool hasChain =
        unique.length > 2 &&
        (unique.first - axisMin).abs() <= _tolerance &&
        (unique.last - axisMax).abs() <= _tolerance;

    final List<DimensionLine> lines = [];

    if (hasChain) {
      for (int i = 0; i < unique.length - 1; i++) {
        if (unique[i + 1] - unique[i] < _minSegmentM) continue;
        lines.add(
          DimensionLine(
            side: side,
            from: unique[i],
            to: unique[i + 1],
            edgeCoord: edge,
            tier: 0,
          ),
        );
      }
    }

    lines.add(
      DimensionLine(
        side: side,
        from: axisMin,
        to: axisMax,
        edgeCoord: edge,
        tier: hasChain ? 1 : 0,
        isOverall: true,
      ),
    );

    return lines;
  }
}
