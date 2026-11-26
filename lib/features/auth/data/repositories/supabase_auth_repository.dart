import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Nao foi possivel autenticar o usuario.');
    }
    return _toAuthUser(user);
  }

  @override
  Future<AuthUser?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String whatsapp,
    String? cep,
    String? city,
    int? age,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
        'whatsapp': whatsapp,
        'cep': cep,
        'city': city,
        'age': age,
        'terms_version': '2026-11',
        'terms_accepted_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Nao foi possivel criar o usuario.');
    }
    return response.session == null ? null : _toAuthUser(user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  AuthUser _toAuthUser(User user) {
    final metadataName = user.userMetadata?['name'];
    final name = metadataName is String && metadataName.isNotEmpty
        ? metadataName
        : user.email?.split('@').first ?? '';

    return AuthUser(name: name, email: user.email ?? '');
  }
}
