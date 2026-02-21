import 'package:flutter/material.dart';
import '../models/candidato_model.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

/// ChatViewModel — Gestiona el estado del chat con la IA.
///
/// Rol MVVM: ViewModel.
///
/// Patrón de contexto dinámico:
///   - [setCandidatos] recibe la lista real de candidatos desde HomeScreen.
///   - Al enviar cada mensaje, [_generarContexto] construye el prompt del
///     sistema en tiempo de ejecución con los datos actualizados de la BD.
///   - La UI muestra SIEMPRE solo el texto original del usuario.
///   - Al backend se envía: contexto_dinámico + texto_del_usuario.
class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  ChatViewModel({ChatRepository? repository})
    : _repository = repository ?? ChatRepository();

  // ── Estado del chat ─────────────────────────────────────────────
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedModel = 'gpt-4o';

  // ── Lista de candidatos (inyectada desde HomeScreen) ────────────
  List<Candidato> _candidatos = [];

  // ── Getters públicos ─────────────────────────────────────────────
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedModel => _selectedModel;

  // ═══════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════════════

  void setModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Recibe la lista actualizada de candidatos desde HomeScreen.
  /// Se llama justo antes de navegar al ChatScreen para que el contexto
  /// sea siempre consistente con los datos actuales de la base de datos.
  void setCandidatos(List<Candidato> candidatos) {
    _candidatos = List.unmodifiable(candidatos);
    // No notificamos listeners: este es un cambio de configuración, no de UI.
  }

  // ═══════════════════════════════════════════════════════════════════
  // GENERADOR DINÁMICO DE CONTEXTO ELECTORAL
  // ═══════════════════════════════════════════════════════════════════

  /// Genera el prompt de sistema en tiempo real con los candidatos actuales.
  ///
  /// Si la lista está vacía (ej: navegación directa sin pasar por Home),
  /// usa un contexto genérico institucional como fallback.
  String _generarContexto() {
    final buffer = StringBuffer();

    buffer.writeln(
      'Eres el Asistente Electoral oficial de la Escuela de Ingeniería de '
      'Sistemas de la Universidad Continental (Huancayo, Perú). '
      'Responde siempre en español, de forma clara, concisa y amigable. '
      'No inventes candidatos ni propuestas que no estén en la lista.',
    );
    buffer.writeln();

    if (_candidatos.isEmpty) {
      // Fallback: sin candidatos cargados
      buffer.writeln(
        'Actualmente no hay información de candidatos disponible. '
        'Invita al usuario a recargar la pantalla de inicio.',
      );
    } else {
      buffer.writeln(
        'CANDIDATOS OFICIALES REGISTRADOS EN EL SISTEMA (${_candidatos.length} en total):',
      );
      for (int i = 0; i < _candidatos.length; i++) {
        final c = _candidatos[i];
        buffer.write('• Lista N°${c.numeroLista ?? (i + 1)} — ${c.nombre}');
        if (c.cargo.isNotEmpty) buffer.write(' (${c.cargo})');
        buffer.writeln(':');
        if (c.propuesta.isNotEmpty) {
          buffer.writeln('  Propuesta: ${c.propuesta}');
        }
        buffer.writeln('  Votos actuales: ${c.totalVotos}');
      }
    }

    buffer.writeln();
    buffer.writeln('REGLAS DE VOTACIÓN:');
    buffer.writeln(
      '• Solo puede votar personal con correo @continental.edu.pe.',
    );
    buffer.writeln(
      '• La votación es presencial (GPS): debes estar dentro del campus.',
    );
    buffer.writeln('• Cada usuario puede votar una sola vez.');
    buffer.writeln();
    buffer.write('Pregunta del usuario: ');

    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════════
  // ENVIAR MENSAJE
  // ═══════════════════════════════════════════════════════════════════

  Future<void> sendMessage(String textoOriginal) async {
    if (textoOriginal.trim().isEmpty) return;

    // 1. Mostrar el texto ORIGINAL en la UI (sin contexto)
    _messages.add(
      ChatMessage(text: textoOriginal, isUser: true, timestamp: DateTime.now()),
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 2. Generar contexto dinámico en tiempo real y concatenar al mensaje
      final mensajeParaIA = _generarContexto() + textoOriginal;

      // 3. Enviar al backend — el usuario solo ve su texto original
      final respuestaIA = await _repository.sendMessage(
        mensajeParaIA,
        _selectedModel,
      );

      // 4. Mostrar respuesta de la IA
      _messages.add(respuestaIA);
    } catch (e) {
      _errorMessage = 'No se pudo conectar con la IA. Verifica tu conexión.';
      debugPrint('❌ [ChatViewModel] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
