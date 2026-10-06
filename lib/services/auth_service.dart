// Manejo de la sesión: login, logout, renovación y restaurar la sesión guardada.
//
// Es un ChangeNotifier: la app escucha sus cambios para decidir si
// muestra el Login o la pantalla principal.
// Token, refreshToken y usuario se guardan cifrados (AlmacenSeguro).
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import 'almacen_seguro.dart';
import 'api_client.dart';
import 'insignias_service.dart';
import 'racha_service.dart';
import 'registro.dart';

class AuthService extends ChangeNotifier {
  AuthService._(this._api, this._almacen) {
    // Refresh exitoso -> guardar los nuevos tokens.
    _api.alRenovarTokens = _guardarRespuesta;
    // Refresh fallido -> limpiar y volver al login con aviso.
    _api.alExpirarSesion = () => _cerrarLocal(mensaje: kMsgSesionExpirada);
  }

  static final AuthService instancia = AuthService._(
    ApiClient.instancia,
    AlmacenSeguro(),
  );

  /// Servicio aislado para pruebas.
  @visibleForTesting
  factory AuthService.prueba(ApiClient api, AlmacenSesion almacen) =>
      AuthService._(api, almacen);

  final ApiClient _api;
  final AlmacenSesion _almacen;

  Usuario? usuario;

  /// true mientras se revisa la sesión guardada al abrir la app.
  bool iniciando = true;

  /// Aviso para mostrar en el login (p. ej. "Tu sesión expiró").
  String? aviso;

  bool get autenticado => usuario != null && _api.token != null;

  /// Al abrir la app: carga servidor + sesión segura y valida con /auth/me
  /// (si el token venció, ApiClient lo renueva solo).
  Future<void> restaurarSesion() async {
    try {
      await _api.cargarServidor();
      final s = await _almacen.leer();
      if (!s.vacia) {
        _api.token = s.token;
        _api.refreshToken = s.refreshToken;
        try {
          final data = await _api.get('/auth/me');
          usuario = Usuario.fromJson(data as Map<String, dynamic>);
          await _almacen.guardar(usuarioJson: jsonEncode(usuario!.toJson()));
        } on ApiException catch (e) {
          if (e.status == 401 || e.status == 403) {
            await _cerrarLocal(mensaje: kMsgSesionExpirada, notificar: false);
          } else if (s.usuarioJson != null && _api.token != null) {
            // Sin red: usamos el usuario guardado para no sacarlo de la app.
            usuario = Usuario.fromJson(
              jsonDecode(s.usuarioJson!) as Map<String, dynamic>,
            );
          } else {
            await _cerrarLocal(notificar: false);
          }
        }
      }
    } catch (e, st) {
      Registro.error('Auth', 'No se pudo restaurar la sesión', e, st);
      await _cerrarLocal(notificar: false);
    }
    iniciando = false;
    notifyListeners();
  }

  /// POST /auth/login. Lanza ApiException con el mensaje de la API.
  Future<void> iniciarSesion(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    if (data is! Map<String, dynamic> ||
        data['token'] is! String ||
        data['user'] is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida del servidor.');
    }
    await _guardarRespuesta(data);
    aviso = null;
    Registro.info('Auth', 'Inicio de sesión de $email');
    notifyListeners();
  }

  /// Cierra sesión: revoca el refresh en la API y borra la sesión segura.
  Future<void> cerrarSesion() async {
    await _api.logoutRemoto();
    await _cerrarLocal();
    Registro.info('Auth', 'Sesión cerrada');
  }

  /// Guarda { token, refreshToken, user } (login o refresh).
  Future<void> _guardarRespuesta(Map<String, dynamic> data) async {
    _api.token = data['token'] as String;
    final rt = data['refreshToken'];
    if (rt is String && rt.isNotEmpty) _api.refreshToken = rt;
    final u = data['user'];
    if (u is Map<String, dynamic>) usuario = Usuario.fromJson(u);
    await _almacen.guardar(
      token: _api.token,
      refreshToken: _api.refreshToken,
      usuarioJson: usuario == null ? null : jsonEncode(usuario!.toJson()),
    );
  }

  Future<void> _cerrarLocal({String? mensaje, bool notificar = true}) async {
    _api.token = null;
    _api.refreshToken = null;
    usuario = null;
    RachaService.instancia.limpiar();
    InsigniasService.instancia.limpiar();
    if (mensaje != null) aviso = mensaje;
    await _almacen.borrar();
    if (notificar) notifyListeners();
  }
}
