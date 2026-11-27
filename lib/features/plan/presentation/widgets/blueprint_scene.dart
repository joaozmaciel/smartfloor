import '../../domain/entities/box_m.dart';
import '../../domain/entities/dimension_line.dart';
import '../../domain/entities/floor_plan.dart';
import '../../domain/entities/floor_plan_data.dart';
import '../../domain/entities/furniture_item.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';
import '../../domain/entities/wall.dart';
import '../../domain/services/dimension_builder.dart';
import '../../domain/services/floor_plan_analyzer.dart';
import '../../domain/services/geometry.dart';
import '../../domain/services/label_spot_finder.dart';

/// Tudo o que o desenho precisa e que NÃO depende do tamanho da tela:
/// relatório de validação, cotas, pontos dos rótulos e paredes compartilhadas.
/// Calculado uma única vez (e não a cada quadro desenhado).
class BlueprintScene {
  final FloorPlanData data;
  final FloorPlanReport report;
  final List<DimensionLine> dimensions;
  final List<LabelSpot> labelSpots;

  /// sharedEdges[cômodo][parede] = true se a parede é dividida com outro cômodo
  /// (divisória interna) e false se é parede externa.
  final List<List<bool>> sharedEdges;

  final Map<DimensionSide, int> tiersPerSide;
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final bool canDraw;

  const BlueprintScene._({
    required this.data,
    required this.report,
    required this.dimensions,
    required this.labelSpots,
    required this.sharedEdges,
    required this.tiersPerSide,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.canDraw,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;

  factory BlueprintScene.build(FloorPlanData data) {
    final FloorPlan plan = data.plan;
    final FloorPlanReport report = const FloorPlanAnalyzer().analyze(plan);

    final bool canDraw =
        !report.hasErrors &&
        plan.rooms.isNotEmpty &&
        plan.rooms.every((r) => r.vertices.length >= 3);

    // Cômodos inválidos: não desenhamos; a tela mostra os problemas do relatório.
    if (!canDraw) {
      return BlueprintScene._(
        data: data,
        report: report,
        dimensions: const [],
        labelSpots: const [],
        sharedEdges: const [],
        tiersPerSide: const {},
        minX: 0,
        minY: 0,
        maxX: 1,
        maxY: 1,
        canDraw: false,
      );
    }

    final Plan box = plan.buildingBoundingBox()!;
    final List<DimensionLine> dimensions = const DimensionBuilder().build(plan);

    // Quantas camadas de cota cada lado tem (define a margem reservada).
    final Map<DimensionSide, int> tiers = {};
    for (final DimensionLine d in dimensions) {
      final int count = d.tier + 1;
      if (count > (tiers[d.side] ?? 0)) tiers[d.side] = count;
    }

    // Ponto do rótulo de cada cômodo, evitando os móveis que estão nele.
    const LabelSpotFinder finder = LabelSpotFinder();
    final List<LabelSpot> spots = [
      for (final Plan room in plan.rooms)
        finder.find(room, avoid: _furnitureBoxesIn(room, data.furniture)),
    ];

    return BlueprintScene._(
      data: data,
      report: report,
      dimensions: dimensions,
      labelSpots: spots,
      sharedEdges: [
        for (int r = 0; r < plan.rooms.length; r++) _sharedEdges(plan, r),
      ],
      tiersPerSide: tiers,
      minX: box.minX,
      minY: box.minY,
      maxX: box.maxX,
      maxY: box.maxY,
      canDraw: true,
    );
  }

  static List<BoxM> _furnitureBoxesIn(
    Plan room,
    List<FurnitureItem> furniture,
  ) {
    return [
      for (final FurnitureItem item in furniture)
        if (room.containsPoint(item.center)) item.bounds,
    ];
  }

  /// Marca quais paredes do cômodo [roomIndex] são divididas com outro cômodo.
  /// Testa 5 pontos ao longo da parede; se a maioria está sobre a parede de
  /// outro cômodo, ela é uma divisória interna.
  static List<bool> _sharedEdges(FloorPlan plan, int roomIndex) {
    const int samples = 5;
    final List<bool> result = [];

    for (final Wall wall in plan.rooms[roomIndex].walls) {
      int hits = 0;

      for (int s = 0; s < samples; s++) {
        final Point2D p = wall.pointAtDistance(
          wall.lengthM * (s + 0.5) / samples,
        );

        bool onOther = false;
        for (int o = 0; o < plan.rooms.length && !onOther; o++) {
          if (o == roomIndex) continue;
          for (final Wall other in plan.rooms[o].walls) {
            if (distanceToSegment(p, other.start, other.end) <=
                geometryEpsilonM) {
              onOther = true;
              break;
            }
          }
        }
        if (onOther) hits++;
      }
      result.add(hits >= 3);
    }
    return result;
  }
}
