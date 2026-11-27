import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseProjectRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('É necessário entrar para acessar seus projetos.');
    }
    return user.id;
  }

  @override
  Future<List<Project>> getProjects() async {
    final rows = await _client
        .from('projects')
        .select(
          'id, name, area_m2, width_m, length_m, height_m, created_at',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows.map(Project.fromJson).toList();
  }

  @override
  Future<Project> createProject({
    required String name,
    required double areaM2,
    double? widthM,
    double? lengthM,
    double? heightM,
  }) async {
    final row = await _client
        .from('projects')
        .insert({
          'user_id': _userId,
          'name': name,
          'area_m2': areaM2,
          'width_m': widthM,
          'length_m': lengthM,
          'height_m': heightM,
        })
        .select(
          'id, name, area_m2, width_m, length_m, height_m, created_at',
        )
        .single();

    return Project.fromJson(row);
  }
}
