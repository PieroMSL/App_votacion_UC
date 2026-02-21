import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../viewmodels/candidato_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../models/candidato_model.dart';
import 'login_screen.dart';
import 'chat_screen.dart';

/// HomeScreen — Pantalla principal de la app de Votaciones UC.
///
/// Rol MVVM: View pura.
/// Solo observa el CandidatoViewModel y renderiza el estado.
/// Toda la lógica de voto y GPS está en el ViewModel.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ══════════════════════════════════════════════════════════════════
  // ACCIONES
  // ══════════════════════════════════════════════════════════════════

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Dispara el voto y muestra el resultado en SnackBar.
  /// El ViewModel nunca relanza — escribe en mensajeVoto/mensajeGps.
  Future<void> _votar(BuildContext context, Candidato candidato) async {
    final viewModel = context.read<CandidatoViewModel>();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      _snack(context, '❌ Debes iniciar sesión primero.', esError: true);
      return;
    }

    await viewModel.emitirVoto(candidato: candidato, email: user.email!);
    if (!context.mounted) return;

    // Leer resultado desde getters del ViewModel (sin try-catch en la Vista)
    if (!viewModel.estaEnRango) {
      _snack(
        context,
        '❌ ${viewModel.mensajeGps ?? 'No se pudo verificar ubicación.'}',
        esError: true,
      );
      return;
    }
    if (viewModel.haVotado && viewModel.mensajeVoto != null) {
      _snack(context, '✅ ${viewModel.mensajeVoto}', esError: false);
      // Recargar candidatos para que el badge de votos se actualice
      viewModel.cargarCandidatos();
      return;
    }
    if (viewModel.mensajeVoto != null) {
      _snack(context, '❌ ${viewModel.mensajeVoto}', esError: true);
    }
  }

  void _snack(BuildContext context, String msg, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: esError
            ? Theme.of(context).colorScheme.error
            : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final viewModel = context.watch<CandidatoViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: _buildAppBar(context, user, viewModel),
      body: Column(
        children: [
          // Barra de progreso durante votación
          if (viewModel.votando)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.transparent,
            ),
          Expanded(child: _buildBody(context, viewModel)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Inyectar la lista actualizada de candidatos al ChatViewModel
          // ANTES de navegar, para que el contexto del asistente sea dinámico.
          context.read<ChatViewModel>().setCandidatos(viewModel.candidatos);
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
        },
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Consultar IA'),
      ),
    );
  }

  // ── AppBar con foto de perfil del usuario ──────────────────────────
  AppBar _buildAppBar(
    BuildContext context,
    User? user,
    CandidatoViewModel viewModel,
  ) {
    // Inicial para avatar por defecto
    final inicial =
        (user?.displayName?.isNotEmpty == true
                ? user!.displayName![0]
                : user?.email?[0] ?? 'U')
            .toUpperCase();

    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      title: Row(
        children: [
          // Logo institucional
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.how_to_vote, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elecciones 2025',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Ing. de Sistemas — UC',
                style: TextStyle(fontSize: 10, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Botón de recarga
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Actualizar candidatos',
          onPressed: viewModel.estaCargando
              ? null
              : () => viewModel.cargarCandidatos(),
        ),
        // Menú de usuario con FOTO DE PERFIL
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'logout') _cerrarSesion(context);
            },
            child: _UserAvatar(user: user, inicial: inicial),
            itemBuilder: (_) => [
              // Cabecera del menú con info del usuario
              PopupMenuItem(
                enabled: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _UserAvatar(user: user, inicial: inicial, radius: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Usuario',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Cuerpo reactivo al estado del ViewModel ────────────────────────
  Widget _buildBody(BuildContext context, CandidatoViewModel viewModel) {
    switch (viewModel.estado) {
      case EstadoCandidatos.inicial:
      case EstadoCandidatos.cargando:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando candidatos...'),
            ],
          ),
        );

      case EstadoCandidatos.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.signal_wifi_off_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar la lista',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.mensajeError ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => viewModel.cargarCandidatos(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );

      case EstadoCandidatos.cargado:
        if (viewModel.candidatos.isEmpty) {
          return const Center(child: Text('No hay candidatos registrados.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: viewModel.candidatos.length,
          itemBuilder: (context, i) => _CandidatoCard(
            candidato: viewModel.candidatos[i],
            numero: i + 1,
            votando: viewModel.votando,
            haVotado: viewModel.haVotado,
            onVotar: () => _votar(context, viewModel.candidatos[i]),
          ),
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET: Avatar del usuario (reutilizable en AppBar y menú)
// ════════════════════════════════════════════════════════════════════

class _UserAvatar extends StatelessWidget {
  final User? user;
  final String inicial;
  final double radius;

  const _UserAvatar({
    required this.user,
    required this.inicial,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl),
        // Fallback si la imagen de perfil no carga
        onBackgroundImageError: (_, __) {},
        backgroundColor: Colors.white24,
        child: null,
      );
    }

    // Sin foto: círculo con inicial
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: Text(
        inicial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET: Tarjeta de candidato — Diseño premium
// ════════════════════════════════════════════════════════════════════

class _CandidatoCard extends StatelessWidget {
  final Candidato candidato;
  final int numero;
  final bool votando;
  final bool haVotado;
  final VoidCallback onVotar;

  const _CandidatoCard({
    required this.candidato,
    required this.numero,
    required this.votando,
    required this.haVotado,
    required this.onVotar,
  });

  // Colores por posición en la lista
  static const List<Color> _colores = [
    Color(0xFF1A237E), // Azul institucional
    Color(0xFF00695C), // Verde oscuro
    Color(0xFFB71C1C), // Rojo oscuro
    Color(0xFF4A148C), // Púrpura oscuro
    Color(0xFFE65100), // Naranja oscuro
    Color(0xFF1B5E20), // Verde bosque
  ];

  Color get _colorBase => _colores[(numero - 1) % _colores.length];

  @override
  Widget build(BuildContext context) {
    final inicial = candidato.nombre.isNotEmpty
        ? candidato.nombre[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colorBase.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Franja superior de color ─────────────────────────────
            Container(height: 6, color: _colorBase),

            // ── Cuerpo de la tarjeta ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Imagen del candidato ──────────────────────
                      _buildAvatar(inicial),
                      const SizedBox(width: 14),

                      // ── Información del candidato ─────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Número de lista
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _colorBase.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Lista N° ${candidato.numeroLista ?? numero}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _colorBase,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Nombre del candidato — color negro explícito para contraste sobre fondo blanco
                            Text(
                              candidato.nombre,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Cargo
                            Text(
                              candidato.cargo,
                              style: TextStyle(
                                fontSize: 12,
                                color: _colorBase,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Badge de VOTOS (prominente) ───────────────
                      _VoteBadge(
                        totalVotos: candidato.totalVotos,
                        color: _colorBase,
                      ),
                    ],
                  ),

                  // ── Propuesta ────────────────────────────────────────
                  if (candidato.propuesta.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              candidato.propuesta,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Botón de VOTO ─────────────────────────────────────
                  SizedBox(width: double.infinity, child: _buildBotonVoto()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Avatar del candidato:
  //   - Con fotoUrl válida → CircleAvatar con NetworkImage
  //   - Sin foto ó imagen rota → icono genérico de persona
  Widget _buildAvatar(String inicial) {
    final tieneUrl = candidato.fotoUrl != null && candidato.fotoUrl!.isNotEmpty;

    return _AvatarCandidato(
      fotoUrl: tieneUrl ? candidato.fotoUrl! : null,
      colorBase: _colorBase,
      inicial: inicial,
      size: 72,
    );
  }

  Widget _buildBotonVoto() {
    // Si ya votó en esta sesión → mostrar confirmación
    if (haVotado) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              'Voto emitido',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: votando ? null : onVotar,
      icon: votando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.how_to_vote_outlined, size: 18),
      label: Text(
        votando
            ? 'Verificando ubicación...'
            : 'Votar por ${candidato.nombre.split(' ').first}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _colorBase,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET: Badge de votos — Prominente y destacado
// ════════════════════════════════════════════════════════════════════

class _VoteBadge extends StatelessWidget {
  final int totalVotos;
  final Color color;

  const _VoteBadge({required this.totalVotos, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.how_to_vote, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            '$totalVotos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          Text(
            totalVotos == 1 ? 'voto' : 'votos',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET: Avatar del Candidato — CircleAvatar con manejo de errores
//
// Estrategia:
//   1. Si fotoUrl es válida → CircleAvatar con backgroundImage NetworkImage
//   2. Si la imagen rompe (onBackgroundImageError) → muestra Icons.person
//   3. Si no hay fotoUrl → muestra Icons.person directamente
// ════════════════════════════════════════════════════════════════════

class _AvatarCandidato extends StatefulWidget {
  final String? fotoUrl;
  final Color colorBase;
  final String inicial;
  final double size;

  const _AvatarCandidato({
    required this.fotoUrl,
    required this.colorBase,
    required this.inicial,
    this.size = 72,
  });

  @override
  State<_AvatarCandidato> createState() => _AvatarCandidatoState();
}

class _AvatarCandidatoState extends State<_AvatarCandidato> {
  bool _imagenFallo = false;

  @override
  Widget build(BuildContext context) {
    final double radius = widget.size / 2;
    final tieneUrl =
        widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty && !_imagenFallo;

    return CircleAvatar(
      radius: radius,
      backgroundColor: widget.colorBase,
      // Imagen de red cuando hay URL válida y no ha fallado
      backgroundImage: tieneUrl ? NetworkImage(widget.fotoUrl!) : null,
      // Si la imagen de red falla → setState pone _imagenFallo = true
      // y CircleAvatar pasa a mostrar el child (icono genérico)
      onBackgroundImageError: tieneUrl
          ? (_, __) {
              if (mounted) setState(() => _imagenFallo = true);
            }
          : null,
      // Child aparece solo cuando no hay imagen (tieneUrl = false)
      child: tieneUrl
          ? null
          : Icon(
              Icons.person,
              size: radius * 1.1,
              color: Colors.white.withOpacity(0.85),
            ),
    );
  }
}
