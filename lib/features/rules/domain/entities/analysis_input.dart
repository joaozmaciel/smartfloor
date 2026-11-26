import 'rule_settings.dart';
import 'site.dart';

/// Dados preenchidos pelo usuário para executar a análise da planta.
class AnalysisInput {
  final Site site;
  final RuleSettings settings;

  const AnalysisInput({required this.site, required this.settings});
}
