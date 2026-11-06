import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Card de atalho para iniciar a captura de um novo ambiente.
class CaptureShortcutCard extends StatelessWidget {
  /// Função chamada quando o usuário toca no card.
  final VoidCallback onTap;

  const CaptureShortcutCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.highlight,
      clipBehavior: Clip.antiAlias, // faz o efeito de toque respeitar as bordas
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone dentro de um quadrado branco
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Expanded: o texto ocupa o espaço que sobrar na linha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capturar novo ambiente',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tire uma foto, use o AR ou importe.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}