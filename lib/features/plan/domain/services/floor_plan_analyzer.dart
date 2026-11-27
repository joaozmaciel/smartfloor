import '../entities/floor_plan.dart';
import '../entities/plan.dart';
import '../entities/point_2d.dart';
import '../entities/wall.dart';
import 'geometry.dart';

enum PlanIssueSeverity { warning, error }

/// Um problema encontrado na planta.
class PlanIssue {
  final PlanIssueSeverity severity;
  final String message;

  const PlanIssue(this.severity, this.message);
}

/// Medidas de um cômodo, já prontas para exibir.
class RoomMetrics {
  final String name;
  final double areaM2; // área exata
  final double
  roundedAreaM2; // área arredondada a 2 casas (o que aparece na tela)
  final double perimeterM;

  const RoomMetrics({
    required this.name,
    required this.areaM2,
    required this.roundedAreaM2,
    required this.perimeterM,
  });
}

/// Resultado da validação e dos cálculos.
class FloorPlanReport {
  final List<RoomMetrics> rooms;

  /// Soma EXATA das áreas.
  final double builtAreaM2;

  /// Soma dos valores ARREDONDADOS que aparecem nos rótulos. É este o total
  /// que deve ser mostrado: assim a soma dos números na tela sempre fecha.
  final double builtAreaRoundedM2;

  /// Área do menor retângulo que contém todos os cômodos.
  final double boundingAreaM2;

  final double? lotAreaM2;
  final List<PlanIssue> issues;

  const FloorPlanReport({
    required this.rooms,
    required this.builtAreaM2,
    required this.builtAreaRoundedM2,
    required this.boundingAreaM2,
    required this.lotAreaM2,
    required this.issues,
  });

  bool get hasErrors =>
      issues.any((i) => i.severity == PlanIssueSeverity.error);

  /// Quanto do retângulo envolvente está ocupado por cômodos (0 a 1).
  double get fillRatio => boundingAreaM2 > 0 ? builtAreaM2 / boundingAreaM2 : 0;
}

/// Valida a geometria e calcula as áreas ANTES de desenhar.
class FloorPlanAnalyzer {
  const FloorPlanAnalyzer();

  FloorPlanReport analyze(FloorPlan plan) {
    final List<PlanIssue> issues = [];
    final List<RoomMetrics> metrics = [];
    final List<bool> usable = [];

    // ---------- Cada cômodo sozinho ----------
    for (final Plan room in plan.rooms) {
      if (room.vertices.length < 3) {
        issues.add(
          PlanIssue(
            PlanIssueSeverity.error,
            'O cômodo "${room.name}" precisa de pelo menos 3 cantos.',
          ),
        );
        metrics.add(
          RoomMetrics(
            name: room.name,
            areaM2: 0,
            roundedAreaM2: 0,
            perimeterM: 0,
          ),
        );
        usable.add(false);
        continue;
      }

      final double area = room.areaM2;
      bool ok = true;

      if (area < 0.01) {
        issues.add(
          PlanIssue(
            PlanIssueSeverity.error,
            'O cômodo "${room.name}" tem área nula.',
          ),
        );
        ok = false;
      }
      if (_selfIntersects(room)) {
        issues.add(
          PlanIssue(
            PlanIssueSeverity.error,
            'As paredes do cômodo "${room.name}" se cruzam: a área não é confiável.',
          ),
        );
        ok = false;
      }

      metrics.add(
        RoomMetrics(
          name: room.name,
          areaM2: area,
          roundedAreaM2: _round2(area),
          perimeterM: room.perimeterM,
        ),
      );
      usable.add(ok);
    }

    // ---------- Sobreposição entre cômodos ----------
    for (int i = 0; i < plan.rooms.length; i++) {
      for (int j = i + 1; j < plan.rooms.length; j++) {
        if (!usable[i] || !usable[j]) continue;
        if (_roomsOverlap(plan.rooms[i], plan.rooms[j])) {
          issues.add(
            PlanIssue(
              PlanIssueSeverity.error,
              'Os cômodos "${plan.rooms[i].name}" e "${plan.rooms[j].name}" '
              'se sobrepõem: a área total estaria contada em duplicidade.',
            ),
          );
        }
      }
    }

    // ---------- Cômodos dentro do terreno ----------
    final Plan? lot = plan.lot;
    if (lot != null && lot.vertices.length >= 3) {
      for (int i = 0; i < plan.rooms.length; i++) {
        if (!usable[i]) continue;
        final bool outside = plan.rooms[i].vertices.any(
          (v) => !_insideOrOnBoundary(lot, v),
        );
        if (outside) {
          issues.add(
            PlanIssue(
              PlanIssueSeverity.warning,
              'O cômodo "${plan.rooms[i].name}" ultrapassa o limite do terreno.',
            ),
          );
        }
      }
    }

    // ---------- Totais ----------
    final double exact = metrics.fold(0.0, (sum, m) => sum + m.areaM2);
    final double rounded = metrics.fold(0.0, (sum, m) => sum + m.roundedAreaM2);

    final Plan? box = plan.buildingBoundingBox();

    return FloorPlanReport(
      rooms: metrics,
      builtAreaM2: exact,
      builtAreaRoundedM2: _round2(rounded),
      boundingAreaM2: box?.areaM2 ?? 0,
      lotAreaM2: lot != null && lot.vertices.length >= 3 ? lot.areaM2 : null,
      issues: issues,
    );
  }

