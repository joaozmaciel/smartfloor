import 'floor_plan.dart';
import 'furniture_item.dart';
import 'plan.dart';

/// Um cômodo é um polígono com nome: o próprio `Plan`.
/// O apelido existe só para o código ficar mais legível onde se fala de cômodos.
typedef RoomItem = Plan;

/// Tudo o que o desenho técnico precisa: a planta (cômodos) e os móveis.
class FloorPlanData {
  final FloorPlan plan;
  final List<FurnitureItem> furniture;

  const FloorPlanData({required this.plan, this.furniture = const []});

  List<RoomItem> get rooms => plan.rooms;

  FloorPlanData copyWith({FloorPlan? plan, List<FurnitureItem>? furniture}) {
    return FloorPlanData(
      plan: plan ?? this.plan,
      furniture: furniture ?? this.furniture,
    );
  }
}
