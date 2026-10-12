// Modelos usados en Inicio: Noticia, CiudadClima y ClimaActual.

class Noticia {
  final int idNoticia;
  final String titulo;
  final String contenido;
  final String? urlImagen;
  final String? urlExterna;
  final bool destacada;
  final String? fechaPublicacion;

  const Noticia({
    required this.idNoticia,
    required this.titulo,
    required this.contenido,
    this.urlImagen,
    this.urlExterna,
    this.destacada = false,
    this.fechaPublicacion,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) => Noticia(
    idNoticia: (json['idNoticia'] as num?)?.toInt() ?? 0,
    titulo: json['titulo']?.toString() ?? '',
    contenido: json['contenido']?.toString() ?? '',
    urlImagen: json['urlImagen']?.toString(),
    urlExterna: json['urlExterna']?.toString(),
    destacada: json['destacada'] == true,
    fechaPublicacion: json['fechaPublicacion']?.toString(),
  );

  /// Fecha corta "8 oct 2026" (sin depender del paquete intl).
  String get fechaCorta {
    final f = DateTime.tryParse(fechaPublicacion ?? '')?.toLocal();
    if (f == null) return '';
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${f.day} ${meses[f.month - 1]} ${f.year}';
  }
}

/// Ciudad fijada por el usuario (GET /perfil/ciudades-clima).
class CiudadClima {
  final String id; // ej. "cdmx"
  final String ciudad;
  final String? estado;
  final String consulta;

  const CiudadClima({
    required this.id,
    required this.ciudad,
    this.estado,
    required this.consulta,
  });

  factory CiudadClima.fromJson(Map<String, dynamic> json) => CiudadClima(
    id: json['id']?.toString() ?? '',
    ciudad: json['ciudad']?.toString() ?? '',
    estado: json['estado']?.toString(),
    consulta: json['consulta']?.toString() ?? '',
  );
}

/// Respuesta de GET /externo/clima.
class ClimaActual {
  final double temp;
  final double sensacion;
  final int humedad;
  final double viento;
  final String descripcion;
  final String icono;

  const ClimaActual({
    required this.temp,
    required this.sensacion,
    required this.humedad,
    required this.viento,
    required this.descripcion,
    required this.icono,
  });

  /// Devuelve null si la API respondió `ok: false`.
  static ClimaActual? fromJson(Map<String, dynamic> json) {
    if (json['ok'] != true) return null;
    return ClimaActual(
      temp: (json['temp'] as num?)?.toDouble() ?? 0,
      sensacion: (json['sensacion'] as num?)?.toDouble() ?? 0,
      humedad: (json['humedad'] as num?)?.toInt() ?? 0,
      viento: (json['viento'] as num?)?.toDouble() ?? 0,
      descripcion: json['descripcion']?.toString() ?? '',
      icono: json['icono']?.toString() ?? '',
    );
  }
}

/// Ciudad + su clima (null si no hubo datos).
class ClimaCiudad {
  final CiudadClima ciudad;
  final ClimaActual? clima;
  const ClimaCiudad(this.ciudad, this.clima);
}
