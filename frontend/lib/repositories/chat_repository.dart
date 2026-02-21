import '../services/api_service.dart';
import '../services/ai_service.dart';
import '../models/candidato_model.dart';
import '../models/chat_message.dart';

/// CandidatoRepository — Abstracción de acceso a datos para candidatos.
///
/// Rol MVVM: Repository.
/// Centraliza el origen de los datos. Si mañana cambia la fuente
/// (de backend REST a GraphQL, por ejemplo), solo se modifica aquí.
class CandidatoRepository {
  final ApiService _apiService;

  CandidatoRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Obtiene la lista de candidatos del backend.
  Future<List<Candidato>> obtenerCandidatos() {
    return _apiService.obtenerCandidatos();
  }

  /// Registra el voto en el backend → Supabase.
  /// Lanza Exception con el mensaje del backend si el usuario ya votó.
  Future<void> votar({required String usuarioEmail, required int candidatoId}) {
    return _apiService.votar(
      usuarioEmail: usuarioEmail,
      candidatoId: candidatoId,
    );
  }
}

/// ChatRepository — Abstracción de acceso a datos para el chat.
class ChatRepository {
  final ApiService _apiService;
  final AiService _aiService;

  ChatRepository({ApiService? apiService, AiService? aiService})
    : _apiService = apiService ?? ApiService(),
      _aiService = aiService ?? AiService();

  Future<ChatMessage> sendMessage(String message, String model) async {
    try {
      String responseText;

      // Si el modelo es Gemini, usar el SDK de Firebase directamente
      if (model.contains('gemini')) {
        responseText = await _aiService.sendMessage(message);
      } else {
        // Para GPT-4o, DeepSeek y otros: usar el backend
        responseText = await _apiService.sendMessage(message, model);
      }

      return ChatMessage.fromApiResponse(responseText);
    } catch (e) {
      rethrow;
    }
  }
}
