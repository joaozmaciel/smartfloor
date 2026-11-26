import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/core/utils/formatters.dart';
import 'package:smartfloor/features/plan/domain/entities/dimension_line.dart';
import 'package:smartfloor/features/plan/domain/entities/floor_plan.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/plan/domain/entities/point_2d.dart';
import 'package:smartfloor/features/plan/domain/samples/sample_floor_plans.dart';
import 'package:smartfloor/features/plan/domain/services/dimension_builder.dart';
import 'package:smartfloor/features/plan/domain/services/floor_plan_analyzer.dart';
import 'package:smartfloor/features/plan/domain/services/label_spot_finder.dart';

Plan rect(String name, double x, double y, double w, double h) => Plan(
  name: name,
  vertices: [
    Point2D(x, y),
    Point2D(x + w, y),
    Point2D(x + w, y + h),
    Point2D(x, y + h),
  ],
);

/// Comprimentos das cotas de um lado e camada, em ordem.
List<double> lengths(List<DimensionLine> all, DimensionSide side, int tier) {
  return all
      .where((d) => d.side == side && d.tier == tier)
      .map((d) => d.lengthM)
      .toList();
}

void main() {
  final sample = SampleFloorPlans.house();

  group('formatMetersCompact', () {
    test('formata como no desenho técnico', () {
      expect(formatMetersCompact(20), '20 m');
      expect(formatMetersCompact(3.5), '3,5 m');
      expect(formatMetersCompact(3.25), '3,25 m');
      expect(formatMetersCompact(10.004), '10 m');
    });
  });

  group('FloorPlanAnalyzer', () {
    test('a casa de exemplo é válida e soma 200 m²', () {
      final report = const FloorPlanAnalyzer().analyze(sample.plan);

      expect(report.issues, isEmpty);
      expect(report.rooms.length, 9);
      expect(report.builtAreaM2, closeTo(200, 1e-9));
      expect(report.builtAreaRoundedM2, 200);
      expect(report.boundingAreaM2, closeTo(200, 1e-9));
      expect(report.fillRatio, closeTo(1, 1e-9));
    });

    test('o total exibido é a soma dos valores arredondados mostrados', () {
      // Cada cômodo tem 10,004 m²: aparece "10,00" três vezes.
      final plan = FloorPlan(
        name: 'T',
        rooms: [
          rect('A', 0, 0, 10.004, 1),
          rect('B', 11, 0, 10.004, 1),
          rect('C', 22, 0, 10.004, 1),
        ],
      );
      final report = const FloorPlanAnalyzer().analyze(plan);

      expect(report.builtAreaM2, closeTo(30.012, 1e-9));
      expect(report.builtAreaRoundedM2, 30); // 10 + 10 + 10, como nos rótulos
    });

    test('cômodos que só dividem uma parede NÃO se sobrepõem', () {
      final plan = FloorPlan(
        name: 'T',
        rooms: [rect('A', 0, 0, 4, 4), rect('B', 4, 0, 4, 4)],
      );

      expect(const FloorPlanAnalyzer().analyze(plan).hasErrors, isFalse);
    });

    test('detecta cômodos sobrepostos', () {
      final plan = FloorPlan(
        name: 'T',
        rooms: [rect('A', 0, 0, 4, 4), rect('B', 2, 2, 4, 4)],
      );

      expect(const FloorPlanAnalyzer().analyze(plan).hasErrors, isTrue);
    });

    test('detecta um cômodo inteiro dentro de outro', () {
      final plan = FloorPlan(
        name: 'T',
        rooms: [rect('Grande', 0, 0, 10, 10), rect('Pequeno', 2, 2, 2, 2)],
      );

      expect(const FloorPlanAnalyzer().analyze(plan).hasErrors, isTrue);
    });

    test('detecta paredes que se cruzam (gravata-borboleta)', () {
      final plan = FloorPlan(
        name: 'T',
        rooms: [
          Plan(
            name: 'Torto',
            vertices: [
              Point2D(0, 0),
              Point2D(4, 4),
              Point2D(4, 0),
              Point2D(0, 4),
            ],
          ),
        ],
      );

      expect(const FloorPlanAnalyzer().analyze(plan).hasErrors, isTrue);
    });

    test('avisa quando um cômodo passa do terreno', () {
      final plan = FloorPlan(
        name: 'T',
        lot: rect('Terreno', 0, 0, 10, 10),
        rooms: [rect('Sala', 8, 8, 4, 4)],
      );
      final report = const FloorPlanAnalyzer().analyze(plan);

      expect(report.issues.length, 1);
      expect(report.issues.first.severity, PlanIssueSeverity.warning);
    });
  });

  group('DimensionBuilder (casa de exemplo)', () {
    final dims = const DimensionBuilder().build(sample.plan);

    test('topo: trechos 4 + 6 e total 10', () {
      expect(lengths(dims, DimensionSide.top, 0), [4, 6]);
      expect(lengths(dims, DimensionSide.top, 1), [10]);
    });

    test('esquerda: trechos 5 + 6 + 5 + 4 e total 20', () {
      expect(lengths(dims, DimensionSide.left, 0), [5, 6, 5, 4]);
      expect(lengths(dims, DimensionSide.left, 1), [20]);
    });

    test('direita: trechos 5 + 3 + 3 + 3 + 2 + 4 e total 20', () {
      expect(lengths(dims, DimensionSide.right, 0), [5, 3, 3, 3, 2, 4]);
      expect(lengths(dims, DimensionSide.right, 1), [20]);
    });

    test('base: sem divisões, só a cota total, já na camada 0', () {
      expect(lengths(dims, DimensionSide.bottom, 0), [10]);
      expect(lengths(dims, DimensionSide.bottom, 1), isEmpty);
    });

    test('a soma dos trechos de cada lado fecha com a cota total', () {
      for (final side in [
        DimensionSide.top,
        DimensionSide.left,
        DimensionSide.right,
      ]) {
        final sum = lengths(dims, side, 0).fold(0.0, (a, b) => a + b);
        final total = lengths(dims, side, 1).first;
        expect(sum, closeTo(total, 1e-9));
      }
    });
  });

  group('LabelSpotFinder', () {
    test('o ponto do rótulo fica dentro do cômodo e com folga', () {
      for (final room in sample.plan.rooms) {
        final spot = const LabelSpotFinder().find(room);

        expect(room.containsPoint(spot.center), isTrue, reason: room.name);
        expect(spot.halfWidthM, greaterThan(0), reason: room.name);
        expect(spot.halfHeightM, greaterThan(0), reason: room.name);
      }
    });

    test('em um cômodo em L o rótulo não cai fora dele', () {
      final l = Plan(
        name: 'L',
        vertices: [
          Point2D(0, 0),
          Point2D(6, 0),
          Point2D(6, 2),
          Point2D(2, 2),
          Point2D(2, 6),
          Point2D(0, 6),
        ],
      );
      final spot = const LabelSpotFinder().find(l);

      expect(l.containsPoint(spot.center), isTrue);
    });
  });
}
