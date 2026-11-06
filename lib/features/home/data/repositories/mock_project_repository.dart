import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

/// Implementação provisória com dados fictícios.
/// Mais adiante, vamos substituí-la por uma que lê de um banco de dados.
class MockProjectRepository implements ProjectRepository {
  const MockProjectRepository();

  @override
  List<Project> getProjects() {
    return [
      Project(
        id: '1',
        name: 'Casa da família',
        areaM2: 68.5,
        createdAt: DateTime(2025, 4, 12),
      ),
      Project(
        id: '2',
        name: 'Apartamento',
        areaM2: 54,
        createdAt: DateTime(2025, 3, 20),
      ),
      Project(
        id: '3',
        name: 'Escritório',
        areaM2: 32,
        createdAt: DateTime(2025, 1, 15),
      ),
    ];
  }
}