import 'package:flutter/material.dart';

/// Paleta de cores do SmartFloor.
/// Centralizar as cores aqui evita "números mágicos" espalhados pelo código.
class AppColors {
  AppColors._(); // construtor privado: esta classe só guarda constantes

  /// Verde escuro institucional.
  static const Color primary = Color(0xFF1B5E20);

  /// Verde bem claro, usado como fundo das telas.
  static const Color background = Color(0xFFF1F8F2);

  /// Verde suave para destaques (ex.: card de captura).
  static const Color highlight = Color(0xFFDCEFDD);

  /// Cor dos textos secundários (descrições, datas).
  static const Color textSecondary = Color(0xFF5F6F65);
}