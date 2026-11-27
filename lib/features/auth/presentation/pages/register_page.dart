import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/repositories/project_repository.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  final AuthRepository? authRepository;
  final ProjectRepository? projectRepository;

  const RegisterPage({
    super.key,
    this.authRepository,
    this.projectRepository,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _cepController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;

  AuthRepository get _authRepository =>
      widget.authRepository ?? SupabaseAuthRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _cepController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Confirme que leu os termos e a política de privacidade'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final user = await _authRepository.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        cep: _cepController.text.trim().isEmpty
            ? null
            : _cepController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
      );
      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cadastro criado. Confirme seu e-mail antes de entrar.',
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => HomePage(
            repository: widget.projectRepository,
            userName: user.name,
            userEmail: user.email,
          ),
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        final detail = error.toString().toLowerCase();
        final message = detail.contains('failed host lookup') ||
                detail.contains('socketexception') ||
                detail.contains('clientexception')
            ? 'Sem conexão com a internet. Conecte o tablet ao Wi-Fi ou ative os dados móveis e tente novamente.'
            : 'Não foi possível criar a conta. Tente novamente.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF5F665F),
        fontSize: 14,
      ),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 42,
        minHeight: 42,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0D4D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0D4D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _requiredField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      decoration: _decoration(label: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Preencha este campo';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F4942)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF7F9F5))),
          const Positioned.fill(
              child: CustomPaint(painter: _RegisterBackgroundPainter())),
          SafeArea(
            top: true,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 6, 28, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SmartFloor',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF203228),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.home_work_rounded,
                              color: AppColors.primary,
                              size: 27,
                            ),
                          ],
                        ),
                        const SizedBox(height: 46),
                        Text(
                          'Faça o seu cadastro',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: const Color(0xFF171A18),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _requiredField(
                          controller: _nameController,
                          label: 'Nome',
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(label: 'E-mail'),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Preencha seu e-mail';
                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Informe um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _requiredField(
                          controller: _phoneController,
                          label: 'Telefone',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        _requiredField(
                          controller: _whatsappController,
                          label: 'Celular',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _cepController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(label: 'CEP'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _cityController,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(label: 'Cidade'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(label: 'Idade'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return null;
                            final age = int.tryParse(value);
                            if (age == null || age < 1 || age > 120) {
                              return 'Informe uma idade válida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            label: 'Senha',
                            suffix: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                                color: const Color(0xFF667068),
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe uma senha';
                            }
                            if (value.length < 6) {
                              return 'Use pelo menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmation,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          decoration: _decoration(
                            label: 'Confirmar senha',
                            suffix: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Mostrar confirmação'
                                  : 'Ocultar confirmação',
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                                color: const Color(0xFF667068),
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 7),
                        CheckboxListTile(
                          value: _acceptedTerms,
                          onChanged: (value) => setState(
                            () => _acceptedTerms = value ?? false,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity:
                              const VisualDensity(horizontal: -4, vertical: -4),
                          title: const Text(
                            'Li e concordo com os termos e condições',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF505750),
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _register,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF244F43),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: const Color(0x66244F43),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Continuar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterBackgroundPainter extends CustomPainter {
  const _RegisterBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x18384F43)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 18; i++) {
      final y = size.height * (0.08 + i * 0.054);
      final path = Path()..moveTo(-20, y);

      for (var x = -20.0; x <= size.width + 30; x += 28) {
        final wave = 12 * (i.isEven ? 1 : -1);
        path.quadraticBezierTo(
          x + 14,
          y + wave,
          x + 28,
          y,
        );
      }
      canvas.drawPath(path, linePaint);
    }

    final glowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x00FFFFFF), Color(0x8DFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RegisterBackgroundPainter oldDelegate) => false;
}
