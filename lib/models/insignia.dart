// Insignia (logro): respuesta de GET /insignias y POST /insignias/evento.
// La API es la que decide el catálogo; aquí solo se lee tolerante.

class Insignia {
  final String codigo;
  final String titulo;
  final String descripcion;

  /// Clave del ícono (brote, hoja, flor, mapa, brujula, libro, escribir, gota, sol, corazon, nochebuena, jacaranda).
  final String icono;

  /// Plantas, Mapa, Blog, Racha o Fechas.
  final String categoria;

  /// Color de la medalla: Plantas, Mapa, Blog, Racha, rojo, navidad o morado.
  final String tono;
  final int meta;

  /// Avance actual, con tope en la meta.
  final int avance;

  /// 0..100.
  final int progreso;
  final bool desbloqueada;

  /// Fecha de obtención (ISO-8601) o null si está bloqueada.
  final DateTime? desbloqueadaEn;

  const Insignia({
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.categoria,
    required this.tono,
    required this.meta,
    required this.avance,
    required this.progreso,
    required this.desbloqueada,
    required this.desbloqueadaEn,
  });

  /// Tolera nulls, números como texto y fechas inválidas.
  factory Insignia.fromJson(Map<String, dynamic> json) {
    final meta = _entero(json['meta']);
    final avance = _entero(json['avance']);
    final progreso = _entero(json['progreso']);
    final codigo = _texto(json['codigo']);
    final categoria = _texto(json['categoria'], 'Plantas');
    return Insignia(
      codigo: codigo,
      titulo: _texto(json['titulo'], codigo),
      descripcion: _texto(json['descripcion']),
      icono: _texto(json['icono'], 'brote'),
      categoria: categoria,
      // Si la API no manda tono, la medalla usa la categoría.
      tono: _texto(json['tono'], categoria),
      meta: meta < 0 ? 0 : meta,
      avance: avance < 0 ? 0 : (meta > 0 && avance > meta ? meta : avance),
      progreso: progreso < 0 ? 0 : (progreso > 100 ? 100 : progreso),
      desbloqueada:
          json['desbloqueada'] == true ||
          json['desbloqueada']?.toString() == 'true',
      desbloqueadaEn: DateTime.tryParse(
        json['desbloqueadaEn']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  /// Avance (0..1) para la barra de progreso.
  double get avanceFraccion => progreso / 100;
}

String _texto(dynamic v, [String porDefecto = '']) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? porDefecto : t;
}

int _entero(dynamic v) {
  if (v is num) return v.isFinite ? v.toInt() : 0;
  if (v is String) {
    final t = v.trim();
    return int.tryParse(t) ?? (double.tryParse(t)?.toInt() ?? 0);
  }
  return 0;
}
