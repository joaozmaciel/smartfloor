import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/mock_project_repository.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../widgets/capture_shortcut_card.dart';
import '../widgets/greeting_card.dart';
import '../widgets/project_card.dart';
import '../../../capture/presentation/pages/capture_page.dart';
import '../../data/repositories/supabase_project_store.dart';
import '../../domain/repositories/project_store.dart';
import '../project_opener.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/pages/settings_page.dart';

/// Tela inicial do SmartFloor.
///
/// Aceita um [repository] injetado para facilitar testes e futuras mudanças de backend.
class HomePage extends StatefulWidget {
  final ProjectRepository repository;
  final String userName;
  final String userEmail;
  final ProjectStore? store;

  HomePage({
    super.key,
    ProjectRepository? repository,
    this.userName = '',
    this.userEmail = '',
    ProjectStore? store,
  }) : repository = repository ?? MockProjectRepository(),
       store = store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Índice da aba selecionada na barra inferior (0 = Início).
  int _selectedIndex = 0;
  List<Project> _projects = [];
  bool _isLoadingProjects = true;
  Object? _projectsError;
  late final SettingsController _settingsController = SettingsController();
  ProjectStore get _store => widget.store ?? SupabaseProjectStore();

  @override
  void initState() {
    super.initState();
    _loadProjects(showLoading: false);
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoadingProjects = true;
        _projectsError = null;
      });
    }

    try {
      final projects = await widget.repository.getProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
        _projectsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingProjects = false;
        _projectsError = error;
      });
    }
  }

  /// Mostra uma mensagem temporária na parte de baixo da tela.
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature: em breve!')));
  }

  /// Abre a tela de captura por cima da Home.
  /// Navigator é a "pilha de telas": push coloca uma nova no topo,
  /// e o botão voltar remove ela e retorna à Home.
  Future<void> _openCapture() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CapturePage(projectRepository: widget.repository),
      ),
    );
    if (mounted) await _loadProjects();
  }

  Future<void> _openSavedProject(Project project) async {
    await openProject(context, project.id, store: _store);
    if (mounted) await _loadProjects();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          controller: _settingsController,
          onAdd: _openCapture,
          onPrivacyTap: () => _showComingSoon('Privacidade e permissões'),
          onHelpTap: () => _showComingSoon('Ajuda e suporte'),
          onAboutTap: () => _showComingSoon('Sobre o aplicativo'),
        ),
      ),
    );
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir projeto?'),
        content: Text(
          'O projeto "${project.name}" e sua imagem serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _store.delete(project.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Projeto excluído.')));
        await _loadProjects();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o projeto.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // ---------- Barra superior ----------
      appBar: _selectedIndex == 2
          ? null
          : AppBar(
              title: const Row(
                children: [
                  Icon(Icons.home_work_rounded),
                  SizedBox(width: 8),
                  Text(
                    'SmartFloor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
          _buildHomeTab(textTheme),
          _buildProjectsTab(textTheme),
          _buildProfileTab(textTheme),
          _buildMoreTab(textTheme),
        ],
      ),

      // ---------- Botão flutuante ----------
      floatingActionButton: _selectedIndex == 2
          ? null
          : FloatingActionButton(
              onPressed: _openCapture,
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
  Widget _buildHomeTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        GreetingCard(userName: widget.userName),
        const SizedBox(height: 12),
        CaptureShortcutCard(onTap: _openCapture),
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
            if (_projects.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingProjects)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_projectsError != null)
          _buildProjectsError()
        else if (_projects.isEmpty)
          _buildEmptyProjectsCard()
        else
          for (final project in _projects) ...[
            ProjectCard(
              project: project,
              onTap: () => _openSavedProject(project),
              onLongPress: () => _deleteProject(project),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  /// Aba 1: Lista completa de projetos.
  Widget _buildProjectsTab(TextTheme textTheme) {
    final double totalArea = _projects.fold(
      0,
      (sum, project) => sum + project.areaM2,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          'Todos os Projetos',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${_projects.length} projeto(s) salvo(s) • Total de ${totalArea.toStringAsFixed(1).replaceAll('.', ',')} m²',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (_isLoadingProjects)
          const Center(child: CircularProgressIndicator())
        else if (_projectsError != null)
          _buildProjectsError()
        else if (_projects.isEmpty)
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
          for (final project in _projects) ...[
            ProjectCard(
              project: project,
              onTap: () => _openSavedProject(project),
              onLongPress: () => _deleteProject(project),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildEmptyProjectsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.home_work_outlined,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Você ainda não tem projetos.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Crie seu primeiro ambiente para vê-lo aparecer aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _openCapture,
              icon: const Icon(Icons.add),
              label: const Text('Criar projeto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Não foi possível carregar seus projetos.'),
            TextButton(
              onPressed: () => _loadProjects(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Aba 2: Perfil do usuário.
  Widget _buildProfileTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.highlight,
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Resumo do perfil',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: FilledButton(
                      onPressed: () => _showComingSoon('Resumo do perfil'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Acesse suas configurações, ambientes e preferências '
                'em um só lugar.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _profileShortcut(
                icon: Icons.folder_open_outlined,
                title: 'Projetos',
                subtitle: 'Acesse ambientes e plantas',
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _profileShortcut(
                icon: Icons.settings_outlined,
                title: 'Configurações',
                subtitle: 'Ajuste unidades e captura',
                onTap: _openSettings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _profileLink(
          title: 'Preferências',
          subtitle: 'Unidades, qualidade e notificações',
          onTap: () => _showComingSoon('Preferências'),
        ),
        const SizedBox(height: 8),
        _profileLink(
          title: 'Ambientes',
          subtitle: 'Gerencie plantas e capturas',
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        const SizedBox(height: 8),
        _profileLink(
          title: 'Ajuda',
          subtitle: 'Central de ajuda e suporte',
          onTap: () => _showComingSoon('Ajuda e suporte'),
        ),
        const SizedBox(height: 8),
        _profileLink(
          title: 'Sobre o aplicativo',
          subtitle: 'Versão 1.0.0 • Políticas',
          onTap: () => _showComingSoon('Sobre o aplicativo'),
        ),
      ],
    );
  }

  Widget _profileShortcut({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 88,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileLink({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, height: 1.2),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aba 3: Mais e Configurações.
  Widget _buildMoreTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          'Mais opções',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações do aplicativo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openSettings,
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
