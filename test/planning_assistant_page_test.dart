import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/assistant/domain/entities/assistant_message.dart';
import 'package:smartfloor/features/assistant/domain/repositories/planning_assistant_repository.dart';
import 'package:smartfloor/features/assistant/presentation/pages/planning_assistant_page.dart';
import 'package:smartfloor/features/home/domain/entities/project.dart';

class _FakePlanningAssistantRepository
    implements PlanningAssistantRepository {
  List<AssistantMessage>? receivedConversation;
  List<Project>? receivedProjects;

  @override
  Future<String> reply({
    required List<AssistantMessage> conversation,
    required List<Project> projects,
  }) async {
    receivedConversation = conversation;
    receivedProjects = projects;
    return 'Podemos começar pela sala.';
  }
}

void main() {
  testWidgets('sends the conversation and project context to the assistant', (
    tester,
  ) async {
    final repository = _FakePlanningAssistantRepository();
    final project = Project(
      id: '1',
      name: 'Sala',
      areaM2: 18,
      createdAt: DateTime(2026, 1, 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlanningAssistantPage(
          projects: [project],
          repository: repository,
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      'Quero reorganizar minha sala.',
    );
    await tester.tap(find.byTooltip('Enviar mensagem'));
    await tester.pumpAndSettle();

    expect(find.text('Quero reorganizar minha sala.'), findsOneWidget);
    expect(find.text('Podemos começar pela sala.'), findsOneWidget);
    expect(repository.receivedConversation, hasLength(1));
    expect(repository.receivedConversation!.single.role, 'user');
    expect(repository.receivedProjects, [project]);
  });
}
