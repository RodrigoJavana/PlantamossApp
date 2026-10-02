// Cliente HTTP único para hablar con la API .NET de Plantamoss.
//
// - Servidor configurable: esquema (http/https) + IP + puerto, o URL completa.
// - Agrega el token JWT en el header Authorization.
// - Ante un 401 renueva la sesión UNA vez con /auth/refresh (con candado para
//   que las peticiones simultáneas esperen el mismo refresh) y reintenta.
// - Convierte los errores de la API ({ message, errors? }) en ApiException.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constantes.dart';
import 'registro.dart';

const String kMsgSesionExpirada = 'Tu sesión expiró. Inicia sesión de nuevo.';
const String kMsgErrorGenerico = 'No se pudo cargar. Intenta de nuevo.';

/// Convierte cualquier error en un texto corto para mostrar en pantalla.
/// Los errores técnicos se registran y NO se muestran al usuario.
String mensajeDeError(Object e, [StackTrace? pila]) {
  if (e is ApiException) return e.message;
  Registro.error('UI', 'Error inesperado', e, pila);
  return kMsgErrorGenerico;
}

/// Error legible devuelto por la API (o por la red).
class ApiException implements Exception {
  final String message;
  final int? status;

  /// Errores por campo (422/400): { "email": "Correo inválido." }.
  final Map<String, String> errores;

  const ApiException(this.message, {this.status, this.errores = const {}});

  /// Error de un campo (busca sin importar mayúsculas).
  String? errorDe(String campo) {
    for (final e in errores.entries) {
      if (e.key.toLowerCase() == campo.toLowerCase()) return e.value;
    }
    return null;
  }

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._() : cliente = http.Client();

  /// Cliente aislado para pruebas (con un http.Client simulado).
  @visibleForTesting
  ApiClient.prueba(this.cliente);

  /// Instancia única (patrón singleton) para toda la app.
  static final ApiClient instancia = ApiClient._();

  /// Tiempo máximo de espera de cada petición.
  static const timeout = Duration(seconds: 15);

  /// Cliente http. Se puede reemplazar en las pruebas.
  http.Client cliente;

  String esquema = kEsquemaPorDefecto;
  String ip = kIpPorDefecto;
  String puerto = kPuertoPorDefecto;

  /// URL completa (por defecto la nube). Si no está vacía reemplaza esquema/ip/puerto.
  /// Vacía = usar esquema/ip/puerto (red local).
  String urlCompleta = kUrlNube;

  /// Token JWT de acceso y refresh token (en memoria; se guardan cifrados
  /// en AlmacenSeguro).
  String? token;
  String? refreshToken;

  /// Se llama al renovar tokens (para guardarlos): recibe la respuesta de
  /// /auth/refresh { token, refreshToken, expiresIn, user }.
  Future<void> Function(Map<String, dynamic> datos)? alRenovarTokens;

  /// Se llama cuando la sesión no se pudo renovar (regresar al login).
  VoidCallback? alExpirarSesion;

  /// Notifica a la UI cuando cambia el servidor.
  final ValueNotifier<String> servidorTexto = ValueNotifier('');

  /// Refresh en curso (candado).
  Future<bool>? _refrescoEnCurso;

  // ---------------- Servidor ----------------

  static String construirBaseUrl({
    String esquema = kEsquemaPorDefecto,
    String ip = kIpPorDefecto,
    String puerto = kPuertoPorDefecto,
    String url = '',
  }) {
    final u = url.trim();
    if (u.isNotEmpty) {
      var limpio = u.replaceAll(RegExp(r'/+$'), '');
      if (!limpio.toLowerCase().endsWith('/api')) limpio = '$limpio/api';
      return limpio;
    }
    return '${esquema.trim()}://${ip.trim()}:${puerto.trim()}/api';
  }

  String get baseUrl => construirBaseUrl(
    esquema: esquema,
    ip: ip,
    puerto: puerto,
    url: urlCompleta,
  );

  /// true si la conexión va cifrada (https).
  bool get cifrado => baseUrl.startsWith('https://');

  /// Texto corto para mostrar en pantalla: host (y puerto), sin esquema ni /api.
  /// Ej.: "api.plantamoss.online" o "10.16.0.72:5080".
  static String textoServidor(String baseUrl) => baseUrl
      .replaceAll(RegExp(r'/api$'), '')
      .replaceFirst(RegExp(r'^https?://'), '');

