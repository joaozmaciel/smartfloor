import 'dart:math' as math;

import '../entities/box_m.dart';
import '../entities/plan.dart';
import '../entities/point_2d.dart';
import '../entities/wall.dart';
import 'geometry.dart';

/// Onde escrever o nome do cômodo e quanto espaço livre existe ali (em metros).
class LabelSpot {
  final Point2D center;
  final double halfWidthM; // folga para a esquerda/direita do centro
  final double halfHeightM; // folga para cima/baixo do centro

  const LabelSpot({
    required this.center,
    required this.halfWidthM,
    required this.halfHeightM,
  });
}

/// Acha, dentro do cômodo, o ponto com mais folga para um texto largo,
/// longe das paredes e (se possível) dos móveis.
///
/// Procura numa grade: testa cada ponto, mede a folga para os 4 lados com
/// "raios" até as paredes e fica com o melhor. Um texto é bem mais largo
/// que alto, então a pontuação favorece folga horizontal.
class LabelSpotFinder {
  final int gridSteps;

  const LabelSpotFinder({this.gridSteps = 24});

  LabelSpot find(Plan room, {List<BoxM> avoid = const []}) {
    LabelSpot? spot = _search(room, avoid);
    // Se os móveis ocupam tudo, aceita sobrepor em vez de ficar sem rótulo.
    if (spot == null && avoid.isNotEmpty) spot = _search(room, const []);

    return spot ??
        LabelSpot(center: room.centroid, halfWidthM: 0.5, halfHeightM: 0.5);
  }

  LabelSpot? _search(Plan room, List<BoxM> avoid) {
    final double width = room.boundingWidthM;
    final double height = room.boundingHeightM;

    LabelSpot? best;
    double bestScore = -1;

    for (int i = 0; i < gridSteps; i++) {
      for (int j = 0; j < gridSteps; j++) {
        final Point2D p = Point2D(
          room.minX + (i + 0.5) / gridSteps * width,
          room.minY + (j + 0.5) / gridSteps * height,
        );

        if (!room.containsPoint(p)) continue;
        // Margem de 40 cm em volta dos móveis (o texto ocupa mais que um ponto).
        if (avoid.any((box) => box.contains(p, margin: 0.4))) continue;

        final double halfWidth = math.min(
          _free(room, p, 1, 0),
          _free(room, p, -1, 0),
        );
        final double halfHeight = math.min(
          _free(room, p, 0, 1),
          _free(room, p, 0, -1),
        );

        final double score = math.min(halfWidth, halfHeight * 2.5);
        if (score > bestScore) {
          bestScore = score;
          best = LabelSpot(
            center: p,
            halfWidthM: halfWidth,
            halfHeightM: halfHeight,
          );
        }
      }
    }
    return best;
  }

  /// Distância livre de [p] até a parede mais próxima na direção (dx, dy).
  double _free(Plan room, Point2D p, double dx, double dy) {
    double nearest = double.infinity;
    for (final Wall wall in room.walls) {
      final double? t = rayDistance(p, dx, dy, wall.start, wall.end);
      if (t != null && t < nearest) nearest = t;
    }
    return nearest.isFinite ? nearest : 0;
  }
}