  // ---------- Auxiliares ----------

  double _round2(double value) => (value * 100).round() / 100;

  /// Alguma parede cruza outra que NÃO é vizinha dela?
  bool _selfIntersects(Plan room) {
    final List<Wall> walls = room.walls;
    final int n = walls.length;

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final bool neighbors = j == i + 1 || (i == 0 && j == n - 1);
        if (neighbors) continue;

        if (segmentsCrossProperly(
          walls[i].start,
          walls[i].end,
          walls[j].start,
          walls[j].end,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  /// Dois cômodos ocupam a mesma região? Cômodos que apenas dividem uma
  /// parede (ou se encostam num canto) NÃO se sobrepõem.
  bool _roomsOverlap(Plan a, Plan b) {
    // 1) paredes que se cruzam de verdade
    for (final Wall wa in a.walls) {
      for (final Wall wb in b.walls) {
        if (segmentsCrossProperly(wa.start, wa.end, wb.start, wb.end)) {
          return true;
        }
      }
    }
    // 2) pontos do interior de um dentro do outro (um cômodo dentro do outro)
    return _hasPointStrictlyInside(a, b) || _hasPointStrictlyInside(b, a);
  }

  /// Algum canto, meio de parede ou o centro de [inner] está no INTERIOR de [outer]?
  bool _hasPointStrictlyInside(Plan inner, Plan outer) {
    final List<Point2D> samples = [
      ...inner.vertices,
      for (final Wall wall in inner.walls)
        Point2D(
          (wall.start.x + wall.end.x) / 2,
          (wall.start.y + wall.end.y) / 2,
        ),
      inner.centroid,
    ];
    return samples.any((p) => _strictlyInside(outer, p));
  }

  bool _strictlyInside(Plan polygon, Point2D p) {
    if (!polygon.containsPoint(p)) return false;
    // Se está em cima de uma parede, não é interior.
    for (final Wall wall in polygon.walls) {
      if (distanceToSegment(p, wall.start, wall.end) <= geometryEpsilonM) {
        return false;
      }
    }
    return true;
  }

  bool _insideOrOnBoundary(Plan polygon, Point2D p) {
    if (polygon.containsPoint(p)) return true;
    return polygon.walls.any(
      (w) => distanceToSegment(p, w.start, w.end) <= geometryEpsilonM,
    );
  }
}
