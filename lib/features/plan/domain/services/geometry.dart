import '../entities/point_2d.dart';

/// Tolerância geométrica padrão: 1 cm (em metros).
const double geometryEpsilonM = 0.01;

const double _crossEpsilon = 1e-9;

/// Produto vetorial de (b - a) por (c - a).
/// Positivo = c está de um lado da reta a-b, negativo = do outro, ~0 = em cima dela.
double cross(Point2D a, Point2D b, Point2D c) {
  return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

/// Distância do ponto [p] ao segmento a-b, em metros.
double distanceToSegment(Point2D p, Point2D a, Point2D b) {
  final double dx = b.x - a.x;
  final double dy = b.y - a.y;
  final double lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) return p.distanceTo(a);

  final double t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared)
      .clamp(0.0, 1.0)
      .toDouble();
  return p.distanceTo(Point2D(a.x + dx * t, a.y + dy * t));
}

/// Os segmentos a-b e c-d se CRUZAM de verdade (no interior dos dois)?
/// Encostar nas pontas (junção em "T") ou ser colinear NÃO conta como cruzamento.
bool segmentsCrossProperly(Point2D a, Point2D b, Point2D c, Point2D d) {
  final double d1 = cross(a, b, c);
  final double d2 = cross(a, b, d);
  final double d3 = cross(c, d, a);
  final double d4 = cross(c, d, b);

  final bool splitsCD =
      (d1 > _crossEpsilon && d2 < -_crossEpsilon) ||
      (d1 < -_crossEpsilon && d2 > _crossEpsilon);
  final bool splitsAB =
      (d3 > _crossEpsilon && d4 < -_crossEpsilon) ||
      (d3 < -_crossEpsilon && d4 > _crossEpsilon);

  return splitsCD && splitsAB;
}

/// Distância (em metros) que um "raio" partindo de [origin] na direção (dx, dy)
/// percorre até bater no segmento a-b. Devolve null se não bater.
double? rayDistance(
  Point2D origin,
  double dx,
  double dy,
  Point2D a,
  Point2D b,
) {
  final double ex = b.x - a.x;
  final double ey = b.y - a.y;
  final double denominator = dx * ey - dy * ex;
  if (denominator.abs() < 1e-12) return null; // raio paralelo ao segmento

  final double ox = a.x - origin.x;
  final double oy = a.y - origin.y;
  final double t = (ox * ey - oy * ex) / denominator; // distância no raio
  final double s =
      (ox * dy - oy * dx) / denominator; // posição no segmento (0 a 1)

  if (t > 1e-9 && s >= -1e-9 && s <= 1 + 1e-9) return t;
  return null;
}
