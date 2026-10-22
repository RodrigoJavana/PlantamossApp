// Blog de la comunidad: listado con imagen, autor, fecha y extracto.
// Desde aquí se publica y se entra a "Mis blogs".
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/blog.dart';
import '../services/api_client.dart';
import '../services/blogs_service.dart';
import '../widgets/comunes.dart';
import '../widgets/imagen_planta.dart';
import 'blog_detalle_screen.dart';
import 'blog_form_screen.dart';
import 'mis_blogs_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
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
      final lista = await _servicio.listar();
      if (!mounted) return;
      setState(() => _blogs = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _publicar() async {
    final guardado = await Navigator.of(
      context,
    ).push<Blog>(MaterialPageRoute(builder: (_) => const BlogFormScreen()));
    if (guardado != null) _cargar();
  }

  Future<void> _abrir(Blog blog) async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BlogDetalleScreen(blog: blog)),
    );
    if (cambio == true) _cargar();
  }

  Future<void> _misBlogs() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MisBlogsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColores.verdeOscuro,
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Blog',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColores.titulo,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Historias y consejos de la comunidad.',
            style: TextStyle(fontSize: 13.5, color: AppColores.texto),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _publicar,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Publicar blog'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
              OutlinedButton.icon(
                onPressed: _misBlogs,
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: const Text('Mis blogs'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._contenido(),
        ],
      ),
    );
  }

  List<Widget> _contenido() {
    if (_cargando && _blogs.isEmpty) {
      return [
        for (var i = 0; i < 3; i++) ...[
          const _TarjetaSkeleton(),
          const SizedBox(height: 14),
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
          texto: 'Aún no hay publicaciones.',
        ),
      ];
    }
    return [
      for (var i = 0; i < _blogs.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        _BlogTarjeta(blog: _blogs[i], alTocar: () => _abrir(_blogs[i])),
      ],
    ];
  }
}

/// Tarjeta de un blog en el listado: imagen fija, meta, título y extracto.
class _BlogTarjeta extends StatelessWidget {
  final Blog blog;
  final VoidCallback alTocar;
  const _BlogTarjeta({required this.blog, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadios.tarjeta),
        side: const BorderSide(color: AppColores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ImagenPlanta(url: blog.urlImagen, tamanoIcono: 40),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColores.texto,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${fechaCorta(blog.fechaPublicacion)} · por ${blog.autorMostrado}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColores.texto,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppColores.titulo,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    blog.extracto,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColores.titulo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Leer más',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColores.verdeOscuro,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSkeleton extends StatelessWidget {
  const _TarjetaSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Tarjeta(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(alto: 180, radio: 0),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(ancho: 160, alto: 11),
                SizedBox(height: 12),
                Skeleton(alto: 16),
                SizedBox(height: 8),
                Skeleton(alto: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
