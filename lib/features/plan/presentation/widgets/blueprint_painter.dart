import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/dimension_line.dart';
import '../../domain/entities/furniture_item.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';
import '../../domain/entities/wall.dart';
import '../../domain/services/floor_plan_analyzer.dart';
import '../../domain/services/label_spot_finder.dart';
import 'blueprint_layout.dart';
import 'blueprint_scene.dart';
import 'blueprint_style.dart';

/// Desenha a planta no padrão técnico: cômodos, móveis indicativos, paredes
/// com espessura consistente, cotas externas tracejadas e rótulos.
///
/// Ordem das camadas (de baixo para cima):
/// preenchimento -> móveis -> paredes -> cotas -> nomes e áreas.
class BlueprintPainter extends CustomPainter {
  final BlueprintScene scene;
  final BlueprintStyle style;
  final bool showFurniture;
  final bool showDimensions;

  const BlueprintPainter({
    required this.scene,
    this.style = const BlueprintStyle(),
    this.showFurniture = true,
    this.showDimensions = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = style.background);
    if (!scene.canDraw) return;

    final BlueprintLayout layout = BlueprintLayout.fit(
      canvasSize: size,
      scene: scene,
      style: style,
      withDimensions: showDimensions,
    );

    _drawRoomFills(canvas, layout);
    if (showFurniture) _drawFurniture(canvas, layout);
    _drawWalls(canvas, layout);
    if (showDimensions) _drawDimensions(canvas, layout);
    _drawRoomLabels(canvas, layout);
  }

  // ===========================================================================
  // Cômodos e paredes
  // ===========================================================================

  void _drawRoomFills(Canvas canvas, BlueprintLayout layout) {
    final List<Plan> rooms = scene.data.rooms;

    for (int r = 0; r < rooms.length; r++) {
      final Path path = Path()
        ..addPolygon(rooms[r].vertices.map(layout.toCanvas).toList(), true);
      canvas.drawPath(
        path,
        Paint()..color = style.roomFills[r % style.roomFills.length],
      );
    }
  }

  /// Largura da parede em pixels: a espessura REAL (em metros) vezes a escala,
  /// com um mínimo para a parede nunca sumir quando o desenho está pequeno.
  double _wallPx(bool shared, BlueprintLayout layout) {
    final double meters = shared ? style.interiorWallM : style.exteriorWallM;
    return math.max(style.minWallPx, layout.lengthToPx(meters));
  }

  void _drawWalls(Canvas canvas, BlueprintLayout layout) {
    final List<Plan> rooms = scene.data.rooms;

    // Divisórias primeiro e paredes externas depois (mais grossas, por cima),
    // para os encontros de parede ficarem limpos.
    for (final bool drawShared in [true, false]) {
      for (int r = 0; r < rooms.length; r++) {
        final List<Wall> walls = rooms[r].walls;

        for (int w = 0; w < walls.length; w++) {
          if (scene.sharedEdges[r][w] != drawShared) continue;

          canvas.drawLine(
            layout.toCanvas(walls[w].start),
            layout.toCanvas(walls[w].end),
            Paint()
              ..color = style.wallColor
              ..strokeWidth = _wallPx(drawShared, layout)
              // "square" estende a ponta em meia espessura: os cantos se fecham.
              ..strokeCap = StrokeCap.square,
          );
        }
      }
    }
  }

  // ===========================================================================
  // Cotas externas
  // ===========================================================================

