import 'package:firebase_ai/firebase_ai.dart';

class AiService {
  // Declaramos el modelo y la sesión de chat
  late final GenerativeModel _model;
  late final ChatSession _chat;

  AiService() {
    // 1. Inicializamos usando la API para desarrolladores de Google AI a través de Firebase.
    // Esto evita el problema de App Check de Vertex y NO expone tu API Key.
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

    // 2. Iniciamos la sesión de chat para que la IA tenga "memoria" de los mensajes anteriores.
    _chat = _model.startChat();
  }

  /// Método para enviar un mensaje y recibir la respuesta manteniendo contexto
  Future<String> sendMessage(String textMessage) async {
    try {
      // Enviamos el mensaje a la sesión de chat existente
      final response = await _chat.sendMessage(Content.text(textMessage));

      // Retornamos el texto de la respuesta
      return response.text ?? 'No se pudo generar una respuesta.';
    } catch (e) {
      print('Error en IA: $e');
      return 'Hubo un error al procesar tu mensaje: $e';
    }
  }
}
