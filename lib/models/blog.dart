// Modelos del mini blog: Blog (BlogDto) y el cuerpo de publicar/editar (BlogRequest).

const _meses = [
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

/// Fecha corta en español: "7 oct 2026".
String fechaCorta(DateTime? fecha) {
  if (fecha == null) return '';
  final f = fecha.toLocal();
  return '${f.day} ${_meses[f.month - 1]} ${f.year}';
}

String? _textoONulo(dynamic v) {
  if (v == null) return null;
  final t = v.toString().trim();
  return t.isEmpty ? null : t;
}

class Blog {
  final int idBlog;
  final int? idUsuario;
  final String titulo;
  final String contenido;
  final String? contenido2;
  final String? contenido3;
  final String? urlImagen;
  final String? urlImagen2;
  final String? urlImagen3;
  final String? urlImagen4;
  final String? urlImagen5;
  final DateTime? fechaPublicacion;
  final String autor;

  const Blog({
    required this.idBlog,
    this.idUsuario,
    required this.titulo,
    required this.contenido,
    this.contenido2,
    this.contenido3,
    this.urlImagen,
    this.urlImagen2,
    this.urlImagen3,
    this.urlImagen4,
    this.urlImagen5,
    this.fechaPublicacion,
    this.autor = '',
  });

  factory Blog.fromJson(Map<String, dynamic> json) => Blog(
    idBlog: (json['idBlog'] as num?)?.toInt() ?? 0,
    idUsuario: (json['idUsuario'] as num?)?.toInt(),
    titulo: _textoONulo(json['titulo']) ?? '',
    contenido: _textoONulo(json['contenido']) ?? '',
    contenido2: _textoONulo(json['contenido2']),
    contenido3: _textoONulo(json['contenido3']),
    urlImagen: _textoONulo(json['urlImagen']),
    urlImagen2: _textoONulo(json['urlImagen2']),
    urlImagen3: _textoONulo(json['urlImagen3']),
    urlImagen4: _textoONulo(json['urlImagen4']),
    urlImagen5: _textoONulo(json['urlImagen5']),
    fechaPublicacion: DateTime.tryParse(
      json['fechaPublicacion']?.toString() ?? '',
    ),
    autor: _textoONulo(json['autor']) ?? '',
  );

  /// Todas las imágenes que tiene el blog, en orden.
  List<String> get imagenes => [
    urlImagen,
    urlImagen2,
    urlImagen3,
    urlImagen4,
    urlImagen5,
  ].whereType<String>().toList();

  /// Párrafos con texto, en orden.
  List<String> get parrafos =>
      [contenido, contenido2, contenido3].whereType<String>().toList();

  String get autorMostrado => autor.isEmpty ? 'Anónimo' : autor;

  /// Inicio del contenido para la tarjeta del listado.
  String get extracto => contenido.length <= 120
      ? contenido
      : '${contenido.substring(0, 120).trimRight()}...';
}

/// Datos que se envían a POST/PUT /blogs (mismos campos que la web).
class BlogEntrada {
  final String titulo;
  final String contenido;
  final String? contenido2;
  final String? contenido3;
  final String urlImagen;

  /// Imágenes adicionales (hasta 4), ya sin vacíos.
  final List<String> extras;

  const BlogEntrada({
    required this.titulo,
    required this.contenido,
    this.contenido2,
    this.contenido3,
    required this.urlImagen,
    this.extras = const [],
  });

  Map<String, dynamic> toJson() => {
    'titulo': titulo.trim(),
    'contenido': contenido.trim(),
    'contenido2': _textoONulo(contenido2),
    'contenido3': _textoONulo(contenido3),
    'urlImagen': urlImagen.trim(),
    'urlImagen2': _extra(0),
    'urlImagen3': _extra(1),
    'urlImagen4': _extra(2),
    'urlImagen5': _extra(3),
  };

  String? _extra(int i) => i < extras.length ? _textoONulo(extras[i]) : null;
}
