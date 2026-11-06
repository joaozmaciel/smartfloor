import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/mock_project_repository.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../widgets/capture_shortcut_card.dart';
import '../widgets/greeting_card.dart';
import '../widgets/project_card.dart';

/// Tela inicial do SmartFloor.
///
/// Aceita um [repository] injetado para facilitar testes e futuras mudanças de backend.
class HomePage extends StatefulWidget {
  final ProjectRepository repository;

  const HomePage({
    super.key,
    this.repository = const MockProjectRepository(),
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Índice da aba selecionada na barra inferior (0 = Início).
  int _selectedIndex = 0;

  /// Mostra uma mensagem temporária na parte de baixo da tela.
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature: em breve!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Project> projects = widget.repository.getProjects();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // ---------- Barra superior ----------
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home_work_rounded),
            SizedBox(width: 8),
            Text('SmartFloor', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showComingSoon('Menu'),
          ),
        ],
      ),

      // ---------- Conteúdo (IndexedStack mantém o estado de cada aba) ----------
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(projects, textTheme),
          _buildProjectsTab(projects, textTheme),
          _buildProfileTab(textTheme),
          _buildMoreTab(textTheme),
        ],
      ),

      // ---------- Botão flutuante ----------
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComingSoon('Novo projeto'),
        child: const Icon(Icons.add),
      ),

      // ---------- Barra de navegação inferior ----------
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: AppColors.primary),
            label: 'Projetos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps, color: AppColors.primary),
            label: 'Mais',
          ),
        ],
      ),
    );
  }

  /// Aba 0: Tela Inicial (Destaques, boas-vindas e atalhos).
  Widget _buildHomeTab(List<Project> projects, TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const GreetingCard(userName: 'Rebeca'),
        const SizedBox(height: 12),
        CaptureShortcutCard(
          onTap: () => _showComingSoon('Captura de ambiente'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Meus projetos',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final project in projects) ...[
          ProjectCard(
            project: project,
            onTap: () => _showComingSoon(project.name),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Aba 1: Lista completa de projetos.
  Widget _buildProjectsTab(List<Project> projects, TextTheme textTheme) {
    final double totalArea = projects.fold(0, (sum, p) => sum + p.areaM2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          'Todos os Projetos',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${projects.length} projeto(s) salvo(s) • Total de ${totalArea.toStringAsFixed(1).replaceAll('.', ',')} m²',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (projects.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Nenhum projeto encontrado.',
                style: textTheme.bodyLarge,
              ),
            ),
          )
        else
          for (final project in projects) ...[
            ProjectCard(
              project: project,
              onTap: () => _showComingSoon(project.name),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  /// Aba 2: Perfil do usuário.
  Widget _buildProfileTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.highlight,
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rebeca',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'rebeca@smartfloor.app',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Editar dados pessoais'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showComingSoon('Editar perfil'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Privacidade e Segurança'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showComingSoon('Privacidade'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Aba 3: Mais e Configurações.
  Widget _buildMoreTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          'Mais opções',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações do aplicativo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showComingSoon('Configurações'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ajuda e Suporte'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showComingSoon('Suporte'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sobre o SmartFloor'),
                subtitle: const Text('Versão 1.0.0'),
                onTap: () => _showComingSoon('Sobre'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}