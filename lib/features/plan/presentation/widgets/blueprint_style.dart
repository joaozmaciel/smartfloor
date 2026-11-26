import 'package:flutter/material.dart';

/// Parâmetros visuais do desenho técnico.
///
/// Espessuras de parede estão em METROS (convertidas pela escala);
/// o resto está em pixels lógicos (tamanhos de texto, folgas, tracejado).
class BlueprintStyle {
  // ---------- Paredes (metros) ----------
  final double exteriorWallM; // parede externa
  final double interiorWallM; // divisória
  final double minWallPx; // nunca mais fina que isto na tela

  // ---------- Cotas (pixels) ----------
  final double edgePaddingPx; // folga entre a borda da tela e o desenho
  final double dimBaseOffsetPx; // da parede até a 1ª linha de cota
  final double dimTierSpacingPx; // entre uma camada de cota e a seguinte
  final double dimTextBandPx; // espaço reservado para o texto da cota
  final double extGapPx; // folga entre a parede e a linha de chamada
  final double extOverPx; // quanto a linha de chamada passa da cota
  final double tickHalfPx; // metade do tamanho da marca de extremidade
  final double dashPx;
  final double dashGapPx;
  final double dimFontSize;
  final double minDimFontSize;

  // ---------- Textos dos cômodos (pixels) ----------
  final double roomNameFontSize;
  final double roomAreaFontSize;
  final double minFontScale; // até quanto o texto pode encolher (0 a 1)
  final bool uppercaseNames;

  // ---------- Cores ----------
  final Color background;
  final Color wallColor;
  final Color dimColor;
  final Color textColor;
  final Color furnitureColor;
  final List<Color> roomFills;

  const BlueprintStyle({
    this.exteriorWallM = 0.20,
    this.interiorWallM = 0.12,
    this.minWallPx = 3,
    this.edgePaddingPx = 12,
    this.dimBaseOffsetPx = 26,
    this.dimTierSpacingPx = 32,
    this.dimTextBandPx = 16,
    this.extGapPx = 5,
    this.extOverPx = 5,
    this.tickHalfPx = 5,
    this.dashPx = 6,
    this.dashGapPx = 4,
    this.dimFontSize = 11,
    this.minDimFontSize = 8.5,
    this.roomNameFontSize = 12,
    this.roomAreaFontSize = 10.5,
    this.minFontScale = 0.55,
    this.uppercaseNames = true,
    this.background = Colors.white,
    this.wallColor = const Color(0xFF212121),
    this.dimColor = const Color(0xFF455A64),
    this.textColor = const Color(0xFF263238),
    this.furnitureColor = const Color(0xFF757575),
    this.roomFills = const [
      Color(0xFFF1F8E9),
      Color(0xFFFFF8E1),
      Color(0xFFE3F2FD),
      Color(0xFFFCE4EC),
      Color(0xFFF3E5F5),
      Color(0xFFFFFDE7),
      Color(0xFFE0F2F1),
    ],
  });
}
