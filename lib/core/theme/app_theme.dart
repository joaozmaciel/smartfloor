import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema global do app (Material 3).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    // O Material 3 gera uma paleta completa a partir de uma cor "semente".
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // Barra superior
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // Cards brancos com cantos arredondados
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Botão flutuante (+)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      // Barra de navegação inferior
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.highlight,
      ),
    );
  }
}