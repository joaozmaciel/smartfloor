import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/domain/repositories/project_repository.dart';
import '../../../plan/domain/entities/floor_plan.dart';
import '../../../plan/domain/entities/plan.dart';
import '../../../plan/presentation/pages/floor_plan_editor_page.dart';
import '../../domain/entities/captured_input.dart';
import '../widgets/capture_step_indicator.dart';

/// Etapa 3 do fluxo: o usuário informa as medidas do ambiente.
class CaptureMeasuresPage extends StatefulWidget {
  final CapturedInput input;
  final ProjectRepository? projectRepository;

  const CaptureMeasuresPage({
    super.key,
    required this.input,
    this.projectRepository,
  });

  @override
  State<CaptureMeasuresPage> createState() => _CaptureMeasuresPageState();
}

class _CaptureMeasuresPageState extends State<CaptureMeasuresPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  double? _parse(String? text) {
    if (text == null) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  String? _validateMeasure(String? value) {
    final double? number = _parse(value);
    if (number == null) return 'Informe um número válido';
    if (number <= 0) return 'Deve ser maior que zero';
    if (number > 100) return 'Máximo de 100 m';
    return null;
  }

  double? get _previewArea {
    final double? width = _parse(_widthController.text);
    final double? length = _parse(_lengthController.text);
    if (width == null || length == null || width <= 0 || length <= 0) {
      return null;
    }
    return width * length;
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    final Plan room = Plan.fromRectangle(
      name: _nameController.text.trim(),
      widthM: _parse(_widthController.text)!,
      lengthM: _parse(_lengthController.text)!,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FloorPlanEditorPage(
          initialPlan: FloorPlan(name: room.name, rooms: [room]),
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? suffix, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double? previewArea = _previewArea;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartFloor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const CaptureStepIndicator(
            title: 'Capturar Ambiente',
            currentStep: 3,
            totalSteps: 4,
          ),
          const SizedBox(height: 24),
          Text(
            'Medidas do ambiente',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Meça com uma trena e informe em metros. '
            'Você poderá ajustar tudo no editor.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildReferenceCard(textTheme),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _decoration(
                    'Nome do ambiente',
                    hint: 'Ex: Meio ambiente',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe um nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _widthController,
                  decoration: _decoration('Largura', suffix: 'm'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: _validateMeasure,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lengthController,
                  decoration: _decoration('Comprimento', suffix: 'm'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: _validateMeasure,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (previewArea != null) ...[
            Card(
              color: AppColors.highlight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.square_foot, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Área estimada: ${formatDecimal(previewArea)} m²',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(onPressed: _onContinue, child: const Text('Continuar')),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(TextTheme textTheme) {
    final CapturedInput input = widget.input;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: input.isPdf
                    ? const ColoredBox(
                        color: AppColors.highlight,
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.primary,
                        ),
                      )
                    : Image.file(
                        File(input.path),
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arquivo de referência',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    input.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}
