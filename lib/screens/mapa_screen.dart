// Mapa interactivo de México: toca un estado para ver su clima y sus plantas.
// Incluye una lista de estados como alternativa accesible al mapa.
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/estado_mapa.dart';
import '../models/planta.dart';
import '../services/api_client.dart';
import '../services/insignias_service.dart';
import '../services/plantas_service.dart';
import '../services/validadores.dart';
import '../widgets/comunes.dart';
import '../widgets/estado_panel.dart';
import '../widgets/mapa_mexico.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _servicio = PlantasService();
  final _buscarCtrl = TextEditingController();

  List<EstadoMapa> _geo = const [];
  List<Estado> _estados = const [];
  bool _cargando = true;
  String? _error;
  bool _vistaLista = false;
  String _filtro = '';

  /// Clave del estado abierto (se resalta en el mapa).
  String? _claveActiva;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _geo = await cargarMapaMexico();
      _estados = await _servicio.estados();
    } catch (e) {
      _error = mensajeDeError(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  /// Estados de la API por nombre normalizado.
  Map<String, Estado> get _indice => {
    for (final e in _estados) normalizarNombre(e.nombreEstado): e,
  };

  /// Estados con plantas, ordenados por nombre (para anterior/siguiente).
  List<Estado> get _conPlantas {
    final lista = _estados.where((e) => e.cantidadPlantas > 0).toList();
    lista.sort(
      (a, b) => normalizarNombre(
        a.nombreEstado,
      ).compareTo(normalizarNombre(b.nombreEstado)),
    );
    return lista;
  }

  Set<String> get _clavesConDatos => {
    for (final e in _estados)
      if (e.cantidadPlantas > 0) normalizarNombre(e.nombreEstado),
  };

  void _tocarMapa(EstadoMapa e) {
    final estado = _indice[e.clave];
    if (estado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin datos registrados para este estado.'),
        ),
      );
      return;
    }
    _abrirEstado(estado);
  }

  void _marcarVista(Estado e) {
    // Cuenta la visita para las insignias (la API evita duplicados).
    InsigniasService.instancia.evento('VER_ESTADO', '${e.idEstado}');
  }

  void _abrirEstado(Estado estado) {
    _marcarVista(estado);
    setState(() => _claveActiva = normalizarNombre(estado.nombreEstado));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // El fondo y la manija los dibuja el panel; así no queda un hueco blanco arriba.
      backgroundColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      builder: (_) => EstadoPanel(
        estado: estado,
        navegables: _conPlantas,
        alCambiar: (nuevo) {
          _marcarVista(nuevo);
          if (mounted) {
            setState(() => _claveActiva = normalizarNombre(nuevo.nombreEstado));
          }
        },
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _claveActiva = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColores.verdeOscuro,
      onRefresh: _cargarTodo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Mapa',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColores.titulo,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Mapa'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.list_rounded),
                  label: Text('Lista'),
                ),
              ],
              selected: {_vistaLista},
              onSelectionChanged: (s) => setState(() => _vistaLista = s.first),
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null && _estados.isEmpty && !_cargando)
            MensajeEstado(
              icono: Icons.wifi_off_rounded,
              texto: _error!,
              textoBoton: 'Reintentar',
              alPresionar: _cargarTodo,
            )
          else if (_vistaLista)
            ..._vistaListaWidgets()
          else
            ..._vistaMapaWidgets(),
        ],
      ),
    );
  }

  List<Widget> _vistaMapaWidgets() {
    final total = _clavesConDatos.length;
    return [
      if (_geo.isEmpty)
        const SizedBox(
          width: double.infinity,
          child: Skeleton(alto: 240, radio: 20),
        )
      else
        Opacity(
          opacity: _cargando ? 0.6 : 1,
          child: MapaMexico(
            estados: _geo,
            conDatos: _clavesConDatos,
            seleccionado: _claveActiva,
            alTocar: _tocarMapa,
          ),
        ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          _leyenda(const Color(0xFFA5D6A7), 'Con plantas ($total)'),
          _leyenda(
            const Color(0xFFF5F5F5),
            'Sin datos',
            borde: const Color(0xFFCCCCCC),
          ),
          _leyenda(const Color(0xFF2E7D32), 'Seleccionado'),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Pellizca para acercar y arrastra para moverte por el mapa.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: AppColores.texto),
      ),
    ];
  }

  Widget _leyenda(Color color, String texto, {Color? borde}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borde ?? Colors.transparent),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(fontSize: 12.5, color: AppColores.titulo),
        ),
      ],
    );
  }

  List<Widget> _vistaListaWidgets() {
    return [
      TextField(
        onChanged: (v) =>
            setState(() => _filtro = Validadores.sanearBusqueda(v)),
        maxLength: Limites.busqueda,
        decoration: const InputDecoration(
          hintText: 'Buscar estado',
          counterText: '',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 10),
      _listaEstados(),
    ];
  }

  Widget _listaEstados() {
    if (_cargando && _estados.isEmpty) {
      return Column(
        children: [
          for (var i = 0; i < 5; i++) ...[
            const Skeleton(alto: 48, radio: 12),
            const SizedBox(height: 8),
          ],
        ],
      );
    }
    final q = normalizarNombre(_filtro);
    final lista =
        _estados
            .where((e) => normalizarNombre(e.nombreEstado).contains(q))
            .toList()
          ..sort(
            (a, b) => normalizarNombre(
              a.nombreEstado,
            ).compareTo(normalizarNombre(b.nombreEstado)),
          );
    if (lista.isEmpty) {
      return const MensajeEstado(
        icono: Icons.search_off_rounded,
        texto: 'Ningún estado coincide con tu búsqueda.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadios.tarjeta),
        border: Border.all(color: AppColores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < lista.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              onTap: () => _abrirEstado(lista[i]),
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColores.verdeOscuro,
              ),
              title: Text(
                lista[i].nombreEstado,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColores.titulo,
                ),
              ),
              trailing: Text(
                '${lista[i].cantidadPlantas} ${lista[i].cantidadPlantas == 1 ? 'planta' : 'plantas'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColores.texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
