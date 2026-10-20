// Insignias (logros): carga la lista, manda eventos y guarda la cola de
// "¡Ganaste una insignia!" por mostrar.
//
// Las peticiones usan el ApiClient (token + renovación). Si no hay red,
// falla en silencio: se intentará en la siguiente visita.
import 'package:flutter/foundation.dart';

import '../models/insignia.dart';
import 'api_client.dart';
import 'registro.dart';

class InsigniasService {
  InsigniasService._(this._api);

  static final InsigniasService instancia = InsigniasService._(
    ApiClient.instancia,
  );

  final ApiClient _api;

  /// Catálogo con el avance del usuario (vacío mientras no se cargue o sin sesión).
  final ValueNotifier<List<Insignia>> insignias = ValueNotifier([]);

  /// Cola de insignias nuevas que falta mostrar (una a la vez).
  final ValueNotifier<List<Insignia>> porMostrar = ValueNotifier([]);

  /// Eventos ya enviados en esta sesión ("evento|referencia").
  final Set<String> _enviados = {};

  /// Insignias ya puestas en la cola en esta sesión (evita avisos repetidos).
  final Set<String> _vistas = {};

  /// GET /insignias. Si falla, deja la última lista conocida.
  Future<void> cargar() async {
    if (_api.token == null) return;
    try {
      final data = await _api.get('/insignias');
      // Si cerró sesión mientras esperaba, no guarda nada.
      if (_api.token == null) return;
      if (data is Map<String, dynamic>) {
        insignias.value = _lista(data['insignias']);
        _encolar(_lista(data['nuevas']));
      }
    } catch (e) {
      Registro.aviso('Insignias', 'No se pudieron cargar (${e.runtimeType})');
    }
  }

  /// POST /insignias/evento. Un mismo evento con la misma referencia se manda una sola vez.
  Future<void> evento(String evento, String referencia) async {
    if (_api.token == null) return;
    final clave = '$evento|$referencia';
    if (!_enviados.add(clave)) return;
    try {
      final data = await _api.post('/insignias/evento', {
        'evento': evento,
        'referencia': referencia,
      });
      if (_api.token == null) return;
      if (data is Map<String, dynamic>) _encolar(_lista(data['nuevas']));
      // Refresca el avance de las insignias (el evento pudo moverlo).
      await cargar();
    } catch (e) {
      // Si falló por red, se podrá reintentar en la siguiente visita.
      _enviados.remove(clave);
      Registro.aviso(
        'Insignias',
        'No se pudo enviar el evento $evento (${e.runtimeType})',
      );
    }
  }

  /// Quita la primera insignia de la cola (ya se mostró).
  void quitarPrimera() {
    if (porMostrar.value.isEmpty) return;
    porMostrar.value = porMostrar.value.sublist(1);
  }

  /// Borra todo (al cerrar sesión).
  void limpiar() {
    insignias.value = [];
    porMostrar.value = [];
    _enviados.clear();
    _vistas.clear();
  }

  void _encolar(List<Insignia> nuevas) {
    final cola = [...porMostrar.value];
    for (final i in nuevas) {
      if (i.codigo.isEmpty || !_vistas.add(i.codigo)) continue;
      cola.add(i);
    }
    if (cola.length != porMostrar.value.length) porMostrar.value = cola;
  }

  List<Insignia> _lista(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map<String, dynamic>>()
        .map(Insignia.fromJson)
        .where((i) => i.codigo.isNotEmpty)
        .toList();
  }
}
