// Consultas del catálogo de plantas y de los estados.
import '../models/planta.dart';
import 'api_client.dart';

class PlantasService {
  final ApiClient _api = ApiClient.instancia;

  /// GET /plantas?q=&estado=&clima=&luz=
  Future<List<Planta>> listar({
    String? q,
    int? estado,
    String? clima,
    String? luz,
  }) async {
    final data = await _api.get(
      '/plantas',
      query: {'q': q, 'estado': estado?.toString(), 'clima': clima, 'luz': luz},
    );
    if (data is! List) return [];
    return data.map((e) => Planta.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /estados
  Future<List<Estado>> estados() async {
    final data = await _api.get('/estados');
    if (data is! List) return [];
    return data.map((e) => Estado.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /estados/{id}/plantas: el estado y sus plantas.
  Future<EstadoConPlantas> plantasDeEstado(int idEstado) async {
    final data = await _api.get('/estados/$idEstado/plantas');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('No se pudieron cargar las plantas del estado.');
    }
    return EstadoConPlantas.fromJson(data);
  }
}
