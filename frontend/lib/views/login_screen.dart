import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// LoginScreen — Pantalla de autenticación institucional.
///
/// Rol MVVM: View con lógica de presentación mínima (estado de loading/error).
/// Tema: hereda ThemeData global. Fondo claro, colores azul institucional.
/// Botones: mismo estilo FilledButton que los botones 'Votar por…' del Home.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isRegistering = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navegar() async {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _submit() async {
    // Validación básica de dominio institucional
    final email = _emailController.text.trim();
    if (!_isRegistering &&
        email.isNotEmpty &&
        !email.endsWith('@continental.edu.pe')) {
      setState(() {
        _errorMessage = 'Solo se permite el correo @continental.edu.pe';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegistering) {
        await _authService.signUpWithEmailPassword(
          email,
          _passwordController.text.trim(),
        );
      } else {
        await _authService.signInWithEmailPassword(
          email,
          _passwordController.text.trim(),
        );
      }
      await _navegar();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('] ')
            ? e.toString().split('] ')[1]
            : e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa el ThemeData global — sin backgroundColor forzado oscuro
    final colorScheme = Theme.of(context).colorScheme;
    const azul = Color(0xFF1A237E); // Color institucional = Home + Chat

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Fondo claro = Home + Chat
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo y título institucional ───────────────────
                  _buildHeader(azul, colorScheme),

                  const SizedBox(height: 36),

                  // ── Contenedor del formulario ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: azul.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Banner de error
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(),

                        // Campo Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo institucional',
                            hintText: 'usuario@continental.edu.pe',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: azul,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo Contraseña con toggle ver/ocultar
                        TextField(
                          controller: _passwordController,
                          obscureText: !_verPassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: azul,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _verPassword = !_verPassword),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),

                        // Botón principal — mismo estilo FilledButton que "Votar por…"
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: azul,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRegistering
                                      ? 'REGISTRARSE'
                                      : 'INICIAR SESIÓN',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                        ).animate().fadeIn().moveY(begin: 16),

                        // Divisor y botón de Google (solo en login)
                        if (!_isRegistering) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'O',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginConGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 26),
                            label: const Text('Continuar con Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: Colors.black87,
                            ),
                          ).animate().fadeIn().moveY(begin: 16),
                        ],
                      ],
                    ),
                  ),

                  // Toggle Registrarse / Iniciar sesión
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {
                      _isRegistering = !_isRegistering;
                      _errorMessage = null;
                    }),
                    child: Text(
                      _isRegistering
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate',
                      style: const TextStyle(color: azul),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color azul, ColorScheme colorScheme) {
    return Column(
      children: [
        // Ícono institucional
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: azul,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: azul.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.how_to_vote, size: 38, color: Colors.white),
        ).animate().scale(duration: 500.ms),
        const SizedBox(height: 20),
        Text(
          _isRegistering ? 'Crear Cuenta' : 'Elecciones 2025',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 6),
        if (!_isRegistering)
          Text(
            'Ingeniería de Sistemas — Universidad Continental',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Future<void> _loginConGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithGoogle();
      await _navegar();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
