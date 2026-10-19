// Racha de visitas diarias: cada día que el usuario entra a la app, su planta crece.
// Respuesta de GET /racha y POST /racha/registrar.

/// Nombres de las etapas, en el orden del número de etapa (0..5).
const List<String> kNombresEtapas = [
  'Semilla',
  'Brote',
  'Plántula',
  'Planta joven',
  'Planta adulta',
  'En flor',
];

/// Días seguidos necesarios para llegar a cada etapa.
const List<int> kDiasEtapa = [0, 1, 3, 7, 14, 30];

class Racha {
  final int rachaActual;
  final int rachaMaxima;
  final int totalDias;

  /// Último día registrado ("yyyy-MM-dd") o null.
  final String? ultimoDia;
  final bool registradaHoy;
  final int etapa;
  final String nombreEtapa;

  /// Días que faltan para la siguiente etapa (null en la etapa máxima).
  final int? diasSiguienteEtapa;

  const Racha({
    required this.rachaActual,
    required this.rachaMaxima,
    required this.totalDias,
    required this.ultimoDia,
    required this.registradaHoy,
    required this.etapa,
    required this.nombreEtapa,
    required this.diasSiguienteEtapa,
  });

  /// Tolera nulls, números como texto y números decimales.
  factory Racha.fromJson(Map<String, dynamic> json) {
    final maxEtapa = kNombresEtapas.length - 1;
    final e = _entero(json['etapa']);
    final etapa = e < 0 ? 0 : (e > maxEtapa ? maxEtapa : e);
    final nombre = json['nombreEtapa']?.toString().trim() ?? '';
    final ultimo = json['ultimoDia']?.toString().trim() ?? '';
    return Racha(
      rachaActual: _entero(json['rachaActual']),
      rachaMaxima: _entero(json['rachaMaxima']),
      totalDias: _entero(json['totalDias']),
      ultimoDia: ultimo.isEmpty ? null : ultimo,
      registradaHoy:
          json['registradaHoy'] == true ||
          json['registradaHoy']?.toString() == 'true',
      etapa: etapa,
      nombreEtapa: nombre.isEmpty ? kNombresEtapas[etapa] : nombre,
      diasSiguienteEtapa: _enteroONull(json['diasSiguienteEtapa']),
    );
  }

  bool get esEtapaMaxima => etapa >= kNombresEtapas.length - 1;

  /// Nombre de la siguiente etapa (null si ya está en la última).
  String? get nombreSiguienteEtapa =>
      esEtapaMaxima ? null : kNombresEtapas[etapa + 1];

  /// Avance (0..1) dentro de la etapa actual.
  double get progreso {
    final faltan = diasSiguienteEtapa;
    if (esEtapaMaxima || faltan == null) return 1;
    final tramo = kDiasEtapa[etapa + 1] - kDiasEtapa[etapa];
    if (tramo <= 0) return 1;
    final avance = (tramo - faltan) / tramo;
    return avance < 0 ? 0 : (avance > 1 ? 1 : avance);
  }
}

int _entero(dynamic v) => _enteroONull(v) ?? 0;

int? _enteroONull(dynamic v) {
  if (v is num) return v.isFinite ? v.toInt() : null;
  if (v is String) {
    final t = v.trim();
    final entero = int.tryParse(t);
    if (entero != null) return entero;
    final decimal = double.tryParse(t);
    return decimal != null && decimal.isFinite ? decimal.toInt() : null;
  }
  return null;
}
