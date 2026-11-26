import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  final SettingsController controller;
  final VoidCallback onAdd;
  final VoidCallback? onSignOut;
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onAboutTap;

  const SettingsPage({
    super.key,
    required this.controller,
    required this.onAdd,
    this.onSignOut,
    this.onPrivacyTap,
    this.onHelpTap,
    this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(onAdd: onAdd),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Configurações',
                              style: TextStyle(
                                color: Color(0xFF202421),
                                fontSize: 26,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ajuste como o app captura e salva seus ambientes',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SettingsCardGroup(
                              controller: controller,
                              onPrivacyTap: onPrivacyTap,
                              onHelpTap: onHelpTap,
                              onAboutTap: onAboutTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => _confirmSignOut(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFBF1B1B),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Sair',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do SmartFloor?'),
        content: const Text('Deseja encerrar sua sessão neste dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBF1B1B),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (onSignOut != null) {
      onSignOut!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ação de saída ainda não configurada.')),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const _SettingsHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: const Color(0xFF202421),
              fixedSize: const Size(44, 44),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.highlight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'SmartFloor',
              style: TextStyle(
                color: Color(0xFF202421),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton.filled(
            tooltip: 'Nova captura',
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 25),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              fixedSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCardGroup extends StatelessWidget {
  final SettingsController controller;
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onAboutTap;

  const _SettingsCardGroup({
    required this.controller,
    required this.onPrivacyTap,
    required this.onHelpTap,
    required this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5ECE6)),
        ),
        child: Column(
          children: [
            _SegmentedSettingCard<MeasurementUnit>(
              title: 'Unidade de medida',
              currentValue: controller.measurementUnit,
              currentLabel: controller.measurementUnit == MeasurementUnit.meters
                  ? 'Metros (m)'
                  : 'Pés (ft)',
              options: const [
                (value: MeasurementUnit.meters, label: 'Metros'),
                (value: MeasurementUnit.feet, label: 'Pés'),
              ],
              onChanged: controller.setMeasurementUnit,
            ),
            const SizedBox(height: 8),
            _SegmentedSettingCard<CaptureQuality>(
              title: 'Qualidade de captura',
              currentValue: controller.captureQuality,
              currentLabel: controller.captureQuality == CaptureQuality.high
                  ? 'Alta (HD)'
                  : 'Baixa',
              options: const [
                (value: CaptureQuality.high, label: 'Alta'),
                (value: CaptureQuality.low, label: 'Baixa'),
              ],
              onChanged: controller.setCaptureQuality,
            ),
            const SizedBox(height: 8),
            _SwitchSettingCard(
              title: 'Salvamento automático',
              subtitle: controller.automaticSaving ? 'Ativado' : 'Desativado',
              value: controller.automaticSaving,
              onChanged: controller.setAutomaticSaving,
            ),
            const SizedBox(height: 8),
            _SwitchSettingCard(
              title: 'Notificações',
              subtitle: 'Push e alertas',
              value: controller.notificationsEnabled,
              onChanged: controller.setNotificationsEnabled,
            ),
            const SizedBox(height: 8),
            _NavigationSettingCard(
              title: 'Privacidade e permissões',
              subtitle: 'Ajustar acesso e dados',
              onTap:
                  onPrivacyTap ??
                  () => _showUnavailable(context, 'Privacidade e permissões'),
            ),
            const SizedBox(height: 8),
            _NavigationSettingCard(
              title: 'Ajuda',
              subtitle: 'Central de ajuda e suporte',
              onTap: onHelpTap ?? () => _showUnavailable(context, 'Ajuda'),
            ),
            const SizedBox(height: 8),
            _NavigationSettingCard(
              title: 'Sobre o aplicativo',
              subtitle: 'Versão 1.0.0 • Políticas',
              onTap:
                  onAboutTap ??
                  () => _showUnavailable(context, 'Sobre o aplicativo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnavailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature: em breve!')));
  }
}

class _SegmentedSettingCard<T> extends StatelessWidget {
  final String title;
  final String currentLabel;
  final T currentValue;
  final List<({T value, String label})> options;
  final ValueChanged<T> onChanged;

  const _SegmentedSettingCard({
    required this.title,
    required this.currentLabel,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftSettingCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                currentLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                for (final option in options)
                  Expanded(
                    child: _SegmentOption(
                      label: option.label,
                      selected: currentValue == option.value,
                      onTap: () => onChanged(option.value),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchSettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftSettingCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavigationSettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationSettingCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _SoftSettingCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 28,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftSettingCard extends StatelessWidget {
  final Widget child;

  const _SoftSettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECE6)),
      ),
      child: child,
    );
  }
}
