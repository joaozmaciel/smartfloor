import 'point_2d.dart';

/// Uma caixa retangular em METROS (usada para evitar que rótulos caiam sobre móveis).
class BoxM {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const BoxM({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  /// O ponto [p] está dentro da caixa (aumentada em [margin] metros)?
  bool contains(Point2D p, {double margin = 0}) {
    return p.x >= minX - margin &&
        p.x <= maxX + margin &&
        p.y >= minY - margin &&
        p.y <= maxY + margin;
  }
}
