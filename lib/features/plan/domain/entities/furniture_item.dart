import 'dart:math' as math;

import 'box_m.dart';
import 'point_2d.dart';

/// Tipos de móveis indicativos (só símbolos simples, não são modelos 3D).
enum FurnitureType {
  bed,
  sofa,
  table,
  counter,
  toilet,
  sink,
  wardrobe,
  desk,
  car,
}

/// Um móvel posicionado na planta, em METROS.
class FurnitureItem {
  final FurnitureType type;
  final Point2D center;
  final double widthM;
  final double depthM;

  /// Rotação em graus, no sentido horário (a tela tem o eixo Y para baixo).
  final double rotationDeg;

  const FurnitureItem({
    required this.type,
    required this.center,
    required this.widthM,
    required this.depthM,
    this.rotationDeg = 0,
  });

  /// Menor caixa (alinhada aos eixos) que contém o móvel já rotacionado.
  BoxM get bounds {
    final double radians = rotationDeg * math.pi / 180;
    final double c = math.cos(radians).abs();
    final double s = math.sin(radians).abs();
    final double halfW = (widthM * c + depthM * s) / 2;
    final double halfH = (widthM * s + depthM * c) / 2;

    return BoxM(
      minX: center.x - halfW,
      minY: center.y - halfH,
      maxX: center.x + halfW,
      maxY: center.y + halfH,
    );
  }
}
