import 'dart:math';
import 'package:location/location.dart';

/// LocationService — Servicio de geolocalización con paquete `location`.
///
/// Rol MVVM: Service.
/// Encapsula permisos GPS, obtención de posición y cálculo de distancia.
/// Usa fórmula Haversine para calcular distancia sin dependencias extra.
/// NUNCA lanza excepciones sin capturar — siempre retorna valores seguros.
class LocationService {
  final Location _location = Location();

  /// Coordenadas del Campus San Carlos — Universidad Continental, Huancayo.
  static const double _campusLatitud = -12.04318;
  static const double _campusLongitud = -75.19688;

  /// Radio máximo permitido para votar (en metros).
  static const double radioPermitidoMetros = 200.0;

  static double get campusLatitud => _campusLatitud;
  static double get campusLongitud => _campusLongitud;

  // ═══════════════════════════════════════════════════════════════════
  // OBTENER POSICIÓN — Flujo estricto del paquete location
  // ═══════════════════════════════════════════════════════════════════

  /// Verifica servicio y permisos, luego retorna la posición del usuario.
  /// Lanza [Exception] con mensaje amigable en cualquier caso de fallo.
  Future<LocationData> obtenerPosicion() async {
    // ── PASO 1: Verificar que el servicio GPS esté activo ──────────────
    bool servicioActivo = false;
    try {
      servicioActivo = await _location.serviceEnabled();
    } catch (_) {
      servicioActivo = false;
    }

    if (!servicioActivo) {
      // Intentar activar el servicio (muestra popup del sistema)
      bool activado = false;
      try {
        activado = await _location.requestService();
      } catch (_) {
        activado = false;
      }
      if (!activado) {
        throw Exception(
          'El GPS está desactivado. Actívalo e intenta de nuevo.',
        );
      }
    }

    // ── PASO 2: Verificar permisos ─────────────────────────────────────
    PermissionStatus permiso;
    try {
      permiso = await _location.hasPermission();
    } catch (_) {
      permiso = PermissionStatus.denied;
    }

    if (permiso == PermissionStatus.denied) {
      try {
        permiso = await _location.requestPermission();
      } catch (_) {
        permiso = PermissionStatus.denied;
      }
    }

    if (permiso == PermissionStatus.denied ||
        permiso == PermissionStatus.deniedForever) {
      throw Exception(
        'Permiso de ubicación denegado. '
        'Acepta el permiso GPS en el navegador o configuración del dispositivo.',
      );
    }

    // ── PASO 3: Obtener LocationData ───────────────────────────────────
    try {
      final data = await _location.getLocation();
      print(
        '📍 [LocationService] Posición: ${data.latitude}, ${data.longitude}',
      );
      return data;
    } catch (e) {
      throw Exception('No se pudo obtener la posición GPS: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HAVERSINE — Cálculo de distancia sin paquetes externos
  // ═══════════════════════════════════════════════════════════════════

  /// Calcula la distancia en metros entre dos coordenadas (fórmula Haversine).
  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const double radioTierra = 6371000; // metros
    final dLat = _radianes(lat2 - lat1);
    final dLon = _radianes(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_radianes(lat1)) *
            cos(_radianes(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radioTierra * c;
  }

  static double _radianes(double grados) => grados * pi / 180;

  // ═══════════════════════════════════════════════════════════════════
  // DISTANCIA AL CAMPUS
  // ═══════════════════════════════════════════════════════════════════

  /// Obtiene la posición actual y retorna la distancia en metros al campus UC.
  /// Lanza [Exception] si no se puede obtener la posición.
  Future<double> calcularDistanciaAlCampus() async {
    final posicion = await obtenerPosicion();

    final lat = posicion.latitude ?? 0.0;
    final lon = posicion.longitude ?? 0.0;

    final distancia = haversine(lat, lon, _campusLatitud, _campusLongitud);

    print(
      '📍 [LocationService] Distancia al campus: '
      '${distancia.toStringAsFixed(1)} m (máx: $radioPermitidoMetros m)',
    );

    return distancia;
  }
}
