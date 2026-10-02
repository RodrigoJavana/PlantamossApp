// Registro (logs) mínimo de la app.
//
// - Niveles: depuracion < info < aviso < error.
// - En debug imprime con debugPrint.
// - En release solo guarda en memoria (últimas 100 líneas) avisos y errores,
//   siempre saneados: nunca tokens ni contraseñas; los correos van enmascarados.
import 'package:flutter/foundation.dart';

enum NivelRegistro { depuracion, info, aviso, error }

class Registro {
  Registro._();

  /// Últimas líneas registradas (para diagnóstico, ya saneadas).
  static final List<String> historial = [];
  static const _maxHistorial = 100;

  /// Permite forzar el modo release en pruebas.
  @visibleForTesting
  static bool? forzarRelease;

  static bool get _esRelease => forzarRelease ?? kReleaseMode;

  static void depuracion(String origen, String mensaje) =>
      _escribir(NivelRegistro.depuracion, origen, mensaje);
  static void info(String origen, String mensaje) =>
      _escribir(NivelRegistro.info, origen, mensaje);
  static void aviso(String origen, String mensaje) =>
      _escribir(NivelRegistro.aviso, origen, mensaje);

  static void error(
    String origen,
    String mensaje, [
    Object? error,
    StackTrace? pila,
  ]) {
    final detalle = error == null
        ? mensaje
        : '$mensaje | ${error.runtimeType}: $error';
    _escribir(NivelRegistro.error, origen, detalle, pila);
  }

  static void _escribir(
    NivelRegistro nivel,
    String origen,
    String mensaje, [
    StackTrace? pila,
  ]) {
    // En release no se registra nada por debajo de "aviso".
    if (_esRelease && nivel.index < NivelRegistro.aviso.index) return;

    final linea = '[${nivel.name.toUpperCase()}] $origen: ${sanear(mensaje)}';
    historial.add(linea);
    if (historial.length > _maxHistorial) historial.removeAt(0);

    if (!_esRelease) {
      debugPrint(linea);
      if (pila != null) debugPrint(pila.toString());
    }
  }

  static final _reJwt = RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+');
  static final _reBearer = RegExp(r'Bearer\s+\S+', caseSensitive: false);
  static final _reCampoSecreto = RegExp(
    r'("?(?:password|contrasena|token|refreshToken|access_token)"?\s*[:=]\s*)("[^"]*"|[^\s,}&]+)',
    caseSensitive: false,
  );
  static final _reEmail = RegExp(
    r'([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+\.[A-Za-z]{2,})',
  );

  /// Quita tokens/contraseñas y enmascara correos ("admin@x.com" -> "a***@x.com").
  static String sanear(String texto) {
    var t = texto;
    t = t.replaceAll(_reBearer, 'Bearer ***');
    t = t.replaceAll(_reJwt, '***');
    t = t.replaceAllMapped(_reCampoSecreto, (m) => '${m[1]}***');
    t = t.replaceAllMapped(_reEmail, (m) => '${m[1]}***@${m[2]}');
    return t;
  }
}
