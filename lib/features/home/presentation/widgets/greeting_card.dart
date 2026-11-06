import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Card de boas-vindas no topo da Home.
class GreetingCard extends StatelessWidget {
  final String userName;

  const GreetingCard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $userName!',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Transforme suas ideias em plantas reais. '
              'Crie, organize e visualize seu espaço.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}