  void _drawDimensions(Canvas canvas, BlueprintLayout layout) {
    final Paint dashPaint = Paint()
      ..color = style.dimColor
      ..strokeWidth = 1;
    final Paint extensionPaint = Paint()
      ..color = style.dimColor
      ..strokeWidth = 0.8;
    final Paint tickPaint = Paint()
      ..color = style.dimColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Metade da parede externa: a linha de chamada nasce na face de FORA.
    final double wallHalfPx = _wallPx(false, layout) / 2;

    // Conta os trechos de cada (lado, camada) para alternar os textos curtos.
    final Map<String, int> counters = {};

    for (final DimensionLine d in scene.dimensions) {
      final String key = '${d.side.name}-${d.tier}';
      final int index = counters[key] = (counters[key] ?? -1) + 1;

      // Extremos da cota sobre o contorno e direção "para fora".
      final Offset a, b, outward;
      switch (d.side) {
        case DimensionSide.top:
          a = layout.toCanvas(Point2D(d.from, d.edgeCoord));
          b = layout.toCanvas(Point2D(d.to, d.edgeCoord));
          outward = const Offset(0, -1);
        case DimensionSide.bottom:
          a = layout.toCanvas(Point2D(d.from, d.edgeCoord));
          b = layout.toCanvas(Point2D(d.to, d.edgeCoord));
          outward = const Offset(0, 1);
        case DimensionSide.left:
          a = layout.toCanvas(Point2D(d.edgeCoord, d.from));
          b = layout.toCanvas(Point2D(d.edgeCoord, d.to));
          outward = const Offset(-1, 0);
        case DimensionSide.right:
          a = layout.toCanvas(Point2D(d.edgeCoord, d.from));
          b = layout.toCanvas(Point2D(d.edgeCoord, d.to));
          outward = const Offset(1, 0);
      }

      // Linha de cota: deslocada para fora conforme a camada.
      final double offset =
          style.dimBaseOffsetPx + d.tier * style.dimTierSpacingPx;
      final Offset da = a + outward * offset;
      final Offset db = b + outward * offset;

      // Linhas de chamada: da parede até um pouco depois da linha de cota.
      for (final List<Offset> pair in [
        [a, da],
        [b, db],
      ]) {
        canvas.drawLine(
          pair[0] + outward * (wallHalfPx + style.extGapPx),
          pair[1] + outward * style.extOverPx,
          extensionPaint,
        );
      }

      // Linha de cota tracejada.
      _drawDashedLine(canvas, da, db, dashPaint);

      // Marcas de extremidade (traço a 45°, como no desenho arquitetônico).
      final Offset along = (db - da) / math.max((db - da).distance, 0.001);
      final Offset across = Offset(-along.dy, along.dx);
      final Offset tick = (along + across) * (style.tickHalfPx / math.sqrt2);
      for (final Offset end in [da, db]) {
        canvas.drawLine(end - tick, end + tick, tickPaint);
      }

      // Texto da cota, do lado de fora da linha.
      _drawDimensionText(canvas, d, da, db, outward, index);
    }
  }

