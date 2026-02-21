import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// ChatScreen — Pantalla del Asistente Electoral IA.
///
/// Rol MVVM: View pura.
/// AppBar unificado con el color institucional del HomeScreen (0xFF1A237E).
/// SafeArea protege el contenido de la barra de estado.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatViewModel>().sendMessage(text);
    _controller.clear();

    // Deslizar al último mensaje tras el frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();

    return Scaffold(
      // ── Fondo: hereda del ThemeData global (claro) ─────────────────
      backgroundColor: const Color(0xFFF0F2F5),

      // ── AppBar institucional — igual al HomeScreen ─────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente Electoral',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'IA — Universidad Continental',
                  style: TextStyle(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        // Selector de modelo en el AppBar
        actions: [
          _ModelSelector(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'clear') {
                context.read<ChatViewModel>().clearChat();
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro de que quieres salir?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Limpiar chat'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Cuerpo con SafeArea ─────────────────────────────────────────
      body: SafeArea(
        child: Column(
          children: [
            // Lista de mensajes
            Expanded(
              child: viewModel.messages.isEmpty
                  ? _EmptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount:
                          viewModel.messages.length +
                          (viewModel.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == viewModel.messages.length) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(
                          message: viewModel.messages[index],
                        );
                      },
                    ),
            ),

            // Banner de error
            if (viewModel.errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.errorContainer,
                width: double.infinity,
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(),

            // Área de input
            _InputArea(
              controller: _controller,
              onSend: _sendMessage,
              enabled: !viewModel.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selector de modelo en el AppBar ────────────────────────────────────
class _ModelSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: DropdownButton<String>(
        value: viewModel.selectedModel,
        dropdownColor: const Color(0xFF283593),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.expand_more, color: Colors.white70, size: 18),
        items: const [
          DropdownMenuItem(value: 'gpt-4o', child: Text('GPT-4o')),
          DropdownMenuItem(
            value: 'DeepSeek-V3-0324',
            child: Text('DeepSeek V3'),
          ),
          DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('Gemini')),
        ],
        onChanged: (value) {
          if (value != null) {
            context.read<ChatViewModel>().setModel(value);
          }
        },
      ),
    );
  }
}

// ── Estado vacío del chat ───────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1A237E);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Asistente Electoral',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pregúntame sobre los candidatos\no el proceso de votación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ).animate().fade().scale(),
    );
  }
}

// ── Burbuja de mensaje ─────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    const azul = Color(0xFF1A237E);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          // Usuario: azul institucional / IA: blanco con sombra suave
          color: isUser ? azul : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  code: theme.textTheme.bodyMedium?.copyWith(
                    backgroundColor: const Color(0xFFF0F2F5),
                    color: const Color(0xFF1A237E),
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                ),
              ),
      ),
    ).animate().fade().slideY(begin: 0.2, end: 0, duration: 250.ms);
  }
}

// ── Indicador "IA escribiendo…" ────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFF1A237E).withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'IA escribiendo...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade();
  }
}

// ── Área de texto e input ──────────────────────────────────────────────
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputArea({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                // Color oscuro explícito — contraste sobre fondo claro 0xFFF0F2F5
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Consulta sobre los candidatos...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Botón de enviar — mismo color azul que los botones de Votar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton(
              heroTag: 'send_btn',
              onPressed: enabled ? onSend : null,
              elevation: enabled ? 3 : 0,
              backgroundColor: enabled
                  ? const Color(0xFF1A237E) // azul institucional = Home
                  : Colors.grey.shade300,
              child: Icon(
                Icons.send_rounded,
                color: enabled ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
