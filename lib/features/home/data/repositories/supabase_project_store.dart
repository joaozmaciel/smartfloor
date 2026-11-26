import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../plan/domain/entities/floor_plan.dart';
import '../../../rules/domain/entities/analysis_input.dart';
import '../../domain/entities/project_document.dart';
import '../../domain/repositories/project_store.dart';
import '../project_document_mapper.dart';

class SupabaseProjectStore implements ProjectStore {
  SupabaseProjectStore({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _table = 'projects';
  static const String _bucket = 'project-backgrounds';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Faça login para salvar projetos.');
    return id;
  }

  @override
  Future<SavedProject> load(String projectId) async {
    _userId;
    final row = await _client
        .from(_table)
        .select('id, name, data')
        .eq('id', projectId)
        .single();
    final name = row['name'] as String;
    final raw = row['data'];
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final document = data.isEmpty
        ? ProjectDocument(floorPlan: FloorPlan(name: name))
        : ProjectDocumentMapper.fromJson(data);
    return SavedProject(
      id: row['id'] as String,
      name: name,
      document: document,
    );
  }

  @override
  Future<SavedProject> save({
    String? projectId,
    required FloorPlan floorPlan,
    BackgroundInfo? background,
    BackgroundUpload? pendingBackground,
    AnalysisInput? analysis,
  }) async {
    final userId = _userId;
    ProjectDocument document = ProjectDocument(
      floorPlan: floorPlan,
      background: background,
      analysis: analysis,
    );
    String id = await _writeRow(projectId, floorPlan, document);
    bool uploadFailed = false;
    if (pendingBackground != null && background != null) {
      final path = '$userId/$id/background';
      try {
        await _client.storage
            .from(_bucket)
            .uploadBinary(
              path,
              pendingBackground.bytes,
              fileOptions: FileOptions(
                contentType: pendingBackground.contentType,
                upsert: true,
              ),
            );
        document = ProjectDocument(
          floorPlan: floorPlan,
          background: background.copyWith(storagePath: path),
          analysis: analysis,
        );
        id = await _writeRow(id, floorPlan, document);
      } catch (_) {
        uploadFailed = true;
      }
    }
    return SavedProject(
      id: id,
      name: floorPlan.name,
      document: document,
      backgroundUploadFailed: uploadFailed,
    );
  }

  Future<String> _writeRow(
    String? id,
    FloorPlan floorPlan,
    ProjectDocument document,
  ) async {
    final values = <String, dynamic>{
      'name': floorPlan.name,
      'area_m2': floorPlan.builtAreaM2,
      'lot_area_m2': floorPlan.lot?.areaM2,
      'room_count': floorPlan.rooms.length,
      'background_path': document.background?.storagePath,
      'data': ProjectDocumentMapper.toJson(document),
    };
    final row = id == null
        ? await _client.from(_table).insert(values).select('id').single()
        : await _client
              .from(_table)
              .update(values)
              .eq('id', id)
              .select('id')
              .single();
    return row['id'] as String;
  }

  @override
  Future<void> saveAnalysis(String projectId, AnalysisInput analysis) async {
    _userId;
    final row = await _client
        .from(_table)
        .select('data')
        .eq('id', projectId)
        .single();
    final raw = row['data'];
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    if (data.isEmpty)
      throw StateError('Salve o projeto antes de guardar a análise.');
    data['analysis'] = ProjectDocumentMapper.analysisToJson(analysis);
    await _client.from(_table).update({'data': data}).eq('id', projectId);
  }

  @override
  Future<Uint8List> downloadBackground(String storagePath) =>
      _client.storage.from(_bucket).download(storagePath);

  @override
  Future<void> delete(String projectId) async {
    _userId;
    final row = await _client
        .from(_table)
        .select('background_path')
        .eq('id', projectId)
        .maybeSingle();
    final path = row?['background_path'] as String?;
    if (path != null) await _client.storage.from(_bucket).remove([path]);
    await _client.from(_table).delete().eq('id', projectId);
  }
}
