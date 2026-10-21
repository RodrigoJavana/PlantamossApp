// Panel inferior de un estado: clima de su capital y lista de plantas.
// Permite pasar al estado anterior/siguiente (orden alfabético).
import 'package:flutter/material.dart';

import '../config/constantes.dart';
import '../config/tema.dart';
import '../models/clima.dart';
import '../models/estado_mapa.dart';
import '../models/planta.dart';
import '../screens/planta_detalle_screen.dart';
import '../services/api_client.dart';
import '../services/externo_service.dart';
import '../services/plantas_service.dart';
import '../services/validadores.dart';
import 'comunes.dart';
import 'imagen_planta.dart';

class EstadoPanel extends StatefulWidget {
  final Estado estado;

  /// Estados con plantas, ordenados por nombre (para anterior/siguiente).
  final List<Estado> navegables;

  /// Avisa al mapa cuando cambia el estado mostrado.
  final ValueChanged<Estado> alCambiar;

  const EstadoPanel({
    super.key,
    required this.estado,
    required this.navegables,
    required this.alCambiar,
  });

  @override
  State<EstadoPanel> createState() => _EstadoPanelState();
}

class _EstadoPanelState extends State<EstadoPanel> {
  final _plantas = PlantasService();
  final _externo = ExternoService();
  final _buscarCtrl = TextEditingController();

  late Estado _estado = widget.estado;
  EstadoConPlantas? _datos;
  bool _cargando = true;
  String? _error;
  ClimaActual? _clima;
  bool _cargandoClima = true;
  String _filtro = '';
  int _peticion = 0; // ignora respuestas de un estado anterior

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = ++_peticion;
    setState(() {
      _cargando = true;
      _error = null;
      _datos = null;
      _clima = null;
      _cargandoClima = true;
      _filtro = '';
    });
    _cargarClima(id);
    try {
      final datos = await _plantas.plantasDeEstado(_estado.idEstado);
      if (!mounted || id != _peticion) return;
      setState(() {
        _datos = datos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || id != _peticion) return;
      setState(() {
        _error = mensajeDeError(e);
        _cargando = false;
      });
    }
  }

  Future<void> _cargarClima(int id) async {
    ClimaActual? clima;
    try {
      clima = await _externo.clima(consultaClimaEstado(_estado.nombreEstado));
    } catch (_) {
      clima = null; // el clima es opcional: si falla, solo se oculta
    }
    if (!mounted || id != _peticion) return;
    setState(() {
      _clima = clima;
      _cargandoClima = false;
    });
  }

  /// Estado anterior (dir < 0) o siguiente (dir > 0) por nombre.
  Estado? _vecino(int dir) {
    final clave = normalizarNombre(_estado.nombreEstado);
    if (dir > 0) {
      for (final e in widget.navegables) {
        if (normalizarNombre(e.nombreEstado).compareTo(clave) > 0) return e;
      }
      return null;
    }
    for (final e in widget.navegables.reversed) {
      if (normalizarNombre(e.nombreEstado).compareTo(clave) < 0) return e;
    }
    return null;
  }

