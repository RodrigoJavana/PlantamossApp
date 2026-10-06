// Almacenamiento seguro de la sesión (token, refreshToken y usuario).
//
// - Android: flutter_secure_storage cifra con AES-GCM y la llave vive en el
//   Android Keystore.
// - iOS: Keychain (accesible solo con el equipo desbloqueado, sin iCloud).
// - Web: cifrado con WebCrypto.
// En shared_preferences solo quedan datos NO sensibles (servidor).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constantes.dart';
import 'registro.dart';

/// Datos de la sesión guardados de forma segura.
class SesionGuardada {
  final String? token;
  final String? refreshToken;
  final String? usuarioJson;
  const SesionGuardada({this.token, this.refreshToken, this.usuarioJson});

  bool get vacia =>
      (token == null || token!.isEmpty) &&
      (refreshToken == null || refreshToken!.isEmpty);
}

/// Contrato del almacén (permite usar uno en memoria en las pruebas).
abstract class AlmacenSesion {
  Future<SesionGuardada> leer();
  Future<void> guardar({
    String? token,
    String? refreshToken,
    String? usuarioJson,
  });
  Future<void> borrar();
}

class AlmacenSeguro implements AlmacenSesion {
  AlmacenSeguro([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  static const _kToken = 'pm_token';
  static const _kRefresh = 'pm_refresh';
  static const _kUsuario = 'pm_user';

  @override
  Future<SesionGuardada> leer() async {
    try {
      await _migrarDesdePrefs();
      return SesionGuardada(
        token: await _storage.read(key: _kToken),
        refreshToken: await _storage.read(key: _kRefresh),
        usuarioJson: await _storage.read(key: _kUsuario),
      );
    } catch (e, st) {
      Registro.error('AlmacenSeguro', 'No se pudo leer la sesión', e, st);
      return const SesionGuardada();
    }
  }

  @override
  Future<void> guardar({
    String? token,
    String? refreshToken,
    String? usuarioJson,
  }) async {
    if (token != null) await _storage.write(key: _kToken, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _kRefresh, value: refreshToken);
    }
    if (usuarioJson != null) {
      await _storage.write(key: _kUsuario, value: usuarioJson);
    }
  }

  @override
  Future<void> borrar() async {
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kRefresh);
      await _storage.delete(key: _kUsuario);
    } catch (e, st) {
      Registro.error('AlmacenSeguro', 'No se pudo borrar la sesión', e, st);
    }
    // Por si quedó algo de la versión anterior.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ClavesPrefs.tokenViejo);
    await prefs.remove(ClavesPrefs.usuarioViejo);
  }

  /// Versiones anteriores guardaban la sesión en shared_preferences (texto
  /// plano). Si existe, se mueve al almacén seguro y se borra.
  Future<void> _migrarDesdePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ClavesPrefs.tokenViejo);
    final usuario = prefs.getString(ClavesPrefs.usuarioViejo);
    if (token == null && usuario == null) return;
    await guardar(token: token, usuarioJson: usuario);
    await prefs.remove(ClavesPrefs.tokenViejo);
    await prefs.remove(ClavesPrefs.usuarioViejo);
    Registro.info('AlmacenSeguro', 'Sesión migrada desde shared_preferences');
  }
}

/// Almacén en memoria (solo pruebas).
class AlmacenMemoria implements AlmacenSesion {
  final Map<String, String> datos = {};

  @override
  Future<SesionGuardada> leer() async => SesionGuardada(
    token: datos['token'],
    refreshToken: datos['refresh'],
    usuarioJson: datos['user'],
  );

  @override
  Future<void> guardar({
    String? token,
    String? refreshToken,
    String? usuarioJson,
  }) async {
    if (token != null) datos['token'] = token;
    if (refreshToken != null) datos['refresh'] = refreshToken;
    if (usuarioJson != null) datos['user'] = usuarioJson;
  }

  @override
  Future<void> borrar() async => datos.clear();
}
