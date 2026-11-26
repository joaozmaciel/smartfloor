import 'dart:typed_data';

import '../../../plan/domain/entities/floor_plan.dart';
import '../../../rules/domain/entities/analysis_input.dart';
import '../entities/project_document.dart';

class BackgroundUpload {
  final Uint8List bytes;
  final String contentType;

  const BackgroundUpload({required this.bytes, required this.contentType});
}

abstract class ProjectStore {
  Future<SavedProject> load(String projectId);
  Future<SavedProject> save({
    String? projectId,
    required FloorPlan floorPlan,
    BackgroundInfo? background,
    BackgroundUpload? pendingBackground,
    AnalysisInput? analysis,
  });
  Future<void> saveAnalysis(String projectId, AnalysisInput analysis);
  Future<Uint8List> downloadBackground(String storagePath);
  Future<void> delete(String projectId);
}
