import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

/// Widget raiz do app: configura tema e define a primeira tela.
class SmartFloorApp extends StatelessWidget {
  const SmartFloorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFloor',
      debugShowCheckedModeBanner: false, // remove a faixa "DEBUG"
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}