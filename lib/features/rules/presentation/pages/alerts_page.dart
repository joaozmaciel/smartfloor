import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../plan/domain/entities/plan.dart';
import '../../../plan/domain/entities/floor_plan.dart';
import '../../domain/entities/building_alert.dart';
import '../../domain/entities/rule_settings.dart';
import '../../domain/entities/site.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/entities/analysis_input.dart';
import '../../domain/services/building_rule_checker.dart';
import '../../domain/services/suggestion_engine.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../widgets/site_painter.dart';

/// Resultado da análise: desenho do terreno, alertas e sugestões.
/// É Stateful porque o terreno (posição da construção) pode mudar
/// quando o usuário aplica uma sugestão.
class AlertsPage extends StatefulWidget {
  final Plan plan;
  final FloorPlan? floorPlan;
  final Site site; // terreno original, usado em "Restaurar"
  final RuleSettings settings;
  final ValueChanged<AnalysisInput>? onAnalysisChanged;

  const AlertsPage({
    super.key,
    required this.plan,
    this.floorPlan,
    required this.site,
    required this.settings,
    this.onAnalysisChanged,
  });

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Site _site; // terreno atual (muda ao aplicar sugestões)

  @override
  void initState() {
    super.initState();
    _site = widget.site;
  }

  void _applySuggestion(Suggestion suggestion) {
    final Site? adjusted = suggestion.adjustedSite;
    if (adjusted == null) return;

    setState(() => _site = adjusted);
    widget.onAnalysisChanged?.call(
      AnalysisInput(site: adjusted, settings: widget.settings),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sugestão aplicada!')));
  }

  void _restore() {
    setState(() => _site = widget.site);
    widget.onAnalysisChanged?.call(
      AnalysisInput(site: widget.site, settings: widget.settings),
    );
  }

  /// Abre o relatório em PDF com a posição atual da construção.
  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportPage(
          plan: widget.plan,
          floorPlan: widget.floorPlan,
          site: _site,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Toda vez que _site muda, a tela é reconstruída e as regras rodam de novo.
    final List<BuildingAlert> alerts = const BuildingRuleChecker().check(
      plan: widget.plan,
      site: _site,
      settings: widget.settings,
      occupiedAreaM2: widget.floorPlan?.builtAreaM2,
    );
    final List<Suggestion> suggestions = const SuggestionEngine().suggest(
      plan: widget.plan,
      site: _site,
      settings: widget.settings,
      occupiedAreaM2: widget.floorPlan?.builtAreaM2,
    );

    final int attention = alerts
        .where((a) => a.severity != AlertSeverity.info)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resultado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Voltar à posição original',
            onPressed: _restore,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Desenho do terreno
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: CustomPaint(
                painter: SitePainter(plan: widget.plan, site: _site),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.floorPlan == null ? '' : 'A ocupação usa a soma das áreas dos cômodos; recuos aproximados pelo retângulo envolvente. '}'
            'Distâncias da construção até cada divisa. Laranja: menos de '
            '1,50 m de um vizinho. Vermelho: fora do terreno.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // ---------- Alertas ----------
          Text(
            attention == 0
                ? 'Nenhum ponto de atenção'
                : '$attention ponto(s) de atenção',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final BuildingAlert alert in alerts) ...[
            _AlertCard(alert: alert),
            const SizedBox(height: 12),
          ],

          // ---------- Sugestões ----------
          const SizedBox(height: 8),
          Text(
            'Sugestões',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            Text(
              'Nenhuma sugestão: a configuração atual respeita as regras '
              'verificadas.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            for (final Suggestion suggestion in suggestions) ...[
              _SuggestionCard(
                suggestion: suggestion,
                onApply: () => _applySuggestion(suggestion),
              ),
              const SizedBox(height: 12),
            ],

          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _openReport,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Gerar relatório em PDF'),
          ),
          const SizedBox(height: 16),

          // ---------- Aviso importante ----------
          const SizedBox(height: 8),
          const Card(
            color: AppColors.highlight,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verificação preliminar. Não substitui a análise de um '
                      'profissional habilitado nem a consulta à legislação e '
                      'à prefeitura do seu município.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

/// Cores e ícone de cada gravidade.
class _SeverityStyle {
  final Color color;
  final Color background;
  final IconData icon;

  const _SeverityStyle(this.color, this.background, this.icon);
}

_SeverityStyle _styleFor(AlertSeverity severity) {
  return switch (severity) {
    AlertSeverity.error => const _SeverityStyle(
      Color(0xFFC62828),
      Color(0xFFFDECEA),
      Icons.error_outline,
    ),
    AlertSeverity.warning => const _SeverityStyle(
      Color(0xFFE65100),
      Color(0xFFFFF3E0),
      Icons.warning_amber_rounded,
    ),
    AlertSeverity.info => const _SeverityStyle(
      AppColors.primary,
      Colors.white,
      Icons.check_circle_outline,
    ),
  };
}

/// Card de um alerta.
class _AlertCard extends StatelessWidget {
  final BuildingAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final _SeverityStyle style = _styleFor(alert.severity);

    return Card(
      color: style.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(style.icon, color: style.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: style.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.message, style: textTheme.bodyMedium),
                  if (alert.reference != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      alert.reference!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de uma sugestão, com botão "Aplicar" quando possível.
class _SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onApply;

  const _SuggestionCard({required this.suggestion, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(suggestion.message, style: textTheme.bodyMedium),
                  if (suggestion.canApply) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: onApply,
                      child: const Text('Aplicar sugestão'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
