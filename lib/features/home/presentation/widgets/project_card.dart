import 'package:flutter/material.dart';

import 'dart:typed_data';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/project.dart';

/// Card que mostra um projeto na lista da Home.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Future<Uint8List?>? thumbnail;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onLongPress,
    this.thumbnail,
  });

  /// Formata a área em m² ajustando casas decimais e separador (ex: 68,5 m² ou 54 m²).
  String _formatArea(double area) {
    if (area == area.roundToDouble()) {
      return '${area.toInt()} m²';
    }
    return '${area.toStringAsFixed(1).replaceAll('.', ',')} m²';
  }

  /// Converte DateTime em "dd/MM/aaaa" (sem precisar de pacotes extras).
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniatura provisória (depois será a prévia da planta)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: thumbnail == null
                    ? const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.primary,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder<Uint8List?>(
                          future: thumbnail,
                          builder: (context, snapshot) {
                            final bytes = snapshot.data;
                            if (bytes == null || bytes.isEmpty) {
                              return const Icon(
                                Icons.grid_view_rounded,
                                color: AppColors.primary,
                              );
                            }
                            return Image.memory(
                              bytes,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.grid_view_rounded,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatArea(project.areaM2),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Criado em ${_formatDate(project.createdAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