  /// Lee el servidor guardado. Si el usuario nunca guardó uno, usa la nube.
  /// En la versión release SIEMPRE se usa la nube: el usuario final no puede
  /// (ni necesita) cambiar ni ver el servidor. Solo en debug se respeta el guardado.
  Future<void> cargarServidor() async {
    if (kReleaseMode) {
      esquema = kEsquemaPorDefecto;
      urlCompleta = kUrlNube;
      servidorTexto.value = textoServidor(baseUrl);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    esquema = prefs.getString(ClavesPrefs.esquema) ?? kEsquemaPorDefecto;
    ip = prefs.getString(ClavesPrefs.ip) ?? kIpPorDefecto;
    puerto = prefs.getString(ClavesPrefs.puerto) ?? kPuertoPorDefecto;
    urlCompleta = prefs.getString(ClavesPrefs.urlCompleta) ?? kUrlNube;
    if (esquema != 'http' && esquema != 'https') esquema = kEsquemaPorDefecto;
    servidorTexto.value = textoServidor(baseUrl);
  }

  /// Guarda el servidor en shared_preferences (no es dato sensible).
  Future<void> guardarServidor({
    required String esquema,
    required String ip,
    required String puerto,
    String url = '',
  }) async {
    this.esquema = esquema;
    this.ip = ip.trim();
    this.puerto = puerto.trim();
    urlCompleta = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ClavesPrefs.esquema, this.esquema);
    await prefs.setString(ClavesPrefs.ip, this.ip);
    await prefs.setString(ClavesPrefs.puerto, this.puerto);
    await prefs.setString(ClavesPrefs.urlCompleta, urlCompleta);
    servidorTexto.value = textoServidor(baseUrl);
    Registro.info('Api', 'Servidor cambiado a ${servidorTexto.value}');
  }

