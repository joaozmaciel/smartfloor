import '../../capture/domain/entities/capture_mode.dart';
import '../../plan/domain/entities/floor_plan.dart';
import '../../plan/domain/entities/plan.dart';
import '../../plan/domain/entities/point_2d.dart';
import '../../rules/domain/entities/analysis_input.dart';
import '../../rules/domain/entities/rule_settings.dart';
import '../../rules/domain/entities/site.dart';
import '../domain/entities/project_document.dart';

class ProjectDocumentMapper {
  ProjectDocumentMapper._();

  static Map<String, dynamic> toJson(ProjectDocument document) => {
    'version': 1,
    'floorPlan': {
      'name': document.floorPlan.name,
      'lot': document.floorPlan.lot == null
          ? null
          : _planToJson(document.floorPlan.lot!),
      'rooms': document.floorPlan.rooms.map(_planToJson).toList(),
    },
    'background': document.background == null
        ? null
        : {
            'captureMode': document.background!.captureMode.name,
            'wasPdf': document.background!.wasPdf,
            'fileName': document.background!.fileName,
            'storagePath': document.background!.storagePath,
            'originX': document.background!.originX,
            'originY': document.background!.originY,
            'metersPerPixel': document.background!.metersPerPixel,
          },
    'analysis': document.analysis == null
        ? null
        : analysisToJson(document.analysis!),
  };

  static Map<String, dynamic> _planToJson(Plan plan) => {
    'name': plan.name,
    'vertices': plan.vertices
        .map((point) => {'x': point.x, 'y': point.y})
        .toList(),
  };

  static ProjectDocument fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw FormatException(
        'Versão de projeto desconhecida: ${json['version']}',
      );
    }
    final Map<String, dynamic> floor = _map(json['floorPlan']);
    final lotJson = floor['lot'];
    final backgroundJson = json['background'];
    final analysisJson = json['analysis'];
    return ProjectDocument(
      floorPlan: FloorPlan(
        name: floor['name'] as String,
        lot: lotJson == null ? null : _planFromJson(_map(lotJson)),
        rooms: (_list(floor['rooms']))
            .map((value) => _planFromJson(_map(value)))
            .toList(),
      ),
      background: backgroundJson == null
          ? null
          : _backgroundFromJson(_map(backgroundJson)),
      analysis: analysisJson == null
          ? null
          : analysisFromJson(_map(analysisJson)),
    );
  }

  static Plan _planFromJson(Map<String, dynamic> json) {
    final vertices = _list(json['vertices']);
    if (vertices.length < 3)
      throw const FormatException(
        'Polígono precisa de ao menos três vértices.',
      );
    return Plan(
      name: json['name'] as String,
      vertices: vertices.map((value) {
        final point = _map(value);
        return Point2D(
          (point['x'] as num).toDouble(),
          (point['y'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  static BackgroundInfo _backgroundFromJson(Map<String, dynamic> json) =>
      BackgroundInfo(
        captureMode: CaptureMode.values.byName(json['captureMode'] as String),
        wasPdf: json['wasPdf'] as bool,
        fileName: json['fileName'] as String,
        storagePath: json['storagePath'] as String?,
        originX: (json['originX'] as num).toDouble(),
        originY: (json['originY'] as num).toDouble(),
        metersPerPixel: (json['metersPerPixel'] as num).toDouble(),
      );

  static Map<String, dynamic> analysisToJson(AnalysisInput input) => {
    'site': {
      'widthM': input.site.widthM,
      'lengthM': input.site.lengthM,
      'frontSetbackM': input.site.frontSetbackM,
      'leftSetbackM': input.site.leftSetbackM,
    },
    'settings': {
      'minFrontSetbackM': input.settings.minFrontSetbackM,
      'minSideSetbackM': input.settings.minSideSetbackM,
      'minRearSetbackM': input.settings.minRearSetbackM,
      'maxOccupancyPercent': input.settings.maxOccupancyPercent,
    },
  };

  static AnalysisInput analysisFromJson(Map<String, dynamic> json) {
    final site = _map(json['site']);
    final settings = _map(json['settings']);
    double number(Map<String, dynamic> map, String key) =>
        (map[key] as num).toDouble();
    return AnalysisInput(
      site: Site(
        widthM: number(site, 'widthM'),
        lengthM: number(site, 'lengthM'),
        frontSetbackM: number(site, 'frontSetbackM'),
        leftSetbackM: number(site, 'leftSetbackM'),
      ),
      settings: RuleSettings(
        minFrontSetbackM: number(settings, 'minFrontSetbackM'),
        minSideSetbackM: number(settings, 'minSideSetbackM'),
        minRearSetbackM: number(settings, 'minRearSetbackM'),
        maxOccupancyPercent: number(settings, 'maxOccupancyPercent'),
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  static List<dynamic> _list(dynamic value) =>
      List<dynamic>.from(value as List);
}
