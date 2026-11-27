import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/dimension_line.dart';
import '../../domain/entities/point_2d.dart';
import 'blueprint_scene.dart';
import 'blueprint_style.dart';

/// Escala e deslocamento do desenho. É o ÚNICO lugar que converte
/// metros em pixels: o painter nunca faz essa conta por conta própria.
class BlueprintLayout {
  /// Pixels por metro.
  final double scale;

  /// Posição em pixels do ponto (0 m, 0 m).
  final Offset origin;

  const BlueprintLayout({required this.scale, required this.origin});

  Offset toCanvas(Point2D p) {
    return Offset(origin.dx + p.x * scale, origin.dy + p.y * scale);
  }

  double lengthToPx(double meters) => meters * scale;

  /// Calcula a escala RESERVANDO, em cada lado, o espaço das cotas externas.
  /// Só depois de reservar as margens é que o desenho recebe o espaço que sobra.
  factory BlueprintLayout.fit({
    required Size canvasSize,
    required BlueprintScene scene,
    required BlueprintStyle style,
    required bool withDimensions,
  }) {
    double margin(DimensionSide side) {
      final int tiers = withDimensions ? (scene.tiersPerSide[side] ?? 0) : 0;
      final double band = tiers == 0
          ? 0
          : style.dimBaseOffsetPx +
                (tiers - 1) * style.dimTierSpacingPx +
                style.dimTextBandPx;
      return style.edgePaddingPx + band;
    }

    final double left = margin(DimensionSide.left);
    final double right = margin(DimensionSide.right);
    final double top = margin(DimensionSide.top);
    final double bottom = margin(DimensionSide.bottom);

    // As paredes externas sobram meia espessura para fora do contorno.
    final double overhang = style.exteriorWallM / 2;
    final double planWidth = scene.width + 2 * overhang;
    final double planHeight = scene.height + 2 * overhang;

    final double availableWidth = math.max(1, canvasSize.width - left - right);
    final double availableHeight = math.max(
      1,
      canvasSize.height - top - bottom,
    );

    final double scale = math.min(
      availableWidth / planWidth,
      availableHeight / planHeight,
    );

    // Centraliza o desenho na área que sobrou.
    final double originX =
        left +
        (availableWidth - planWidth * scale) / 2 +
        overhang * scale -
        scene.minX * scale;
    final double originY =
        top +
        (availableHeight - planHeight * scale) / 2 +
        overhang * scale -
        scene.minY * scale;

    return BlueprintLayout(scale: scale, origin: Offset(originX, originY));
  }
}
