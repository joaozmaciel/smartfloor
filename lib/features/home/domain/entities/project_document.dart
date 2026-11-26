import '../../../capture/domain/entities/capture_mode.dart';
import '../../../plan/domain/entities/floor_plan.dart';
import '../../../rules/domain/entities/analysis_input.dart';

class BackgroundInfo {
  final CaptureMode captureMode;
  final bool wasPdf;
  final String fileName;
  final String? storagePath;
  final double originX;
  final double originY;
  final double metersPerPixel;

  const BackgroundInfo({
    required this.captureMode,
    required this.wasPdf,
    required this.fileName,
    required this.storagePath,
    required this.originX,
    required this.originY,
    required this.metersPerPixel,
  });

  BackgroundInfo copyWith({
    String? storagePath,
    double? originX,
    double? originY,
    double? metersPerPixel,
  }) => BackgroundInfo(
    captureMode: captureMode,
    wasPdf: wasPdf,
    fileName: fileName,
    storagePath: storagePath ?? this.storagePath,
    originX: originX ?? this.originX,
    originY: originY ?? this.originY,
    metersPerPixel: metersPerPixel ?? this.metersPerPixel,
  );
}

class ProjectDocument {
  final FloorPlan floorPlan;
  final BackgroundInfo? background;
  final AnalysisInput? analysis;

  const ProjectDocument({
    required this.floorPlan,
    this.background,
    this.analysis,
  });

  ProjectDocument copyWith({BackgroundInfo? background}) => ProjectDocument(
    floorPlan: floorPlan,
    background: background ?? this.background,
    analysis: analysis,
  );
}

class SavedProject {
  final String id;
  final String name;
  final ProjectDocument document;
  final bool backgroundUploadFailed;

  const SavedProject({
    required this.id,
    required this.name,
    required this.document,
    this.backgroundUploadFailed = false,
  });
}
