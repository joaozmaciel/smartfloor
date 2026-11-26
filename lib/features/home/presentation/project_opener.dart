import 'package:flutter/material.dart';

import '../../plan/domain/entities/point_2d.dart';
import '../../plan/presentation/pages/floor_plan_editor_page.dart';
import '../../plan/presentation/widgets/plan_underlay.dart';
import '../data/repositories/supabase_project_store.dart';
import '../domain/entities/project_document.dart';
import '../domain/repositories/project_store.dart';

Future<void> openProject(
  BuildContext context,
  String projectId, {
  ProjectStore? store,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final projectStore = store ?? SupabaseProjectStore();
  PlanUnderlay? underlay;
  BackgroundInfo? background;
  bool imageFailed = false;
  bool loadingDialogOpen = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Abrindo projeto...'),
        ],
      ),
    ),
  );
  try {
    final saved = await projectStore.load(projectId);
    background = saved.document.background;
    final info = background;
    if (info != null && info.storagePath != null) {
      try {
        final bytes = await projectStore.downloadBackground(info.storagePath!);
        underlay = await PlanUnderlay.fromBytes(
          bytes,
          origin: Point2D(info.originX, info.originY),
          metersPerPixel: info.metersPerPixel,
          keepBytes: false,
        );
      } catch (_) {
        imageFailed = true;
      }
    }
    navigator.pop();
    loadingDialogOpen = false;
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => FloorPlanEditorPage(
          initialPlan: saved.document.floorPlan,
          projectId: saved.id,
          background: background,
          initialUnderlay: underlay,
          analysis: saved.document.analysis,
        ),
      ),
    );
    if (imageFailed)
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível baixar a imagem de fundo.'),
        ),
      );
  } catch (_) {
    if (loadingDialogOpen) navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o projeto.')),
    );
    underlay?.image.dispose();
  }
}
