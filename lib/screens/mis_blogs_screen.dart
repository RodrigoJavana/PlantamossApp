// Mis blogs: los blogs del usuario, con editar y eliminar (igual que la web).
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/blog.dart';
import '../services/api_client.dart';
import '../services/blogs_service.dart';
import '../widgets/comunes.dart';
import '../widgets/imagen_planta.dart';
import 'blog_form_screen.dart';

class MisBlogsScreen extends StatefulWidget {
  const MisBlogsScreen({super.key});

  @override
  State<MisBlogsScreen> createState() => _MisBlogsScreenState();
}

class _MisBlogsScreenState extends State<MisBlogsScreen> {
  final _servicio = BlogsService();

  List<Blog> _blogs = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _servicio.mios();
      if (!mounted) return;
      setState(() => _blogs = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _editar(Blog blog) async {
    final actualizado = await Navigator.of(
      context,
    ).push<Blog>(MaterialPageRoute(builder: (_) => BlogFormScreen(blog: blog)));
    if (actualizado == null || !mounted) return;
    setState(() {
      _blogs = [
        for (final b in _blogs)
          b.idBlog == actualizado.idBlog ? actualizado : b,
      ];
    });
  }

  Future<void> _publicar() async {
    final nuevo = await Navigator.of(
      context,
    ).push<Blog>(MaterialPageRoute(builder: (_) => const BlogFormScreen()));
    if (nuevo != null) _cargar();
  }

  Future<void> _eliminar(Blog blog) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar blog'),
        content: Text(
          '¿Seguro que quieres eliminar "${blog.titulo}"? Esta acción no se puede deshacer.',
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
    if (ok != true) return;
    try {
      await _servicio.eliminar(blog.idBlog);
      if (!mounted) return;
      setState(
        () => _blogs = _blogs.where((b) => b.idBlog != blog.idBlog).toList(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tu blog fue eliminado.')));
    } catch (e, pila) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeError(e, pila))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      appBar: AppBar(title: const Text('Mis blogs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publicar,
        backgroundColor: AppColores.verdeClaro,
        foregroundColor: AppColores.verdeOscuro,
        icon: const Icon(Icons.edit_outlined),
        label: const Text(
          'Publicar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: AppColores.verdeOscuro,
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: _contenido(),
        ),
      ),
    );
  }

  List<Widget> _contenido() {
    if (_cargando && _blogs.isEmpty) {
      return [
        for (var i = 0; i < 3; i++) ...[
          const _FilaSkeleton(),
          const SizedBox(height: 10),
        ],
      ];
    }
    if (_error != null && _blogs.isEmpty) {
      return [
        MensajeEstado(
          icono: Icons.wifi_off_rounded,
          texto: _error!,
          textoBoton: 'Reintentar',
          alPresionar: _cargar,
        ),
      ];
    }
    if (_blogs.isEmpty) {
      return const [
        MensajeEstado(
          icono: Icons.article_outlined,
          texto: 'Aún no has publicado blogs.',
        ),
      ];
    }
    final n = _blogs.length;
    return [
      Text(
        '$n ${n == 1 ? 'publicación' : 'publicaciones'}',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColores.texto,
        ),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < _blogs.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        _FilaBlog(
          blog: _blogs[i],
          alEditar: () => _editar(_blogs[i]),
          alEliminar: () => _eliminar(_blogs[i]),
        ),
      ],
    ];
  }
}

class _FilaBlog extends StatelessWidget {
  final Blog blog;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  const _FilaBlog({
    required this.blog,
    required this.alEditar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: ImagenPlanta(url: blog.urlImagen, tamanoIcono: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColores.titulo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fechaCorta(blog.fechaPublicacion)} · ${blog.imagenes.length} ${blog.imagenes.length == 1 ? 'imagen' : 'imágenes'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColores.texto),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar ${blog.titulo}',
            onPressed: alEditar,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColores.verdeOscuro,
            ),
          ),
          IconButton(
            tooltip: 'Eliminar ${blog.titulo}',
            onPressed: alEliminar,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColores.rojo,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaSkeleton extends StatelessWidget {
  const _FilaSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Tarjeta(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Skeleton(ancho: 72, alto: 72, radio: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(alto: 14),
                SizedBox(height: 8),
                Skeleton(ancho: 120, alto: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
