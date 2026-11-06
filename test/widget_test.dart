import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartfloor/app.dart';
import 'package:smartfloor/features/home/domain/entities/project.dart';
import 'package:smartfloor/features/home/domain/repositories/project_repository.dart';
import 'package:smartfloor/features/home/presentation/pages/home_page.dart';

class FakeProjectRepository implements ProjectRepository {
  final List<Project> projects;

  FakeProjectRepository(this.projects);

  @override
  List<Project> getProjects() => projects;
}

void main() {
  testWidgets('home displays projects and shows feedback for a new project', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartFloorApp());

    expect(find.text('Olá, Rebeca!'), findsOneWidget);
    expect(find.text('Meus projetos'), findsOneWidget);
    expect(find.text('Casa da família'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    // Verifica feedback temporário
    expect(find.text('Novo projeto: em breve!'), findsOneWidget);
  });

  testWidgets('allows navigating between bottom navigation bar tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartFloorApp());

    // Navega para a aba "Projetos"
    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();

    expect(find.text('Todos os Projetos'), findsOneWidget);

    // Navega para a aba "Perfil"
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('rebeca@smartfloor.app'), findsOneWidget);

    // Navega para a aba "Mais"
    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();

    expect(find.text('Mais opções'), findsOneWidget);
  });

  testWidgets('uses injected ProjectRepository when provided', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeProjectRepository([
      Project(
        id: 'test-1',
        name: 'Projeto de Teste',
        areaM2: 120.0,
        createdAt: DateTime(2025, 5, 1),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(repository: fakeRepo),
      ),
    );

    expect(find.text('Projeto de Teste'), findsOneWidget);
    expect(find.text('120 m²'), findsOneWidget);
  });
}
