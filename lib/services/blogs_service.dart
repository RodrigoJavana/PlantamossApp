// Blogs de la comunidad: listado, "mis blogs", publicar, editar y eliminar.
import '../models/blog.dart';
import 'api_client.dart';

class BlogsService {
  final ApiClient _api = ApiClient.instancia;

  /// GET /blogs (públicos, más recientes primero).
  Future<List<Blog>> listar() async => _lista(await _api.get('/blogs'));

  /// GET /blogs/mios (solo los del usuario).
  Future<List<Blog>> mios() async => _lista(await _api.get('/blogs/mios'));

  /// POST /blogs. Requiere correo verificado (la API responde 403 si no).
  Future<Blog> crear(BlogEntrada entrada) async =>
      _blog(await _api.post('/blogs', entrada.toJson()));

  /// PUT /blogs/{id}: dueño o moderador.
  Future<Blog> actualizar(int id, BlogEntrada entrada) async =>
      _blog(await _api.put('/blogs/$id', entrada.toJson()));

  /// DELETE /blogs/{id}: dueño o moderador.
  Future<void> eliminar(int id) async {
    await _api.delete('/blogs/$id');
  }

  List<Blog> _lista(dynamic data) {
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(Blog.fromJson).toList();
  }

  Blog _blog(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException('No se pudo leer el blog guardado.');
    }
    return Blog.fromJson(data);
  }
}
