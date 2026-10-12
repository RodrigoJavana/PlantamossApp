// Datos de la pantalla de Inicio: noticias y clima de las ciudades.
import '../models/inicio.dart';
import 'api_client.dart';

class InicioService {
  final ApiClient _api = ApiClient.instancia;

  /// GET /noticias/recientes
  Future<List<Noticia>> noticiasRecientes() async {
    final data = await _api.get('/noticias/recientes');
    if (data is! List) return [];
    return data
        .map((e) => Noticia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /perfil/ciudades-clima y luego GET /externo/clima de cada ciudad
  /// EN PARALELO (Future.wait). Si una ciudad falla, queda sin datos.
  Future<List<ClimaCiudad>> climaCiudades() async {
    final data = await _api.get('/perfil/ciudades-clima');
    if (data is! List) return [];
    final ciudades = data
        .map((e) => CiudadClima.fromJson(e as Map<String, dynamic>))
        .toList();

    return Future.wait(
      ciudades.map((c) async {
        try {
          final r = await _api.get('/externo/clima', query: {'q': c.consulta});
          return ClimaCiudad(
            c,
            r is Map<String, dynamic> ? ClimaActual.fromJson(r) : null,
          );
        } catch (_) {
          return ClimaCiudad(c, null);
        }
      }),
    );
  }
}
