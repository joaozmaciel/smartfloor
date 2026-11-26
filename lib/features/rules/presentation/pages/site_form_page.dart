import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../plan/domain/entities/floor_plan.dart';
import '../../../plan/domain/entities/plan.dart';
import '../../domain/entities/floor_plan_site_analysis.dart';
import '../../domain/entities/rule_settings.dart';
import '../../domain/entities/site.dart';
import '../../domain/entities/analysis_input.dart';
import 'alerts_page.dart';

/// Formulário do terreno e dos parâmetros do município.
class SiteFormPage extends StatefulWidget {
  final Plan plan;
  final FloorPlan? floorPlan;
  final Site? initialSite;
  final RuleSettings? initialSettings;
  final ValueChanged<AnalysisInput>? onAnalysisChanged;

  const SiteFormPage({
    super.key,
    required this.plan,
    this.floorPlan,
    this.initialSite,
    this.initialSettings,
    this.onAnalysisChanged,
  });

  @override
  State<SiteFormPage> createState() => _SiteFormPageState();
}

class _SiteFormPageState extends State<SiteFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Terreno e posição da construção
  final TextEditingController _siteWidth = TextEditingController();
  final TextEditingController _siteLength = TextEditingController();
  final TextEditingController _front = TextEditingController();
  final TextEditingController _left = TextEditingController();

  // Parâmetros do município (opcionais)
  final TextEditingController _minFront = TextEditingController();
  final TextEditingController _minSide = TextEditingController();
  final TextEditingController _minRear = TextEditingController();
  final TextEditingController _maxOccupancy = TextEditingController();

  @override
  void initState() {
    super.initState();
    final FloorPlan? floorPlan = widget.floorPlan;
    if (widget.initialSite != null) {
      final site = widget.initialSite!;
      _siteWidth.text = formatDecimal(site.widthM);
      _siteLength.text = formatDecimal(site.lengthM);
      _front.text = formatDecimal(site.frontSetbackM);
      _left.text = formatDecimal(site.leftSetbackM);
    } else if (floorPlan != null) {
      final FloorPlanSiteAnalysis analysis =
          FloorPlanSiteAnalysis.fromFloorPlan(floorPlan);
      _siteWidth.text = formatDecimal(analysis.site.widthM);
      _siteLength.text = formatDecimal(analysis.site.lengthM);
      _front.text = formatDecimal(analysis.site.frontSetbackM);
      _left.text = formatDecimal(analysis.site.leftSetbackM);
    }
    final settings = widget.initialSettings;
    if (settings != null) {
      if (settings.minFrontSetbackM > 0)
        _minFront.text = formatDecimal(settings.minFrontSetbackM);
      if (settings.minSideSetbackM > 0)
        _minSide.text = formatDecimal(settings.minSideSetbackM);
      if (settings.minRearSetbackM > 0)
        _minRear.text = formatDecimal(settings.minRearSetbackM);
      if (settings.maxOccupancyPercent > 0)
        _maxOccupancy.text = formatDecimal(settings.maxOccupancyPercent);
    }
  }

  @override
  void dispose() {
    _siteWidth.dispose();
    _siteLength.dispose();
    _front.dispose();
    _left.dispose();
    _minFront.dispose();
    _minSide.dispose();
    _minRear.dispose();
    _maxOccupancy.dispose();
    super.dispose();
  }

  /// Fábrica de validadores, para não repetir o mesmo código em cada campo.
  /// - optional: campo pode ficar vazio
  /// - allowZero: aceita 0 (ex.: construção encostada na divisa)
  FormFieldValidator<String> _numberValidator({
    required bool optional,
    required bool allowZero,
    double max = 1000,
  }) {
    return (String? value) {
      if (optional && (value == null || value.trim().isEmpty)) return null;

      final double? number = parseDecimal(value);
      if (number == null) return 'Informe um número válido';
      if (number < 0) return 'Não pode ser negativo';
      if (number == 0 && !allowZero) return 'Deve ser maior que zero';
      if (number > max) return 'Máximo de ${max.toStringAsFixed(0)}';
      return null;
    };
  }

  /// Campo de texto numérico padronizado.
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Duas colunas lado a lado.
  Widget _row(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  void _onAnalyze() {
    if (!_formKey.currentState!.validate()) return;

    final Site site = Site(
      widthM: parseDecimal(_siteWidth.text)!,
      lengthM: parseDecimal(_siteLength.text)!,
      frontSetbackM: parseDecimal(_front.text)!,
      leftSetbackM: parseDecimal(_left.text)!,
    );

    // Campos opcionais vazios viram 0 ("não verificar").
    final RuleSettings settings = RuleSettings(
      minFrontSetbackM: parseDecimal(_minFront.text) ?? 0,
      minSideSetbackM: parseDecimal(_minSide.text) ?? 0,
      minRearSetbackM: parseDecimal(_minRear.text) ?? 0,
      maxOccupancyPercent: parseDecimal(_maxOccupancy.text) ?? 0,
    );
    widget.onAnalysisChanged?.call(
      AnalysisInput(site: site, settings: settings),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlertsPage(
          plan: widget.plan,
          floorPlan: widget.floorPlan,
          site: site,
          settings: settings,
          onAnalysisChanged: widget.onAnalysisChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Plan plan = widget.plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Análise preliminar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // Resumo da construção que será analisada
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.home_work_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Construção: ${formatDecimal(plan.boundingWidthM)} × '
                      '${formatDecimal(plan.boundingHeightM)} m '
                      '(${formatDecimal(widget.floorPlan?.builtAreaM2 ?? plan.areaM2)} m²)',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.floorPlan != null) ...[
            const SizedBox(height: 6),
            Text(
              'A área construída e a ocupação somam os cômodos. Os recuos '
              'são aproximados pelo retângulo envolvente da construção.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terreno',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _row(
                  _field(
                    controller: _siteWidth,
                    label: 'Largura',
                    suffix: 'm',
                    validator: _numberValidator(
                      optional: false,
                      allowZero: false,
                    ),
                  ),
                  _field(
                    controller: _siteLength,
                    label: 'Comprimento',
                    suffix: 'm',
                    validator: _numberValidator(
                      optional: false,
                      allowZero: false,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Posição da construção',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Olhando de cima, com a rua embaixo: distância da '
                  'construção até a frente e até a divisa da esquerda.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _row(
                  _field(
                    controller: _front,
                    label: 'Até a frente',
                    suffix: 'm',
                    validator: _numberValidator(
                      optional: false,
                      allowZero: true,
                    ),
                  ),
                  _field(
                    controller: _left,
                    label: 'Até a esquerda',
                    suffix: 'm',
                    validator: _numberValidator(
                      optional: false,
                      allowZero: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Parâmetros opcionais, escondidos até o usuário abrir.
                Card(
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: const Text(
                      'Parâmetros do município (opcional)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Deixe vazio para não verificar.',
                      style: TextStyle(fontSize: 12),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _row(
                        _field(
                          controller: _minFront,
                          label: 'Recuo frontal mín.',
                          suffix: 'm',
                          validator: _numberValidator(
                            optional: true,
                            allowZero: true,
                          ),
                        ),
                        _field(
                          controller: _minSide,
                          label: 'Recuo lateral mín.',
                          suffix: 'm',
                          validator: _numberValidator(
                            optional: true,
                            allowZero: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _row(
                        _field(
                          controller: _minRear,
                          label: 'Recuo de fundos mín.',
                          suffix: 'm',
                          validator: _numberValidator(
                            optional: true,
                            allowZero: true,
                          ),
                        ),
                        _field(
                          controller: _maxOccupancy,
                          label: 'Taxa de ocupação máx.',
                          suffix: '%',
                          validator: _numberValidator(
                            optional: true,
                            allowZero: true,
                            max: 100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          FilledButton(onPressed: _onAnalyze, child: const Text('Analisar')),
        ],
      ),
    );
  }
}
