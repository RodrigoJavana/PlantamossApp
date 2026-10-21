// Servicios externos a través de la API (clima con OpenWeather).
import '../models/clima.dart';
import 'api_client.dart';

class ExternoService {
  final ApiClient _api = ApiClient.instancia;

  /// GET /externo/clima?q=. Devuelve null si la API no tiene clima para esa ciudad.
  Future<ClimaActual?> clima(String ciudad) async {
    final data = await _api.get('/externo/clima', query: {'q': ciudad});
    if (data is! Map<String, dynamic>) return null;
    final clima = ClimaActual.fromJson(data);
    return clima.ok ? clima : null;
  }
}
