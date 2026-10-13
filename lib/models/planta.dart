// Modelos del catálogo: Planta (PlantaDto) y Estado (EstadoDto).

class Planta {
  final int idPlanta;
  final String nombrePlanta;
  final String? nombreCientifico;
  final String letraInicial;
  final int? idEstado;
  final String? nombreEstado;
  final String? urlImagen;
  final String tipoClima;
  final String luzSol;
  final String? riego;
  final String? descripcion;
  final String? cuidadosTexto;

  const Planta({
    required this.idPlanta,
    required this.nombrePlanta,
    this.nombreCientifico,
    required this.letraInicial,
    this.idEstado,
    this.nombreEstado,
    this.urlImagen,
    required this.tipoClima,
    required this.luzSol,
    this.riego,
    this.descripcion,
    this.cuidadosTexto,
  });

  factory Planta.fromJson(Map<String, dynamic> json) => Planta(
    idPlanta: (json['idPlanta'] as num?)?.toInt() ?? 0,
    nombrePlanta: json['nombrePlanta']?.toString() ?? '',
    nombreCientifico: json['nombreCientifico']?.toString(),
    letraInicial: json['letraInicial']?.toString() ?? '',
    idEstado: (json['idEstado'] as num?)?.toInt(),
    nombreEstado: json['nombreEstado']?.toString(),
    urlImagen: json['urlImagen']?.toString(),
    tipoClima: json['tipoClima']?.toString() ?? 'templado',
    luzSol: json['luzSol']?.toString() ?? 'sol_directo',
    riego: json['riego']?.toString(),
    descripcion: json['descripcion']?.toString(),
    cuidadosTexto: json['cuidadosTexto']?.toString(),
  );
}

/// Respuesta de GET /estados/{id}/plantas (EstadoConPlantasDto).
class EstadoConPlantas {
  final Estado estado;
  final List<Planta> plantas;

  const EstadoConPlantas({required this.estado, required this.plantas});

  factory EstadoConPlantas.fromJson(Map<String, dynamic> json) {
    final estado = json['estado'];
    final plantas = json['plantas'];
    return EstadoConPlantas(
      estado: Estado.fromJson(
        estado is Map<String, dynamic> ? estado : const {},
      ),
      plantas: plantas is List
          ? plantas
                .whereType<Map<String, dynamic>>()
                .map(Planta.fromJson)
                .toList()
          : const [],
    );
  }
}

class Estado {
  final int idEstado;
  final String nombreEstado;
  final String? climaPredominante;
  final int cantidadPlantas;

  const Estado({
    required this.idEstado,
    required this.nombreEstado,
    this.climaPredominante,
    this.cantidadPlantas = 0,
  });

  factory Estado.fromJson(Map<String, dynamic> json) => Estado(
    idEstado: (json['idEstado'] as num?)?.toInt() ?? 0,
    nombreEstado: json['nombreEstado']?.toString() ?? '',
    climaPredominante: json['climaPredominante']?.toString(),
    cantidadPlantas: (json['cantidadPlantas'] as num?)?.toInt() ?? 0,
  );
}
