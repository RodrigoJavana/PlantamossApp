// Geografía del mapa de México: contornos SVG de los 32 estados (los mismos
// datos de la web) convertidos a Path, más nombres y capitales para el clima.
import 'dart:convert';
import 'dart:ui' show Path;

import 'package:flutter/services.dart' show rootBundle;

/// Área que se dibuja: los contornos ocupan x 0..700 e y 0..440; se deja un margen
/// para que el mapa quede centrado y sin espacio vacío (la web usa un lienzo más grande).
const double kMapaX = -12;
const double kMapaY = -12;
const double kMapaAncho = 724;
const double kMapaAlto = 464;

/// Un estado dibujable: nombre, clave normalizada y su contorno.
class EstadoMapa {
  final String nombre;

  /// Nombre sin acentos ni mayúsculas: sirve para cruzarlo con la API.
  final String clave;
  final Path path;

  const EstadoMapa({
    required this.nombre,
    required this.clave,
    required this.path,
  });
}

const Map<String, String> _acentos = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
};

/// Minúsculas, sin acentos y sin espacios extra (como normalizar() de la web).
String normalizarNombre(String texto) {
  var t = texto.toLowerCase().trim();
  _acentos.forEach((k, v) => t = t.replaceAll(k, v));
  return t.replaceAll(RegExp('[̀-ͯ]'), '');
}

final RegExp _tokenSvg = RegExp(
  r'[MLZmlz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);
final RegExp _letra = RegExp(r'[A-Za-z]');

/// Convierte un atributo "d" de SVG (comandos M, L y Z en absoluto) a Path.
Path parsearPathSvg(String d) {
  final path = Path();
  final tokens = _tokenSvg.allMatches(d).map((m) => m.group(0)!).toList();
  var cmd = '';
  var i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (_letra.hasMatch(t)) {
      i++;
      if (t == 'Z' || t == 'z') {
        path.close();
        cmd = '';
      } else {
        cmd = t.toUpperCase();
      }
      continue;
    }
    if (i + 1 >= tokens.length) break;
    final x = double.parse(t);
    final y = double.parse(tokens[i + 1]);
    i += 2;
    if (cmd == 'M') {
      path.moveTo(x, y);
      cmd = 'L'; // los pares que siguen a un M son líneas
    } else if (cmd == 'L') {
      path.lineTo(x, y);
    }
  }
  return path;
}

Future<List<EstadoMapa>>? _cacheMapa;

/// Carga (una sola vez) los 32 estados desde assets/data/mexico-estados.json.
Future<List<EstadoMapa>> cargarMapaMexico() {
  return _cacheMapa ??= _leerMapa().catchError((Object e) {
    _cacheMapa = null; // permite reintentar
    throw e;
  });
}

Future<List<EstadoMapa>> _leerMapa() async {
  final texto = await rootBundle.loadString('assets/data/mexico-estados.json');
  final lista = jsonDecode(texto) as List<dynamic>;
  return lista.map((e) {
    final m = e as Map<String, dynamic>;
    final nombre = m['nombre'] as String;
    return EstadoMapa(
      nombre: nombre,
      clave: normalizarNombre(nombre),
      path: parsearPathSvg(m['d'] as String),
    );
  }).toList();
}

/// Capital usada para el clima de cada estado (clave normalizada -> consulta).
const Map<String, String> kCapitalesClima = {
  'aguascalientes': 'Aguascalientes,MX',
  'baja california': 'Mexicali,MX',
  'baja california sur': 'La Paz,MX',
  'campeche': 'Campeche,MX',
  'chiapas': 'Tuxtla Gutierrez,MX',
  'chihuahua': 'Chihuahua,MX',
  'coahuila': 'Saltillo,MX',
  'colima': 'Colima,MX',
  'ciudad de mexico': 'Mexico City,MX',
  'durango': 'Durango,MX',
  'guanajuato': 'Guanajuato,MX',
  'guerrero': 'Chilpancingo,MX',
  'hidalgo': 'Pachuca,MX',
  'jalisco': 'Guadalajara,MX',
  'estado de mexico': 'Toluca,MX',
  'michoacan': 'Morelia,MX',
  'morelos': 'Cuernavaca,MX',
  'nayarit': 'Tepic,MX',
  'nuevo leon': 'Monterrey,MX',
  'oaxaca': 'Oaxaca,MX',
  'puebla': 'Puebla,MX',
  'queretaro': 'Queretaro,MX',
  'quintana roo': 'Chetumal,MX',
  'san luis potosi': 'San Luis Potosi,MX',
  'sinaloa': 'Culiacan,MX',
  'sonora': 'Hermosillo,MX',
  'tabasco': 'Villahermosa,MX',
  'tamaulipas': 'Ciudad Victoria,MX',
  'tlaxcala': 'Tlaxcala,MX',
  'veracruz': 'Xalapa,MX',
  'yucatan': 'Merida,MX',
  'zacatecas': 'Zacatecas,MX',
};

const Map<String, String> _capitalVisible = {
  'Mexico City': 'Ciudad de México',
  'Tuxtla Gutierrez': 'Tuxtla Gutiérrez',
  'Queretaro': 'Querétaro',
  'San Luis Potosi': 'San Luis Potosí',
  'Culiacan': 'Culiacán',
  'Merida': 'Mérida',
};

/// Consulta de clima para un estado (su capital, o el nombre si no hay capital).
String consultaClimaEstado(String nombreEstado) =>
    kCapitalesClima[normalizarNombre(nombreEstado)] ?? '$nombreEstado,MX';

/// Nombre visible de la capital del estado, o vacío si no se conoce.
String capitalEtiqueta(String nombreEstado) {
  final consulta = kCapitalesClima[normalizarNombre(nombreEstado)];
  if (consulta == null) return '';
  final ciudad = consulta.replaceFirst(RegExp(r',MX$'), '');
  return _capitalVisible[ciudad] ?? ciudad;
}
