import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/floor_plan_data.dart';
import '../../domain/services/floor_plan_analyzer.dart';
import '../widgets/blueprint_painter.dart';
import '../widgets/blueprint_scene.dart';

/// Mostra o desenho técnico com zoom e o resumo de áreas já validado.
class BlueprintPreviewPage extends StatefulWidget {
  final FloorPlanData data;
  final String title;

  const BlueprintPreviewPage({
    super.key,
    required this.data,
    this.title = 'Desenho técnico',
  });

  @override
  State<BlueprintPreviewPage> createState() => _BlueprintPreviewPageState();
}

class _BlueprintPreviewPageState extends State<BlueprintPreviewPage> {
  /// A cena (validação, cotas, pontos dos rótulos) é calculada UMA vez.
  late final BlueprintScene _scene = BlueprintScene.build(widget.data);

  bool _showFurniture = true;
  bool _showDimensions = true;

  @override
  Widget build(BuildContext context) {
    final FloorPlanReport report = _scene.report;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFurniture ? Icons.chair : Icons.chair_outlined),
            tooltip: 'Móveis',
            onPressed: () => setState(() => _showFurniture = !_showFurniture),
          ),
          IconButton(
            icon: Icon(
              _showDimensions ? Icons.straighten : Icons.straighten_outlined,
            ),
            tooltip: 'Cotas',
            onPressed: () => setState(() => _showDimensions = !_showDimensions),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: ColoredBox(
              color: Colors.white,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 6,
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: BlueprintPainter(
                      scene: _scene,
                      showFurniture: _showFurniture,
                      showDimensions: _showDimensions,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTotalCard(report),
                const SizedBox(height: 12),
                _buildRoomsCard(report),
                if (report.issues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final PlanIssue issue in report.issues)
                    _buildIssue(issue),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(FloorPlanReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Área construída: ${formatDecimal(report.builtAreaRoundedM2)} m²',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            if (_scene.canDraw)
              Text(
                'Retângulo envolvente: '
                '${formatDecimal(_scene.width)} x ${formatDecimal(_scene.height)} m '
                '(${formatDecimal(report.boundingAreaM2)} m²) • '
                'ocupação ${formatDecimal(report.fillRatio * 100)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsCard(FloorPlanReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final RoomMetrics room in report.rooms)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(room.name)),
                    Text('${formatDecimal(room.roundedAreaM2)} m²'),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total (soma dos cômodos)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${formatDecimal(report.builtAreaRoundedM2)} m²',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssue(PlanIssue issue) {
    final bool isError = issue.severity == PlanIssueSeverity.error;
    final Color color = isError
        ? const Color(0xFFC62828)
        : const Color(0xFFE65100);

    return Card(
      color: isError ? const Color(0xFFFDECEA) : const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.warning_amber_rounded,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(issue.message)),
          ],
        ),
      ),
    );
  }
}
