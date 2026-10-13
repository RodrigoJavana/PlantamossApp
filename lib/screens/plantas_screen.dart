// Catálogo de plantas: imagen destacada con chips de filtro, buscador
// (con debounce), lista de tarjetas y botón flotante de filtros.
import 'dart:async';

import 'package:flutter/material.dart';

import '../config/constantes.dart';
import '../config/tema.dart';
import '../models/planta.dart';
import '../services/api_client.dart';
import '../services/plantas_service.dart';
import '../services/validadores.dart';
import '../widgets/comunes.dart';
import '../widgets/imagen_planta.dart';
import 'planta_detalle_screen.dart';

class PlantasScreen extends StatefulWidget {
  const PlantasScreen({super.key});

  @override
  State<PlantasScreen> createState() => _PlantasScreenState();
}

class _PlantasScreenState extends State<PlantasScreen> {
  final _servicio = PlantasService();
  final _buscarCtrl = TextEditingController();
  Timer? _debounce;

  // Resultados
  List<Planta> _plantas = [];
  bool _cargando = true;
  String? _error;
  int _peticion = 0; // para ignorar respuestas viejas

  // Filtros
  String _q = '';
  Estado? _estado;
  String? _clima;
  String? _luz;
  List<Estado> _estados = [];

  bool get _hayFiltros =>
      _q.isNotEmpty || _estado != null || _clima != null || _luz != null;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = ++_peticion;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _servicio.listar(
        q: _q,
        estado: _estado?.idEstado,
        clima: _clima,
        luz: _luz,
      );
      if (id != _peticion) return; // llegó una búsqueda más nueva
      _plantas = r;
    } catch (e) {
      if (id != _peticion) return;
      _error = mensajeDeError(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  /// Espera 350 ms después de la última tecla antes de buscar.
  void _alEscribir(String texto) {
    setState(() {}); // actualiza el botón de borrar
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _q = Validadores.sanearBusqueda(texto);
      _cargar();
    });
  }

  void _limpiarFiltros() {
    _debounce?.cancel();
    _buscarCtrl.clear();
    _q = '';
    _estado = null;
    _clima = null;
    _luz = null;
    _cargar();
  }

  // ---------------- Selectores ----------------

  Future<void> _elegirEstado() async {
    if (_estados.isEmpty) {
      try {
        _estados = await _servicio.estados();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
        }
        return;
      }
    }
    if (!mounted) return;
    // Devuelve un Estado, o un Estado con id 0 para "Todos".
    final elegido = await showModalBottomSheet<Estado>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelectorEstado(estados: _estados, actual: _estado),
    );
    if (elegido == null) return;
    setState(() => _estado = elegido.idEstado == 0 ? null : elegido);
    _cargar();
  }

  Future<void> _abrirFiltros() async {
    final r = await showModalBottomSheet<(String?, String?)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltrosSheet(clima: _clima, luz: _luz),
    );
    if (r == null) return;
    setState(() {
      _clima = r.$1;
      _luz = r.$2;
    });
    _cargar();
  }

  String get _textoRecomendaciones {
    final partes = [
      buscarClima(_clima)?.etiqueta,
      buscarLuz(_luz)?.etiqueta,
    ].whereType<String>();
    return partes.isEmpty ? 'Recomendaciones' : partes.join(' · ');
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      floatingActionButton: FloatingActionButton.small(
        key: const Key('fab_filtros'),
        tooltip: 'Filtros',
        heroTag: 'fab_filtros',
        backgroundColor: AppColores.verdeClaro,
        foregroundColor: AppColores.verdeOscuro,
        elevation: 2,
        shape: const CircleBorder(),
        onPressed: _abrirFiltros,
        child: const Icon(Icons.tune_rounded),
      ),
      body: RefreshIndicator(
        color: AppColores.verdeOscuro,
        onRefresh: _cargar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(child: _destacada()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              sliver: SliverToBoxAdapter(child: _buscador()),
            ),
            ..._lista(),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  /// Imagen grande con los chips de filtro encima.
  Widget _destacada() {
    final primera = _plantas.isNotEmpty ? _plantas.first : null;
    final tieneImagen = (primera?.urlImagen ?? '').isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            tieneImagen
                ? ImagenPlanta(url: primera!.urlImagen, tamanoIcono: 48)
                : Image.asset(
                    'assets/img/banner-inicio.jpg',
                    fit: BoxFit.cover,
                  ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipImagen(
                    key: const Key('chip_estado'),
                    icono: Icons.location_on_rounded,
                    texto: _estado?.nombreEstado ?? 'Todo México',
                    activo: _estado != null,
                    alTocar: _elegirEstado,
                  ),
                  _ChipImagen(
                    key: const Key('chip_recomendaciones'),
                    icono: Icons.auto_awesome_rounded,
                    texto: _textoRecomendaciones,
                    activo: _clima != null || _luz != null,
                    alTocar: _abrirFiltros,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buscador() {
    return TextField(
      key: const Key('campo_buscar'),
      controller: _buscarCtrl,
      onChanged: _alEscribir,
      textInputAction: TextInputAction.search,
      maxLength: Limites.busqueda,
      decoration: InputDecoration(
        hintText: 'Buscar planta',
        counterText: '',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _buscarCtrl.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _buscarCtrl.clear();
                  _alEscribir('');
                },
              ),
      ),
    );
  }

  List<Widget> _lista() {
    if (_cargando && _plantas.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, _) => const _PlantaSkeleton(),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(
          child: MensajeEstado(
            icono: Icons.wifi_off_rounded,
            texto: _error!,
            textoBoton: 'Reintentar',
            alPresionar: _cargar,
          ),
        ),
      ];
    }
    if (_plantas.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColores.texto,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sin resultados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColores.titulo,
                ),
              ),
              if (_hayFiltros) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpiar filtros'),
                ),
              ],
            ],
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Text(
                '${_plantas.length} ${_plantas.length == 1 ? 'planta' : 'plantas'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColores.texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_hayFiltros)
                TextButton(
                  onPressed: _limpiarFiltros,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColores.verdeOscuro,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Limpiar'),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: _plantas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _PlantaCard(
            planta: _plantas[i],
            alTocar: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlantaDetalleScreen(planta: _plantas[i]),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

// ======================= Widgets privados =======================

/// Chip blanco sobre la imagen destacada.
class _ChipImagen extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activo;
  final VoidCallback alTocar;
  const _ChipImagen({
    super.key,
    required this.icono,
    required this.texto,
    required this.activo,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo
          ? AppColores.verdeOscuro
          : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icono,
                size: 16,
                color: activo ? Colors.white : AppColores.verdeOscuro,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  texto,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: activo ? Colors.white : AppColores.titulo,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: activo ? Colors.white : AppColores.titulo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantaCard extends StatelessWidget {
  final Planta planta;
  final VoidCallback alTocar;
  const _PlantaCard({required this.planta, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final clima = buscarClima(planta.tipoClima);
    final luz = buscarLuz(planta.luzSol);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadios.tarjeta),
        side: const BorderSide(color: AppColores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'planta-${planta.idPlanta}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 92,
                    height: 104,
                    child: ImagenPlanta(url: planta.urlImagen, tamanoIcono: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planta.nombrePlanta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColores.titulo,
                      ),
                    ),
                    if ((planta.nombreCientifico ?? '').isNotEmpty)
                      Text(
                        planta.nombreCientifico!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: AppColores.texto,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if ((planta.descripcion ?? '').isNotEmpty)
                      Text(
                        planta.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColores.texto,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        if ((planta.nombreEstado ?? '').isNotEmpty)
                          ChipInfo(
                            icono: Icons.location_on_outlined,
                            texto: planta.nombreEstado!,
                          ),
                        if (clima != null)
                          ChipInfo(icono: clima.icono, texto: clima.etiqueta),
                        if (luz != null)
                          ChipInfo(icono: luz.icono, texto: luz.etiqueta),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantaSkeleton extends StatelessWidget {
  const _PlantaSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Tarjeta(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Skeleton(ancho: 92, alto: 104, radio: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(ancho: 140, alto: 16),
                SizedBox(height: 8),
                Skeleton(ancho: 100, alto: 11),
                SizedBox(height: 12),
                Skeleton(alto: 10),
                SizedBox(height: 6),
                Skeleton(ancho: 120, alto: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de estados para filtrar (con buscador).
class _SelectorEstado extends StatefulWidget {
  final List<Estado> estados;
  final Estado? actual;
  const _SelectorEstado({required this.estados, required this.actual});

  @override
  State<_SelectorEstado> createState() => _SelectorEstadoState();
}

class _SelectorEstadoState extends State<_SelectorEstado> {
  String _filtro = '';

  static String _normalizar(String t) => t
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  @override
  Widget build(BuildContext context) {
    final lista = widget.estados
        .where(
          (e) => _normalizar(e.nombreEstado).contains(_normalizar(_filtro)),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Estado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColores.titulo,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _filtro = Validadores.sanearBusqueda(v)),
              maxLength: Limites.busqueda,
              decoration: const InputDecoration(
                hintText: 'Buscar estado',
                counterText: '',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              children: [
                if (_filtro.isEmpty)
                  _fila(
                    texto: 'Todos los estados',
                    seleccionado: widget.actual == null,
                    alTocar: () => Navigator.pop(
                      context,
                      const Estado(idEstado: 0, nombreEstado: ''),
                    ),
                  ),
                for (final e in lista)
                  _fila(
                    texto: e.nombreEstado,
                    cantidad: e.cantidadPlantas,
                    seleccionado: widget.actual?.idEstado == e.idEstado,
                    alTocar: () => Navigator.pop(context, e),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila({
    required String texto,
    int? cantidad,
    required bool seleccionado,
    required VoidCallback alTocar,
  }) {
    return ListTile(
      onTap: alTocar,
      leading: Icon(
        seleccionado
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: seleccionado ? AppColores.verdeOscuro : AppColores.texto,
      ),
      title: Text(
        texto,
        style: TextStyle(
          fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
          color: AppColores.titulo,
        ),
      ),
      trailing: cantidad == null
          ? null
          : Text(
              '$cantidad',
              style: const TextStyle(
                color: AppColores.texto,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Filtros de clima y luz. Devuelve (clima, luz).
class _FiltrosSheet extends StatefulWidget {
  final String? clima;
  final String? luz;
  const _FiltrosSheet({required this.clima, required this.luz});

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late String? _clima = widget.clima;
  late String? _luz = widget.luz;

  Widget _grupo(
    String titulo,
    List<OpcionFiltro> opciones,
    String? actual,
    ValueChanged<String?> alElegir,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColores.titulo,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in opciones)
              ChoiceChip(
                avatar: Icon(
                  o.icono,
                  size: 16,
                  color: actual == o.valor
                      ? Colors.white
                      : AppColores.verdeOscuro,
                ),
                label: Text(o.etiqueta),
                selected: actual == o.valor,
                showCheckmark: false,
                selectedColor: AppColores.verdeOscuro,
                labelStyle: TextStyle(
                  color: actual == o.valor ? Colors.white : AppColores.titulo,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (sel) => alElegir(sel ? o.valor : null),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColores.titulo,
            ),
          ),
          const SizedBox(height: 18),
          _grupo('Clima', kClimas, _clima, (v) => setState(() => _clima = v)),
          const SizedBox(height: 18),
          _grupo('Luz', kLuces, _luz, (v) => setState(() => _luz = v)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(context, (null, null)),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const Key('boton_aplicar_filtros'),
                  onPressed: () => Navigator.pop(context, (_clima, _luz)),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
