/// Candidato — Modelo de datos (entidad de dominio).
///
/// Rol MVVM: Model puro.
/// Representa un candidato tal como viene del backend.
/// El método fromJson debe coincidir EXACTAMENTE con la respuesta de /api/candidatos.
class Candidato {
  final int id;
  final String nombre;
  final String cargo;
  final String propuesta;
  final String? fotoUrl; // foto_url en Supabase
  final int? numeroLista; // numero_lista en Supabase
  final int totalVotos; // total_votos calculado por el backend (nunca null)

  const Candidato({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.propuesta,
    this.fotoUrl,
    this.numeroLista,
    this.totalVotos = 0, // Valor por defecto: 0
  });

  /// Construye un Candidato desde el JSON que devuelve el backend.
  ///
  /// El backend agrega total_votos = COUNT(votos por candidato).
  /// Si el campo no viene o viene null → se usa 0 como fallback.
  factory Candidato.fromJson(Map<String, dynamic> json) {
    return Candidato(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      cargo: (json['cargo'] as String?) ?? 'Delegado de Sistemas',
      propuesta: (json['propuesta'] as String?) ?? '',
      fotoUrl: json['foto_url'] as String?,
      numeroLista: json['numero_lista'] as int?,
      // Convierte a int y garantiza 0 si viene null (nunca falla)
      totalVotos: (json['total_votos'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'cargo': cargo,
    'propuesta': propuesta,
    'foto_url': fotoUrl,
    'numero_lista': numeroLista,
    'total_votos': totalVotos,
  };
}
