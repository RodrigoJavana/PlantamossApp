// Publicar o editar un blog. Mismos campos y validaciones que la web:
// título (255), imagen principal URL, hasta 4 imágenes extra y hasta 3 párrafos.
// Las imágenes son URLs (la API no recibe archivos).
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/blog.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/blogs_service.dart';
import '../services/insignias_service.dart';
import '../services/validadores.dart';
import '../widgets/comunes.dart';
import '../widgets/imagen_planta.dart';

const int _maxTitulo = 255;
const int _minContenido = 20;
const int _maxContenido = 10000;
const int _maxExtras = 4;
const int _maxUrl = 500;

class BlogFormScreen extends StatefulWidget {
  /// Blog a editar; null para publicar uno nuevo.
  final Blog? blog;
  const BlogFormScreen({super.key, this.blog});

  @override
  State<BlogFormScreen> createState() => _BlogFormScreenState();
}

class _BlogFormScreenState extends State<BlogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _url = TextEditingController();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  final _p3 = TextEditingController();
  final List<TextEditingController> _extras = [];

  int _parrafos = 1;
  bool _guardando = false;
  String? _errorServidor;

  bool get _esEdicion => widget.blog != null;

  /// La API exige correo verificado para publicar (no para editar).
  bool get _sinVerificar =>
      !_esEdicion && !(AuthService.instancia.usuario?.emailVerificado ?? false);

  @override
  void initState() {
    super.initState();
    final b = widget.blog;
    if (b != null) {
      _titulo.text = b.titulo;
      _url.text = b.urlImagen ?? '';
      _p1.text = b.contenido;
      _p2.text = b.contenido2 ?? '';
      _p3.text = b.contenido3 ?? '';
      for (final u in [
        b.urlImagen2,
        b.urlImagen3,
        b.urlImagen4,
        b.urlImagen5,
      ]) {
        if (u != null) _extras.add(TextEditingController(text: u));
      }
      _parrafos = b.contenido3 != null ? 3 : (b.contenido2 != null ? 2 : 1);
    }
  }

  @override
  void dispose() {
    for (final c in [_titulo, _url, _p1, _p2, _p3, ..._extras]) {
      c.dispose();
    }
    super.dispose();
  }

  void _agregarImagen() {
    if (_extras.length >= _maxExtras) return;
    setState(() => _extras.add(TextEditingController()));
  }

  void _quitarImagen(int i) {
    setState(() => _extras.removeAt(i).dispose());
  }

  void _agregarParrafo() {
    if (_parrafos >= 3) return;
    setState(() => _parrafos++);
  }

  void _quitarParrafo(int n) {
    // Si se quita el 2 y existe el 3, el 3 sube (como en la web).
    setState(() {
      if (n == 2) _p2.text = _p3.text;
      _p3.clear();
      _parrafos = _parrafos > 1 ? _parrafos - 1 : 1;
    });
  }

  BlogEntrada _entrada() => BlogEntrada(
    titulo: _titulo.text,
    contenido: _p1.text,
    contenido2: _parrafos >= 2 ? _p2.text : null,
    contenido3: _parrafos >= 3 ? _p3.text : null,
    urlImagen: _url.text,
    extras: [
      for (final c in _extras) c.text.trim(),
    ].where((u) => u.isNotEmpty).toList(),
  );

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _guardando = true;
      _errorServidor = null;
    });
    final servicio = BlogsService();
    try {
      final blog = widget.blog;
      final Blog resultado = blog == null
          ? await servicio.crear(_entrada())
          : await servicio.actualizar(blog.idBlog, _entrada());
      if (!mounted) return;
      if (blog == null) {
        // Revisa si con esta publicación ganó una insignia.
        InsigniasService.instancia.cargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu blog fue publicado. Gracias por compartir.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu blog se actualizó correctamente.')),
        );
      }
      Navigator.of(context).pop(resultado);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _errorServidor = e.errores.isEmpty
            ? e.message
            : e.errores.values.join('\n'),
      );
    } catch (e, pila) {
      if (!mounted) return;
      setState(() => _errorServidor = mensajeDeError(e, pila));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeEnviar = !_guardando && !_sinVerificar;
    return Scaffold(
      backgroundColor: AppColores.fondo,
      appBar: AppBar(title: Text(_esEdicion ? 'Editar blog' : 'Publicar blog')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (_sinVerificar) ...[
              const _AvisoCorreo(),
              const SizedBox(height: 14),
            ],
            if (_errorServidor != null) ...[
              _Aviso(texto: _errorServidor!),
              const SizedBox(height: 14),
            ],
            _seccion('Información', [
              TextFormField(
                controller: _titulo,
                maxLength: _maxTitulo,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej: Cómo cuidar tu nopal en lluvias',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Escribe un título.';
                  if (t.length > _maxTitulo) {
                    return 'Máximo $_maxTitulo caracteres.';
                  }
                  return null;
                },
              ),
            ]),
            const SizedBox(height: 14),
            _seccion('Imágenes', [
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                maxLength: _maxUrl,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Imagen principal (URL)',
                  hintText: 'https://ejemplo.com/planta.jpg',
                ),
                validator: (v) => Validadores.esUrlHttp(v)
                    ? null
                    : 'Debe empezar con http:// o https://',
              ),
              const SizedBox(height: 8),
              _vistaPrevia(),
              const SizedBox(height: 12),
              for (var i = 0; i < _extras.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _extras[i],
                        keyboardType: TextInputType.url,
                        maxLength: _maxUrl,
                        decoration: InputDecoration(
                          labelText: 'Imagen adicional ${i + 1} (opcional)',
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return null;
                          return Validadores.esUrlHttp(v)
                              ? null
                              : 'URL no válida.';
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar imagen ${i + 1}',
                      onPressed: () => _quitarImagen(i),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_extras.length < _maxExtras)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _agregarImagen,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: Text(
                      'Agregar imagen (${_extras.length}/$_maxExtras)',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            _seccion('Contenido', [
              _campoParrafo(
                numero: 1,
                controlador: _p1,
                etiqueta: 'Párrafo',
                obligatorio: true,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.length < _minContenido) {
                    return 'Mínimo $_minContenido caracteres.';
                  }
                  return null;
                },
              ),
              if (_parrafos >= 2) ...[
                const SizedBox(height: 14),
                _campoParrafo(
                  numero: 2,
                  controlador: _p2,
                  etiqueta: 'Párrafo 2 (opcional)',
                  onQuitar: () => _quitarParrafo(2),
                ),
              ],
              if (_parrafos >= 3) ...[
                const SizedBox(height: 14),
                _campoParrafo(
                  numero: 3,
                  controlador: _p3,
                  etiqueta: 'Párrafo 3 (opcional)',
                  onQuitar: () => _quitarParrafo(3),
                ),
              ],
              if (_parrafos < 3) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _agregarParrafo,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Agregar párrafo'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: puedeEnviar ? _guardar : null,
                  child: Text(
                    _guardando
                        ? 'Guardando...'
                        : (_esEdicion ? 'Guardar cambios' : 'Publicar blog'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Imagen de la URL principal, o un recuadro con la pista si aún no hay una válida.
  Widget _vistaPrevia() {
    final valida = Validadores.esUrlHttp(_url.text);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadios.tarjeta),
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: valida
            ? ImagenPlanta(url: _url.text.trim(), tamanoIcono: 40)
            : Container(
                color: AppColores.verdeSuave,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Pega una URL para ver la imagen',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColores.texto),
                ),
              ),
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> hijos) {
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColores.titulo,
            ),
          ),
          const SizedBox(height: 12),
          ...hijos,
        ],
      ),
    );
  }

  Widget _campoParrafo({
    required int numero,
    required TextEditingController controlador,
    required String etiqueta,
    bool obligatorio = false,
    String? Function(String?)? validator,
    VoidCallback? onQuitar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColores.titulo,
                ),
              ),
            ),
            if (onQuitar != null)
              IconButton(
                tooltip: 'Quitar párrafo $numero',
                onPressed: onQuitar,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        TextFormField(
          controller: controlador,
          minLines: 4,
          maxLines: 10,
          maxLength: _maxContenido,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: obligatorio
                ? 'Escribe el primer párrafo...'
                : 'Continúa tu historia...',
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _AvisoCorreo extends StatelessWidget {
  const _AvisoCorreo();

  @override
  Widget build(BuildContext context) {
    return _Aviso(
      icono: Icons.mark_email_unread_outlined,
      texto:
          'Verifica tu correo para publicar blogs. Revisa tu bandeja de entrada y vuelve a intentarlo.',
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;
  final IconData icono;
  const _Aviso({required this.texto, this.icono = Icons.error_outline_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(AppRadios.boton),
        border: Border.all(color: const Color(0xFFF5D39B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: const Color(0xFF8A5300)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColores.titulo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
