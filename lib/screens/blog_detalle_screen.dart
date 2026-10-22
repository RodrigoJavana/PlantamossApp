// Detalle de un blog: imágenes, título, autor, fecha y todos los párrafos.
// Al abrirlo registra la lectura (insignia LEER_BLOG).
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/blog.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/blogs_service.dart';
import '../services/insignias_service.dart';
import '../widgets/imagen_planta.dart';
import 'blog_form_screen.dart';

class BlogDetalleScreen extends StatefulWidget {
  final Blog blog;
  const BlogDetalleScreen({super.key, required this.blog});

  @override
  State<BlogDetalleScreen> createState() => _BlogDetalleScreenState();
}

class _BlogDetalleScreenState extends State<BlogDetalleScreen> {
  final _servicio = BlogsService();

  late Blog _blog = widget.blog;
  bool _cambio = false; // avisa a la lista que debe recargar al volver
  bool _borrando = false;

  @override
  void initState() {
    super.initState();
    InsigniasService.instancia.evento('LEER_BLOG', '${widget.blog.idBlog}');
  }

  /// Dueño del blog o moderador (mismo criterio que la API).
  bool get _puedeGestionar {
    final u = AuthService.instancia.usuario;
    if (u == null) return false;
    return _blog.idUsuario == u.id || u.role == 'noticias' || u.role == 'admin';
  }

  Future<void> _editar() async {
    final actualizado = await Navigator.of(context).push<Blog>(
      MaterialPageRoute(builder: (_) => BlogFormScreen(blog: _blog)),
    );
    if (actualizado != null && mounted) {
      setState(() {
        _blog = actualizado;
        _cambio = true;
      });
    }
  }

  Future<void> _confirmarBorrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar blog'),
        content: Text(
          '¿Seguro que quieres eliminar "${_blog.titulo}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColores.rojo,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await _borrar();
  }

  Future<void> _borrar() async {
    setState(() => _borrando = true);
    try {
      await _servicio.eliminar(_blog.idBlog);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, pila) {
      if (!mounted) return;
      setState(() => _borrando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeError(e, pila))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = _blog.imagenes;
    final parrafos = _blog.parrafos;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_cambio);
      },
      child: Scaffold(
        backgroundColor: AppColores.fondo,
        appBar: AppBar(
          title: const Text('Blog'),
          actions: [
            if (_puedeGestionar) ...[
              IconButton(
                tooltip: 'Editar',
                onPressed: _borrando ? null : _editar,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: _borrando ? null : _confirmarBorrar,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Imagen principal y adicionales, con tamaño fijo.
            for (var i = 0; i < imagenes.length; i++) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadios.tarjeta),
                child: SizedBox(
                  height: i == 0 ? 240 : 190,
                  width: double.infinity,
                  child: ImagenPlanta(url: imagenes[i], tamanoIcono: 48),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              _blog.titulo,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppColores.titulo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${fechaCorta(_blog.fechaPublicacion)} · por ${_blog.autorMostrado}',
              style: const TextStyle(fontSize: 13, color: AppColores.texto),
            ),
            const SizedBox(height: 18),
            for (final p in parrafos)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.7,
                    color: AppColores.titulo,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
