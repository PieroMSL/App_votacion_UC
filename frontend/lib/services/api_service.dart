import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/candidato_model.dart';

/// ApiService — Capa de comunicación HTTP con el backend FastAPI.
///
/// Rol MVVM: Service.
/// Todas las peticiones al backend pasan por aquí.
/// NUNCA habla directamente con Supabase.
///
/// Arquitectura de 3 capas:
///   Flutter (ApiService) → FastAPI (Render) → Supabase
class ApiService {
  /// URL base del backend desplegado en Render.
  static const String _backendUrl = 'https://backend-zh2s.onrender.com';

  // ─── Helper: headers con token Firebase opcional ───────────────────
  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════════════
  // CHAT  →  POST /api/chat
  // ═══════════════════════════════════════════════════════════════════

  /// Envía un mensaje al chatbot y retorna la respuesta de la IA como String.
  Future<String> sendMessage(String message, String model) async {
    final url = '$_backendUrl/api/chat';
    try {
      final headers = await _headers();
      print("📤 [ApiService.sendMessage] POST $url  modelo=$model");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'message': message, 'model': model}),
      );

      print("📥 [ApiService.sendMessage] status=${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['response'] == null) {
          throw Exception('Campo "response" vacío: ${response.body}');
        }
        print("✅ [ApiService.sendMessage] Respuesta IA recibida.");
        return data['response'] as String;
      } else {
        print(
          "❌ [ApiService.sendMessage] Error ${response.statusCode}: ${response.body}",
        );
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print("❌ [ApiService.sendMessage] Excepción: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CANDIDATOS  →  GET /api/candidatos
  // ═══════════════════════════════════════════════════════════════════

  /// Trae la lista de candidatos desde el backend.
  /// El backend consulta la tabla 'candidatos' de Supabase.
  Future<List<Candidato>> obtenerCandidatos() async {
    final url = '$_backendUrl/api/candidatos';
    try {
      final headers = await _headers();
      print("📤 [ApiService.obtenerCandidatos] GET $url");

      final response = await http.get(Uri.parse(url), headers: headers);
      print("📥 [ApiService.obtenerCandidatos] status=${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

        final candidatos = jsonList
            .map((json) => Candidato.fromJson(json as Map<String, dynamic>))
            .toList();

        print(
          "✅ [ApiService.obtenerCandidatos] ${candidatos.length} candidatos cargados.",
        );
        return candidatos;
      } else {
        throw Exception(
          'Error al obtener candidatos (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print("❌ [ApiService.obtenerCandidatos] Excepción: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // VOTAR  →  POST /api/votar
  // ═══════════════════════════════════════════════════════════════════

  /// Registra el voto del usuario en el backend.
  /// El backend inserta en la tabla 'votos' de Supabase.
  ///
  /// Lanza [Exception] con el mensaje del backend si:
  ///   - El usuario ya votó (HTTP 400) → "Ya has emitido tu voto..."
  ///   - Falla la conexión.
  Future<void> votar({
    required String usuarioEmail,
    required int candidatoId,
  }) async {
    final url = '$_backendUrl/api/votar';
    try {
      final headers = await _headers();
      print("📤 [ApiService.votar] POST $url  candidato=$candidatoId");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'usuario_email': usuarioEmail,
          'candidato_id': candidatoId,
        }),
      );

      print(
        "📥 [ApiService.votar] status=${response.statusCode}  body=${response.body}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ [ApiService.votar] Voto emitido correctamente.");
        return;
      }

      // Parsear el campo "detail" que devuelve FastAPI en los errores
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final detalle =
          (body['detail'] as String?) ?? 'Error desconocido al votar.';

      // HTTP 400 → usuario ya votó (UNIQUE constraint de Supabase)
      throw Exception(detalle);
    } catch (e) {
      print("❌ [ApiService.votar] Excepción: $e");
      rethrow;
    }
  }
}
