import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseProjectRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Project>> getProjects() async {
    final rows = await _client
        .from('projects')
        .select('id, name, area_m2, created_at, background_path')
        .order('updated_at', ascending: false);

    return rows.map(Project.fromJson).toList();
  }

  @override
  Future<Project> createProject({
    required String name,
    required double areaM2,
  }) async {
    final row = await _client
        .from('projects')
        .insert({'name': name, 'area_m2': areaM2})
        .select('id, name, area_m2, created_at, background_path')
        .single();
    return Project.fromJson(row);
  }
}
