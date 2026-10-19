// Racha de visitas: registra la visita de hoy y guarda el estado para la UI.
//
// Las peticiones usan el ApiClient (token + renovación). Si no hay red,
// falla en silencio: la racha se actualizará en la siguiente visita.
import 'package:flutter/foundation.dart';

import '../models/racha.dart';
import 'api_client.dart';
import 'registro.dart';

class RachaService {
  RachaService._(this._api);

  static final RachaService instancia = RachaService._(ApiClient.instancia);

  final ApiClient _api;

  /// Estado actual de la racha (null mientras no se cargue o sin sesión).
  final ValueNotifier<Racha?> racha = ValueNotifier(null);

  bool _registrando = false;

  /// POST /racha/registrar (idempotente) y luego recarga el estado.
  Future<void> registrar() async {
    if (_registrando || _api.token == null) return;
    _registrando = true;
    try {
      await _api.post('/racha/registrar', {});
      await cargar();
    } catch (e) {
      Registro.aviso(
        'Racha',
        'No se pudo registrar la visita (${e.runtimeType})',
      );
    } finally {
      _registrando = false;
    }
  }

  /// GET /racha. Si falla, deja el último estado conocido.
  Future<void> cargar() async {
    if (_api.token == null) return;
    try {
      final data = await _api.get('/racha');
      // Si cerró sesión mientras esperaba, no guarda nada.
      if (_api.token == null) return;
      if (data is Map<String, dynamic>) racha.value = Racha.fromJson(data);
    } catch (e) {
      Registro.aviso('Racha', 'No se pudo cargar la racha (${e.runtimeType})');
    }
  }

  /// Borra el estado (al cerrar sesión).
  void limpiar() => racha.value = null;
}
