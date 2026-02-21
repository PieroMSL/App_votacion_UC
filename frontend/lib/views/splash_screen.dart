import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// SplashScreen — Pantalla de presentación de la app.
///
/// Rol en MVVM: Es una View pura.
/// - No tiene lógica de negocio.
/// - Solo maneja la animación visual y delega la decisión de navegación
///   a FirebaseAuth (fuente de verdad de autenticación).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones de entrada
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward();

    // Después de 3 segundos, verificar estado de auth y navegar
    Future.delayed(const Duration(seconds: 3), _verificarYNavegar);
  }

  /// Verifica si el usuario ya está autenticado.
  /// Si está logueado → ChatScreen (pantalla principal).
  /// Si no está logueado → LoginScreen.
  Future<void> _verificarYNavegar() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    Widget destino;
    if (user != null) {
      // Usuario autenticado: ir a la pantalla principal de votaciones
      destino = const HomeScreen();
    } else {
      // Sin sesión activa: ir al login
      destino = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destino,
        transitionDuration: const Duration(milliseconds: 600),
        // Transición: fade suave
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // Azul profundo institucional
      body: Stack(
        children: [
          // Fondo con gradiente radial decorativo
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3949AB).withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Contenido central
          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(scale: _scaleAnim, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono representativo de votación
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.how_to_vote_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título principal
                  const Text(
                    'Elecciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Text(
                    'Sistemas UC',
                    style: TextStyle(
                      color: Color(0xFFAEB9FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Subtítulo institucional
                  Text(
                    'Universidad Continental',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Indicador de carga animado
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Versión en la esquina inferior
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0  •  @continental.edu.pe',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