  /// Prueba si hay API en esa URL base (GET /estados). Lanza ApiException si falla.
  Future<void> probarConexion(String base) async {
    final uri = Uri.parse('$base/estados');
    try {
      final r = await cliente.get(uri).timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) {
        throw ApiException(
          'El servidor respondió ${r.statusCode}.',
          status: r.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } catch (e) {
      Registro.aviso('Api', 'Prueba de conexión fallida: ${e.runtimeType}');
      throw const ApiException('Sin conexión con ese servidor.');
    }
  }

  // ---------------- Peticiones ----------------

  Map<String, String> _headers() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String ruta, [Map<String, String?>? query]) {
    final limpio = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.trim().isNotEmpty) limpio[k] = v.trim();
    });
    final uri = Uri.parse('$baseUrl$ruta');
    return limpio.isEmpty ? uri : uri.replace(queryParameters: limpio);
  }

  Future<dynamic> get(String ruta, {Map<String, String?>? query}) =>
      _enviar('GET', ruta, query: query);

  Future<dynamic> post(String ruta, Map<String, dynamic> body) =>
      _enviar('POST', ruta, body: body);

  Future<dynamic> put(String ruta, Map<String, dynamic> body) =>
      _enviar('PUT', ruta, body: body);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  static bool _esRutaAuth(String ruta) =>
      ruta == '/auth/login' ||
      ruta == '/auth/register' ||
      ruta == '/auth/refresh' ||
      ruta.startsWith('/auth/logout');

  Future<http.Response> _hacer(
    String metodo,
    String ruta,
    Map<String, String?>? query,
    Map<String, dynamic>? body,
  ) async {
    try {
      final uri = _uri(ruta, query);
      final cuerpo = jsonEncode(body ?? {});
      final peticion = switch (metodo) {
        'POST' => cliente.post(uri, headers: _headers(), body: cuerpo),
        'PUT' => cliente.put(uri, headers: _headers(), body: cuerpo),
        'DELETE' => cliente.delete(uri, headers: _headers()),
        _ => cliente.get(uri, headers: _headers()),
      };
      final r = await peticion.timeout(timeout);
      Registro.depuracion('Api', '$metodo $ruta -> ${r.statusCode}');
      return r;
    } on TimeoutException {
      Registro.aviso('Api', '$metodo $ruta: tiempo agotado');
      throw const ApiException(
        'El servidor tardó demasiado (más de 15 s). Revisa tu conexión.',
      );
    } catch (e) {
      Registro.aviso('Api', '$metodo $ruta: sin conexión (${e.runtimeType})');
      throw const ApiException('Sin conexión con el servidor.');
    }
  }

  /// Ejecuta la petición, renueva la sesión si hace falta y procesa la respuesta.
  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Map<String, String?>? query,
    Map<String, dynamic>? body,
    bool reintento = false,
  }) async {
    final tokenUsado = token;
    final r = await _hacer(metodo, ruta, query, body);

    if (r.statusCode == 401 && tokenUsado != null && !_esRutaAuth(ruta)) {
      if (!reintento && await _renovar(tokenUsado)) {
        return _enviar(metodo, ruta, query: query, body: body, reintento: true);
      }
      _expirar();
      throw const ApiException(kMsgSesionExpirada, status: 401);
    }

    final cuerpo = r.body.isEmpty ? null : _decodificar(r, ruta);
    if (r.statusCode >= 200 && r.statusCode < 300) return cuerpo;
    throw _excepcion(cuerpo, r.statusCode);
  }

  /// Renueva el token. Si ya hay un refresh en curso, espera ese mismo.
  Future<bool> _renovar(String tokenUsado) {
    // Otra petición ya renovó el token mientras esta esperaba.
    if (token != null && token != tokenUsado) return Future.value(true);
    return _refrescoEnCurso ??= _refrescar().whenComplete(
      () => _refrescoEnCurso = null,
    );
  }

  Future<bool> _refrescar() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return false;
    final http.Response r;
    try {
      r = await cliente
          .post(
            _uri('/auth/refresh'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refreshToken': rt}),
          )
          .timeout(timeout);
    } catch (e) {
      Registro.aviso('Api', 'Refresh sin conexión (${e.runtimeType})');
      return false;
    }
    if (r.statusCode != 200) {
      Registro.aviso('Api', 'Refresh rechazado (${r.statusCode})');
      return false;
    }
    final datos = _decodificar(r, '/auth/refresh');
    if (datos is! Map<String, dynamic> ||
        datos['token'] is! String ||
        datos['refreshToken'] is! String) {
      Registro.aviso('Api', 'Refresh con respuesta inválida');
      return false;
    }
    token = datos['token'] as String;
    refreshToken = datos['refreshToken'] as String;
    await alRenovarTokens?.call(datos);
    Registro.info('Api', 'Sesión renovada');
    return true;
  }

  void _expirar() {
    token = null;
    refreshToken = null;
    Registro.aviso('Api', 'Sesión expirada');
    alExpirarSesion?.call();
  }

  /// POST /auth/logout { refreshToken } (revoca el refresh en el servidor).
  /// Si falla no importa: la sesión local se borra de todas formas.
  Future<void> logoutRemoto() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return;
    try {
      await cliente
          .post(
            _uri('/auth/logout'),
            headers: _headers(),
            body: jsonEncode({'refreshToken': rt}),
          )
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      Registro.aviso('Api', 'Logout remoto falló (${e.runtimeType})');
    }
  }

  dynamic _decodificar(http.Response r, String ruta) {
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } catch (e) {
      Registro.aviso('Api', 'Respuesta no JSON en $ruta (${r.statusCode})');
      return null;
    }
  }

  /// Arma la excepción con { message, errors }.
  ApiException _excepcion(dynamic cuerpo, int status) {
    final errores = <String, String>{};
    String? mensaje;
    if (cuerpo is Map) {
      final e = cuerpo['errors'];
      if (e is Map) {
        e.forEach((k, v) {
          final texto = v is List
              ? (v.isEmpty ? null : v.first?.toString())
              : v?.toString();
          if (texto != null && texto.isNotEmpty) errores[k.toString()] = texto;
        });
      }
      final msg = cuerpo['message'];
      if (msg is String && msg.isNotEmpty) mensaje = msg;
    }
    if (status >= 500) Registro.error('Api', 'Error del servidor $status');
    mensaje ??= errores.isNotEmpty
        ? errores.values.first
        : _mensajePorStatus(status);
    return ApiException(mensaje, status: status, errores: errores);
  }

  static String _mensajePorStatus(int status) {
    switch (status) {
      case 401:
        return 'Sesión no válida.';
      case 403:
        return 'Sin permiso.';
      case 404:
        return 'No encontrado.';
      case 422:
        return 'Revisa los datos.';
      case 429:
        return 'Demasiados intentos. Espera un momento.';
      default:
        return status >= 500
            ? 'El servidor tuvo un problema. Intenta más tarde.'
            : 'Error del servidor ($status).';
    }
  }
}
