import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/repositories/project_repository.dart';
import '../../../plan/domain/entities/floor_plan.dart';
import '../../../plan/presentation/pages/floor_plan_editor_page.dart';
import '../../domain/entities/captured_input.dart';
import '../widgets/capture_step_indicator.dart';
import 'capture_measures_page.dart';

/// Etapa 2 do fluxo: o usuário confere o arquivo escolhido.
class CapturePreviewPage extends StatelessWidget {
  final CapturedInput input;
  final ProjectRepository? projectRepository;

  const CapturePreviewPage({
    super.key,
    required this.input,
    this.projectRepository,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartFloor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // SafeArea evita que os botões fiquem atrás da barra do sistema.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CaptureStepIndicator(
                title: 'Capturar Ambiente',
                currentStep: 2,
                totalSteps: 4,
              ),
              const SizedBox(height: 24),
              Text(
                'Confira o arquivo',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Este é o material que usaremos para gerar a planta.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Expanded: a prévia ocupa todo o espaço livre da tela.
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: input.isPdf ? _buildPdfInfo(textTheme) : _buildImage(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                input.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // corta com "..." se longo
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // pop() fecha esta tela e volta para a anterior.
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Escolher outro'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FloorPlanEditorPage(
                              initialPlan: FloorPlan(name: input.name),
                              underlayPath: input.path,
                              underlayIsPdf: input.isPdf,
                              input: input,
                              projectRepository: projectRepository,
                            ),
                          ),
                        );
                      },
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CaptureMeasuresPage(
                          input: input,
                          projectRepository: projectRepository,
                        ),
                      ),
                    );
                  },
                  child: const Text('Prefiro informar as medidas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra a imagem. O InteractiveViewer permite dar zoom com dois dedos
  /// (o mesmo widget que usaremos no editor 2D).
  Widget _buildImage() {
    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      alignment: Alignment.center,
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Image.file(
              File(input.path),
              fit: BoxFit.contain,
              cacheWidth: 1600,
              alignment: Alignment.center,
              // Se a imagem não puder ser lida, mostramos um aviso em vez de travar.
              errorBuilder: (context, error, stackTrace) =>
                  const Text('Não foi possível exibir a imagem.'),
            ),
          ),
        ),
      ),
    );
  }

  /// Para PDF mostramos um ícone. A prévia real das páginas exige
  /// outro pacote e fica para uma etapa futura.
  Widget _buildPdfInfo(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text('Planta em PDF', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'A prévia das páginas virá em breve.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
