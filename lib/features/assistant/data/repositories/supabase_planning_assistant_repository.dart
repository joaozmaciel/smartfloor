import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../home/domain/entities/project.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/repositories/planning_assistant_repository.dart';

class SupabasePlanningAssistantRepository
    implements PlanningAssistantRepository {
  SupabasePlanningAssistantRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<String> reply({
    required List<AssistantMessage> conversation,
    required List<Project> projects,
  }) async {
    if (conversation.isEmpty || conversation.last.role != 'user') {
      throw ArgumentError(
        'A conversa precisa terminar com uma mensagem do usuário.',
      );
    }

    final response = await _client.functions.invoke(
      'smartfloor-assistant',
      body: {
        'messages': [
          for (final message in _recentMessages(conversation))
            {'role': message.role, 'content': message.content},
        ],
        'projects': [
          for (final project in projects.take(20))
            {
              'name': project.name,
              'areaM2': project.areaM2,
              'widthM': project.widthM,
              'lengthM': project.lengthM,
              'heightM': project.heightM,
              'createdAt': project.createdAt.toIso8601String(),
            },
        ],
      },
    );

    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      throw StateError('O assistente respondeu com status ${response.status}.');
    }
    if (data is! Map || data['reply'] is! String) {
      throw const FormatException('Resposta inválida do assistente.');
    }

    return data['reply'] as String;
  }

  List<AssistantMessage> _recentMessages(
    List<AssistantMessage> conversation,
  ) {
    final recent = conversation.length <= 20
        ? List<AssistantMessage>.of(conversation)
        : conversation.sublist(conversation.length - 20);
    if (recent.first.role == 'model') recent.removeAt(0);
    return recent;
  }
}
