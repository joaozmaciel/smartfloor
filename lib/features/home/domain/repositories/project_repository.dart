import '../entities/project.dart';

/// Contrato (interface): define O QUE o app precisa fazer com projetos,
/// sem dizer COMO. A implementação fica na camada `data`.
abstract class ProjectRepository {
  List<Project> getProjects();
}