  void _drawDimensionText(
    Canvas canvas,
    DimensionLine d,
    Offset da,
    Offset db,
    Offset outward,
    int index,
  ) {
    final String label = formatMetersCompact(d.lengthM);
    final FontWeight weight = d.isOverall ? FontWeight.w700 : FontWeight.w500;
    final double available = (db - da).distance;

    // Encolhe a fonte até o texto caber entre as marcas.
    TextPainter text = _text(label, style.dimFontSize, weight, style.textColor);
    double size = style.dimFontSize;
    while (text.width + 8 > available && size > style.minDimFontSize) {
      size -= 0.5;
      text = _text(label, size, weight, style.textColor);
    }

    // Ainda não coube? Alterna os textos curtos entre duas alturas para
    // não se sobreporem ao do trecho vizinho.
    final bool stagger = text.width + 8 > available && index.isOdd;
    final double shift = stagger ? text.height + 1 : 0;

    // O texto fica do lado de fora da linha (afastado pela metade da sua altura).
    final Offset position =
        (da + db) / 2 + outward * (text.height / 2 + 3 + shift);

    // Cotas verticais giram o texto para ele ler de baixo para cima.
    _paintTextAt(
      canvas,
      text,
      position,
      rotation: d.isHorizontal ? 0 : -math.pi / 2,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final double length = (b - a).distance;
    if (length == 0) return;

    final Offset direction = (b - a) / length;
    double traveled = 0;
    while (traveled < length) {
      final double end = math.min(traveled + style.dashPx, length);
      canvas.drawLine(a + direction * traveled, a + direction * end, paint);
      traveled += style.dashPx + style.dashGapPx;
    }
  }

  // ===========================================================================
  // Nome e área dos cômodos
  // ===========================================================================

  void _drawRoomLabels(Canvas canvas, BlueprintLayout layout) {
    final List<Plan> rooms = scene.data.rooms;

    for (int r = 0; r < rooms.length; r++) {
      final LabelSpot spot = scene.labelSpots[r];
      final RoomMetrics metrics = scene.report.rooms[r];

      final String name = style.uppercaseNames
          ? rooms[r].name.toUpperCase()
          : rooms[r].name;
      // Usa a área ARREDONDADA: o que está escrito é o que entra na soma total.
      final String area = '${formatDecimal(metrics.roundedAreaM2)} m²';

      final Offset center = layout.toCanvas(spot.center);
      final double maxWidth = 2 * layout.lengthToPx(spot.halfWidthM) * 0.92;
      final double maxHeight = 2 * layout.lengthToPx(spot.halfHeightM) * 0.92;

      _drawFittedLabel(canvas, name, area, center, maxWidth, maxHeight);
    }
  }

  /// Escreve o rótulo reduzindo a fonte (e quebrando o nome em até 2 linhas)
  /// até ele caber no espaço livre. Se mesmo no tamanho mínimo não couber,
  /// desenha com um fundo claro para continuar legível.
  void _drawFittedLabel(
    Canvas canvas,
    String name,
    String area,
    Offset center,
    double maxWidth,
    double maxHeight,
  ) {
    TextPainter? namePainter;
    TextPainter? areaPainter;
    bool fits = false;

    for (double f = 1.0; f >= style.minFontScale - 0.001; f -= 0.1) {
      namePainter = _text(
        name,
        style.roomNameFontSize * f,
        FontWeight.w700,
        style.textColor,
        maxLines: 2,
        maxWidth: maxWidth,
      );
      areaPainter = _text(
        area,
        style.roomAreaFontSize * f,
        FontWeight.w500,
        style.textColor,
        maxLines: 1,
        maxWidth: maxWidth,
      );

      final double totalHeight = namePainter.height + areaPainter.height + 1;
      fits =
          !namePainter.didExceedMaxLines &&
          !areaPainter.didExceedMaxLines &&
          totalHeight <= maxHeight;
      if (fits) break;
    }

    final TextPainter nameText = namePainter!;
    final TextPainter areaText = areaPainter!;
    final double blockHeight = nameText.height + areaText.height + 1;
    final double blockWidth = math.max(nameText.width, areaText.width);

    if (!fits) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: blockWidth + 6,
            height: blockHeight + 4,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xE6FFFFFF),
      );
    }

    final double top = center.dy - blockHeight / 2;
    nameText.paint(canvas, Offset(center.dx - nameText.width / 2, top));
    areaText.paint(
      canvas,
      Offset(center.dx - areaText.width / 2, top + nameText.height + 1),
    );
  }

  // ===========================================================================
  // Móveis indicativos
  // ===========================================================================

  void _drawFurniture(Canvas canvas, BlueprintLayout layout) {
    for (final FurnitureItem item in scene.data.furniture) {
      _drawFurnitureItem(canvas, layout, item);
    }
  }

  void _drawFurnitureItem(
    Canvas canvas,
    BlueprintLayout layout,
    FurnitureItem item,
  ) {
    final Offset center = layout.toCanvas(item.center);
    final double w = layout.lengthToPx(item.widthM);
    final double d = layout.lengthToPx(item.depthM);

    final Paint line = Paint()
      ..color = style.furnitureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Paint fill = Paint()..color = Colors.white;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(item.rotationDeg * math.pi / 180);

    final Rect r = Rect.fromCenter(center: Offset.zero, width: w, height: d);
    final RRect body = RRect.fromRectAndRadius(
      r,
      Radius.circular(math.min(w, d) * 0.08),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, line);

    switch (item.type) {
      case FurnitureType.bed:
        // Dois travesseiros e a dobra do cobertor.
        for (final double x in [0.08, 0.54]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                r.left + w * x,
                r.top + d * 0.05,
                w * 0.38,
                d * 0.2,
              ),
              const Radius.circular(3),
            ),
            line,
          );
        }
        canvas.drawLine(
          Offset(r.left, r.top + d * 0.35),
          Offset(r.right, r.top + d * 0.35),
          line,
        );
      case FurnitureType.sofa:
        // Encosto e braços.
        canvas.drawLine(
          Offset(r.left, r.top + d * 0.28),
          Offset(r.right, r.top + d * 0.28),
          line,
        );
        for (final double x in [r.left + w * 0.08, r.right - w * 0.08]) {
          canvas.drawLine(
            Offset(x, r.top + d * 0.28),
            Offset(x, r.bottom),
            line,
          );
        }
      case FurnitureType.table:
        // Cadeiras nos dois lados maiores.
        final double chair = math.min(w, d) * 0.3;
        for (final double x in [-w * 0.22, w * 0.22]) {
          for (final double side in [-1, 1]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(x, side * (d / 2 + chair * 0.45)),
                  width: chair * 1.1,
                  height: chair * 0.9,
                ),
                const Radius.circular(2),
              ),
              line,
            );
          }
        }
      case FurnitureType.counter:
        // Pia e quatro bocas do fogão.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(r.left + w * 0.3, 0),
              width: w * 0.22,
              height: d * 0.55,
            ),
            const Radius.circular(2),
          ),
          line,
        );
        for (final double x in [0.30, 0.14]) {
          for (final double y in [-0.2, 0.2]) {
            canvas.drawCircle(Offset(r.right - w * x, d * y), d * 0.1, line);
          }
        }
      case FurnitureType.toilet:
        // Caixa acoplada e bacia.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              r.left + w * 0.1,
              r.top + d * 0.03,
              w * 0.8,
              d * 0.28,
            ),
            const Radius.circular(2),
          ),
          line,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, d * 0.18),
            width: w * 0.72,
            height: d * 0.6,
          ),
          line,
        );
      case FurnitureType.sink:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w * 0.7, height: d * 0.6),
          line,
        );
      case FurnitureType.wardrobe:
        canvas.drawLine(r.topLeft, r.bottomRight, line);
        canvas.drawLine(r.topRight, r.bottomLeft, line);
      case FurnitureType.desk:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, d / 2 + d * 0.45),
              width: w * 0.35,
              height: d * 0.6,
            ),
            const Radius.circular(2),
          ),
          line,
        );
      case FurnitureType.car:
        // Cabine e para-brisas.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              r.left + w * 0.28,
              r.top + d * 0.12,
              r.left + w * 0.72,
              r.bottom - d * 0.12,
            ),
            Radius.circular(d * 0.15),
          ),
          line,
        );
    }

    canvas.restore();
  }

  // ===========================================================================
  // Texto
  // ===========================================================================

  TextPainter _text(
    String text,
    double fontSize,
    FontWeight weight,
    Color color, {
    int? maxLines,
    double? maxWidth,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth ?? double.infinity);
  }

  /// Desenha um texto centrado em [center], opcionalmente girado.
  void _paintTextAt(
    Canvas canvas,
    TextPainter text,
    Offset center, {
    double rotation = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (rotation != 0) canvas.rotate(rotation);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BlueprintPainter oldDelegate) {
    return oldDelegate.scene != scene ||
        oldDelegate.style != style ||
        oldDelegate.showFurniture != showFurniture ||
        oldDelegate.showDimensions != showDimensions;
  }
}
