import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/entities/project.dart';
import '../../data/repositories/supabase_planning_assistant_repository.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/repositories/planning_assistant_repository.dart';

class PlanningAssistantPage extends StatefulWidget {
  final List<Project> projects;
  final PlanningAssistantRepository? repository;

  const PlanningAssistantPage({
    super.key,
    required this.projects,
    this.repository,
  });

  @override
  State<PlanningAssistantPage> createState() => _PlanningAssistantPageState();
}

class _PlanningAssistantPageState extends State<PlanningAssistantPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<AssistantMessage> _conversation = [];
  bool _isSending = false;
  String? _errorMessage;

  PlanningAssistantRepository get _repository =>
      widget.repository ?? SupabasePlanningAssistantRepository();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _conversation.add(AssistantMessage(role: 'user', content: text));
      _messageController.clear();
      _isSending = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      final reply = await _repository.reply(
        conversation: List.unmodifiable(_conversation),
        projects: widget.projects,
      );
      if (!mounted) return;
      setState(() {
        _conversation.add(AssistantMessage(role: 'model', content: reply));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = 'Não foi possível falar com o assistente: $error';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Assistente SmartFloor'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversation.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversation.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _conversation.length) {
                        return const _MessageBubble(
                          message: AssistantMessage(
                            role: 'model',
                            content: 'Estou pensando...',
                          ),
                          isLoading: true,
                        );
                      }
                      return _MessageBubble(
                        message: _conversation[index],
                      );
                    },
                  ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Pergunte sobre seu projeto...',
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar mensagem',
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 44,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Vamos planejar seu ambiente?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Conte o que você quer criar. Posso ajudar com ideias e '
              'explicar os dados dos seus projetos. Confira as sugestões '
              'antes de aplicá-las.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ao enviar uma mensagem, ela e os dados resumidos dos seus '
              'projetos serão enviados ao Gemini para gerar a resposta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;
  final bool isLoading;

  const _MessageBubble({
    required this.message,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : null,
            fontStyle: isLoading ? FontStyle.italic : null,
          ),
        ),
      ),
    );
  }
}
