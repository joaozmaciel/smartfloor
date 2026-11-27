import '../../../home/domain/entities/project.dart';
import '../entities/assistant_message.dart';

abstract class PlanningAssistantRepository {
  Future<String> reply({
    required List<AssistantMessage> conversation,
    required List<Project> projects,
  });
}
