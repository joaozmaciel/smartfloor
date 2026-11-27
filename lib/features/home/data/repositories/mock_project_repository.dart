import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

class MockProjectRepository implements ProjectRepository {
  MockProjectRepository({List<Project> initialProjects = const []})
      : _projects = List.of(initialProjects);

  final List<Project> _projects;

  @override
  Future<List<Project>> getProjects() async => List.unmodifiable(_projects);

  @override
  Future<Project> createProject({
    required String name,
    required double areaM2,
    double? widthM,
    double? lengthM,
    double? heightM,
  }) async {
    final now = DateTime.now();
    final project = Project(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      areaM2: areaM2,
      createdAt: now,
      widthM: widthM,
      lengthM: lengthM,
      heightM: heightM,
    );
    _projects.insert(0, project);
    return project;
  }
}