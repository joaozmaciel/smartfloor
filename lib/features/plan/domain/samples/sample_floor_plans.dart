import '../entities/floor_plan.dart';
import '../entities/floor_plan_data.dart';
import '../entities/furniture_item.dart';
import '../entities/plan.dart';
import '../entities/point_2d.dart';

/// Dados de exemplo para testar o desenho técnico.
class SampleFloorPlans {
  SampleFloorPlans._();

  /// Casa de 10 m x 20 m (200 m²). A rua fica embaixo (Y = 20).
  ///
  ///   y= 0 ┌────────┬────────────┐
  ///        │Cozinha │ S. jantar  │   (0 a 5)
  ///   y= 5 ├────────┴──┬─────────┤
  ///        │           │ Banho   │   (5 a 8)
  ///        │ S. estar  ├─────────┤
  ///        │           │ Hall    │   (8 a 11)
  ///   y=11 ├───────────┼─────────┤
  ///        │           │ Banho 2 │   (11 a 14)
  ///        │ Dormitório├─────────┤
  ///        │           │ Closet  │   (14 a 16)
  ///   y=16 ├───────────┴─────────┤
  ///        │       Garagem       │   (16 a 20)
  ///   y=20 └─────────────────────┘
  static FloorPlanData house() {
    final FloorPlan plan = FloorPlan(
      name: 'Casa exemplo',
      rooms: [
        _room('Cozinha', 0, 0, 4, 5),
        _room('Sala de jantar', 4, 0, 6, 5),
        _room('Sala de estar', 0, 5, 6, 6),
        _room('Banho social', 6, 5, 4, 3),
        _room('Hall', 6, 8, 4, 3),
        _room('Dormitório', 0, 11, 6, 5),
        _room('Banho suíte', 6, 11, 4, 3),
        _room('Closet', 6, 14, 4, 2),
        _room('Garagem', 0, 16, 10, 4),
      ],
    );

    return FloorPlanData(
      plan: plan,
      furniture: const [
        // Cozinha
        FurnitureItem(
          type: FurnitureType.counter,
          center: Point2D(2, 0.4),
          widthM: 3.4,
          depthM: 0.6,
        ),
        // Sala de jantar
        FurnitureItem(
          type: FurnitureType.table,
          center: Point2D(7, 2.7),
          widthM: 2.2,
          depthM: 1.0,
        ),
        // Sala de estar
        FurnitureItem(
          type: FurnitureType.sofa,
          center: Point2D(3, 10.2),
          widthM: 2.4,
          depthM: 0.95,
        ),
        // Banho social
        FurnitureItem(
          type: FurnitureType.toilet,
          center: Point2D(9.5, 5.55),
          widthM: 0.4,
          depthM: 0.7,
          rotationDeg: 90,
        ),
        FurnitureItem(
          type: FurnitureType.sink,
          center: Point2D(7.6, 5.35),
          widthM: 0.6,
          depthM: 0.45,
        ),
        // Dormitório
        FurnitureItem(
          type: FurnitureType.bed,
          center: Point2D(3, 13.3),
          widthM: 1.6,
          depthM: 2.0,
        ),
        FurnitureItem(
          type: FurnitureType.wardrobe,
          center: Point2D(0.35, 14.6),
          widthM: 1.8,
          depthM: 0.55,
          rotationDeg: 90,
        ),
        // Banho suíte
        FurnitureItem(
          type: FurnitureType.toilet,
          center: Point2D(9.5, 11.55),
          widthM: 0.4,
          depthM: 0.7,
          rotationDeg: 90,
        ),
        FurnitureItem(
          type: FurnitureType.sink,
          center: Point2D(7.6, 11.35),
          widthM: 0.6,
          depthM: 0.45,
        ),
        // Closet
        FurnitureItem(
          type: FurnitureType.wardrobe,
          center: Point2D(8, 14.3),
          widthM: 3.6,
          depthM: 0.5,
        ),
        // Garagem
        FurnitureItem(
          type: FurnitureType.car,
          center: Point2D(2.6, 18),
          widthM: 4.2,
          depthM: 1.8,
        ),
        FurnitureItem(
          type: FurnitureType.car,
          center: Point2D(7.4, 18),
          widthM: 4.2,
          depthM: 1.8,
        ),
      ],
    );
  }

  /// Cômodo retangular: canto superior esquerdo (x, y) e tamanho (w, h).
  static Plan _room(String name, double x, double y, double w, double h) {
    return Plan(
      name: name,
      vertices: [
        Point2D(x, y),
        Point2D(x + w, y),
        Point2D(x + w, y + h),
        Point2D(x, y + h),
      ],
    );
  }
}
