import 'package:flutter/material.dart';
import '../models/candidato_model.dart';
import '../repositories/chat_repository.dart';
import '../services/location_service.dart';

/// Estados posibles del listado de candidatos.
enum EstadoCandidatos { inicial, cargando, cargado, error }

/// CandidatoViewModel — Gestiona el estado de candidatos y la lógica de voto.
///
/// Rol MVVM: ViewModel.
/// - Todas las variables booleanas se inicializan explícitamente en false.
/// - El GPS nunca lanza una pantalla roja: los errores se capturan y
///   se convierten en mensajes amigables vía [mensajeGps].
/// - La Vista solo observa y dispara eventos; nunca hace GPS ni HTTP.
class CandidatoViewModel extends ChangeNotifier {
  final CandidatoRepository _repository;
  final LocationService _locationService;

  CandidatoViewModel({
    CandidatoRepository? repository,
    LocationService? locationService,
  }) : _repository = repository ?? CandidatoRepository(),
       _locationService = locationService ?? LocationService() {
    cargarCandidatos();
  }

  // ─── Estado del listado ────────────────────────────────────────────
  EstadoCandidatos _estado = EstadoCandidatos.inicial;
  List<Candidato> _candidatos = [];
  String? _mensajeError;

  // ─── Estado de votación (todos inicializados explícitamente) ───────
  bool _estaCargando = false; // Carga de lista de candidatos en progreso
  bool _estaEnRango = false; // El usuario está dentro del campus (≤ 200 m)
  bool _haVotado = false; // El usuario ya emitió su voto en esta sesión
  bool _votando = false; // Hay una operación de voto en proceso
  String? _mensajeGps; // Mensaje GPS para la Vista (éxito o error)
  String? _mensajeVoto; // Último mensaje de voto (éxito o error)

  // ─── Getters públicos (solo lectura) ──────────────────────────────
  EstadoCandidatos get estado => _estado;
  List<Candidato> get candidatos => List.unmodifiable(_candidatos);
  String? get mensajeError => _mensajeError;

  // Variables booleanas garantizadas no-null (valor inicial = false)
  bool get estaCargando => _estaCargando; // Lista de candidatos
  bool get estaEnRango => _estaEnRango; // GPS dentro de 200 m
  bool get haVotado => _haVotado; // Votó en esta sesión
  bool get votando => _votando; // Operación de voto en proceso

  String? get mensajeGps => _mensajeGps;
  String? get mensajeVoto => _mensajeVoto;

  // ═══════════════════════════════════════════════════════════════════
  // CARGAR CANDIDATOS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> cargarCandidatos() async {
    _estaCargando = true;
    _estado = EstadoCandidatos.cargando;
    _mensajeError = null;
    notifyListeners();

    try {
      _candidatos = await _repository.obtenerCandidatos();
      _estado = EstadoCandidatos.cargado;
      print(
        '✅ [CandidatoViewModel] ${_candidatos.length} candidatos cargados.',
      );
    } catch (e) {
      _estado = EstadoCandidatos.error;
      _mensajeError = e.toString().replaceFirst('Exception: ', '');
      print('❌ [CandidatoViewModel] Error al cargar candidatos: $e');
    } finally {
      _estaCargando = false; // Siempre vuelve a false
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // EMITIR VOTO  — GPS → Backend
  // ═══════════════════════════════════════════════════════════════════

  /// Flujo de votación con protección total contra null/crashes:
  ///   1. Verifica GPS (bloque try-catch propio).
  ///      - Si falla: [estaEnRango] = false, [mensajeGps] = mensaje amigable.
  ///      - La app NO muestra pantalla roja.
  ///   2. Si está en rango, hace POST /api/votar al backend.
  ///   3. Si responde 400 (ya votó): [haVotado] = true, mensaje claro.
  Future<void> emitirVoto({
    required Candidato candidato,
    required String email,
  }) async {
    // Protección: no procesar si ya hay un voto en curso
    if (_votando) return;

    _votando = true;
    _mensajeGps = null;
    _mensajeVoto = null;
    _estaEnRango = false; // Resetear hasta confirmar posición
    notifyListeners();

    try {
      // ── BLOQUE GPS (nunca lanza pantalla roja) ─────────────────────
      double distancia = double.infinity; // Valor seguro por defecto

      try {
        distancia = await _locationService.calcularDistanciaAlCampus();
        _estaEnRango = distancia <= LocationService.radioPermitidoMetros;

        if (_estaEnRango) {
          _mensajeGps =
              '📍 Ubicación verificada (${distancia.toStringAsFixed(0)} m del campus).';
        } else {
          _mensajeGps =
              'Estás a ${distancia.toStringAsFixed(0)} m del campus. '
              'Máximo permitido: ${LocationService.radioPermitidoMetros.toInt()} m.';
        }

        print('📍 [CandidatoViewModel] $_mensajeGps');
      } catch (gpsError) {
        // GPS falló (null, permiso denegado, Chrome sin geolocation, etc.)
        _estaEnRango = false;
        _mensajeGps = gpsError
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('Exception', 'Error GPS');
        print('❌ [CandidatoViewModel] Error GPS: $gpsError');
        // No relanzamos → nunca hay pantalla roja por GPS
      }

      notifyListeners(); // Actualizar GPS state antes de continuar

      // ── VALIDACIÓN DE RANGO ────────────────────────────────────────
      if (!_estaEnRango) {
        // [_mensajeGps] ya tiene el mensaje para mostrar en SnackBar rojo
        return; // Salir sin votar — el finally limpiará _votando
      }

      // ── REGISTRO DE VOTO EN BACKEND ────────────────────────────────
      print('🗳️ [CandidatoViewModel] Enviando voto al backend...');
      await _repository.votar(usuarioEmail: email, candidatoId: candidato.id);

      // ── ÉXITO ──────────────────────────────────────────────────────
      _haVotado = true;
      _mensajeVoto = '¡Voto emitido exitosamente por ${candidato.nombre}!';
      print('✅ [CandidatoViewModel] $_mensajeVoto');
    } catch (e) {
      // Errores del backend (doble voto 400, conexión, etc.)
      _mensajeVoto = e.toString().replaceFirst('Exception: ', '');
      print('❌ [CandidatoViewModel] Error al votar: $e');
    } finally {
      _votando = false; // SIEMPRE vuelve a false — sin excepción
      notifyListeners();
    }
  }
}