  void _irA(Estado nuevo) {
    _estado = nuevo;
    _buscarCtrl.clear();
    widget.alCambiar(nuevo);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controlador) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: CustomScrollView(
          controller: controlador,
          slivers: [
            // Manija para arrastrar el panel
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColores.borde,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _cabecera()),
            SliverToBoxAdapter(child: _climaCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TituloSeccion(
                  icono: Icons.eco_outlined,
                  texto: _tituloPlantas(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buscador()),
            ..._listaPlantas(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _cabecera() {
    final anterior = _vecino(-1);
    final siguiente = _vecino(1);
    final clima = _estado.climaPredominante;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTADO',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColores.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _estado.nombreEstado,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: AppColores.titulo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (clima ?? '').isEmpty ? 'Clima no registrado' : clima!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColores.texto,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Estado anterior',
            onPressed: anterior == null ? null : () => _irA(anterior),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Estado siguiente',
            onPressed: siguiente == null ? null : () => _irA(siguiente),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _climaCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Tarjeta(child: _contenidoClima()),
    );
  }

  Widget _contenidoClima() {
    if (_cargandoClima) {
      return const Row(
        children: [
          Skeleton(ancho: 44, alto: 44, radio: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(ancho: 110, alto: 22),
                SizedBox(height: 8),
                Skeleton(alto: 12),
              ],
            ),
          ),
        ],
      );
    }
    final c = _clima;
    if (c == null) {
      return const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: AppColores.texto),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Clima no disponible por ahora.',
              style: TextStyle(color: AppColores.texto),
            ),
          ),
        ],
      );
    }
    final capital = capitalEtiqueta(_estado.nombreEstado);
    final temp = c.temp == null ? '--' : '${c.temp!.round()}°C';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              iconoClimaOpenWeather(c.icono),
              size: 44,
              color: AppColores.verdeOscuro,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temp,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColores.titulo,
                    ),
                  ),
                  Text(
                    c.descripcion ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColores.titulo,
                    ),
                  ),
                  if (capital.isNotEmpty)
                    Text(
                      'Capital: $capital',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColores.texto,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChipInfo(
              icono: Icons.water_drop_outlined,
              texto: 'Humedad ${c.humedad ?? '--'}%',
            ),
            ChipInfo(
              icono: Icons.air_rounded,
              texto: 'Viento ${c.viento?.round() ?? '--'} m/s',
            ),
            ChipInfo(
              icono: Icons.thermostat_rounded,
              texto: 'Sensación ${c.sensacion?.round() ?? '--'}°C',
            ),
          ],
        ),
      ],
    );
  }

  String _tituloPlantas() {
    final datos = _datos;
    if (datos == null) return 'Plantas';
    return 'Plantas (${datos.plantas.length})';
  }

  Widget _buscador() {
    final datos = _datos;
    if (_cargando || datos == null || datos.plantas.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: TextField(
        controller: _buscarCtrl,
        onChanged: (v) =>
            setState(() => _filtro = Validadores.sanearBusqueda(v)),
        maxLength: Limites.busqueda,
        decoration: const InputDecoration(
          hintText: 'Buscar planta',
          counterText: '',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  List<Widget> _listaPlantas() {
    if (_cargando) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, _) => const _FilaSkeleton(),
          ),
        ),
      ];
    }
    final error = _error;
    if (error != null) {
      return [
        SliverToBoxAdapter(
          child: MensajeEstado(
            icono: Icons.wifi_off_rounded,
            texto: error,
            textoBoton: 'Reintentar',
            alPresionar: _cargar,
          ),
        ),
      ];
    }
    final todas = _datos?.plantas ?? const <Planta>[];
    if (todas.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: MensajeEstado(
            icono: Icons.eco_outlined,
            texto: 'Este estado aún no tiene plantas registradas.',
          ),
        ),
      ];
    }
    final q = normalizarNombre(_filtro);
    final lista = q.isEmpty
        ? todas
        : todas
              .where(
                (p) => normalizarNombre(
                  '${p.nombrePlanta} ${p.nombreCientifico ?? ''}',
                ).contains(q),
              )
              .toList();
    if (lista.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: MensajeEstado(
            icono: Icons.search_off_rounded,
            texto: 'Ninguna planta coincide con tu búsqueda.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _FilaPlanta(planta: lista[i]),
        ),
      ),
    ];
  }
}

/// Fila de planta dentro del panel: miniatura, nombre y clima.
class _FilaPlanta extends StatelessWidget {
  final Planta planta;
  const _FilaPlanta({required this.planta});

  @override
  Widget build(BuildContext context) {
    final clima = buscarClima(planta.tipoClima);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadios.tarjeta),
        side: const BorderSide(color: AppColores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlantaDetalleScreen(planta: planta),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ImagenPlanta(url: planta.urlImagen, tamanoIcono: 20),
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
                        fontSize: 15,
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
                    if (clima != null) ...[
                      const SizedBox(height: 4),
                      ChipInfo(icono: clima.icono, texto: clima.etiqueta),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColores.texto),
            ],
          ),
        ),
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
          Skeleton(ancho: 56, alto: 56, radio: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(ancho: 140, alto: 14),
                SizedBox(height: 8),
                Skeleton(ancho: 90, alto: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
