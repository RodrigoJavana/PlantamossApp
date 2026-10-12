// Inicio: banner, saludo, clima de las ciudades, accesos rápidos y noticias.
import 'package:flutter/material.dart';

import '../config/constantes.dart';
import '../config/tema.dart';
import '../models/inicio.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/inicio_service.dart';
import '../services/racha_service.dart';
import '../widgets/comunes.dart';
import '../widgets/imagen_planta.dart';
import '../widgets/tarjeta_racha.dart';

class InicioScreen extends StatefulWidget {
  /// Accesos rápidos: cambian a la pestaña correspondiente.
  final VoidCallback irAPlantas;
  final VoidCallback irAMapa;
  final VoidCallback irABlog;
  const InicioScreen({
    super.key,
    required this.irAPlantas,
    required this.irAMapa,
    required this.irABlog,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _servicio = InicioService();

  // Noticias
  List<Noticia> _noticias = [];
  bool _cargandoNoticias = true;
  String? _errorNoticias;

  // Clima
  List<ClimaCiudad> _clima = [];
  bool _cargandoClima = true;
  String? _errorClima;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() => Future.wait([
    _cargarNoticias(),
    _cargarClima(),
    RachaService.instancia.cargar(),
  ]);

  Future<void> _cargarNoticias() async {
    setState(() {
      _cargandoNoticias = true;
      _errorNoticias = null;
    });
    try {
      _noticias = await _servicio.noticiasRecientes();
    } catch (e) {
      _errorNoticias = mensajeDeError(e);
    }
    if (mounted) setState(() => _cargandoNoticias = false);
  }

  Future<void> _cargarClima() async {
    setState(() {
      _cargandoClima = true;
      _errorClima = null;
    });
    try {
      _clima = await _servicio.climaCiudades();
    } catch (e) {
      _errorClima = mensajeDeError(e);
    }
    if (mounted) setState(() => _cargandoClima = false);
  }

  /// Saludo e ícono según la hora del día.
  (String, IconData) get _saludo {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return ('Buenos días', Icons.wb_sunny_rounded);
    if (h >= 12 && h < 19) return ('Buenas tardes', Icons.wb_twilight_rounded);
    return ('Buenas noches', Icons.nightlight_round);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = AuthService.instancia.usuario?.primerNombre ?? 'Usuario';
    final (textoSaludo, iconoSaludo) = _saludo;

    return RefreshIndicator(
      color: AppColores.verdeOscuro,
      onRefresh: _cargarTodo,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Banner panorámico (sin degradado).
          SizedBox(
            height: 160,
            child: Image.asset(
              'assets/img/banner-inicio.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.1),
              errorBuilder: (_, _, _) => const PlaceholderPlanta(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Saludo
                // Saludo + ícono en la misma línea (el texto se ajusta si es largo).
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$textoSaludo, $nombre',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColores.titulo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(iconoSaludo, color: AppColores.titulo, size: 24),
                  ],
                ),
                const SizedBox(height: 18),
                _tarjetaClima(),
                const TarjetaRachaActual(),
                const SizedBox(height: 16),
                _tarjetaAccesos(),
                const SizedBox(height: 16),
                _tarjetaNoticias(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Clima ----------------
  Widget _tarjetaClima() {
    Widget contenido;
    if (_cargandoClima) {
      contenido = _filaHorizontal(
        List.generate(3, (_) => const _ClimaSkeleton()),
      );
    } else if (_errorClima != null) {
      contenido = MensajeEstado(
        icono: Icons.cloud_off_rounded,
        texto: _errorClima!,
        textoBoton: 'Reintentar',
        alPresionar: _cargarClima,
      );
    } else if (_clima.isEmpty) {
      contenido = const MensajeEstado(
        icono: Icons.location_off_outlined,
        texto: 'Sin ciudades.',
      );
    } else if (_clima.every((c) => c.clima == null)) {
      contenido = MensajeEstado(
        icono: Icons.cloud_off_rounded,
        texto: 'Clima no disponible.',
        textoBoton: 'Reintentar',
        alPresionar: _cargarClima,
      );
    } else {
      contenido = _filaHorizontal(
        _clima.map((c) => _ClimaCard(dato: c)).toList(),
      );
    }

    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(icono: Icons.thermostat_rounded, texto: 'Clima'),
          const SizedBox(height: 14),
          contenido,
        ],
      ),
    );
  }

  Widget _filaHorizontal(List<Widget> hijos) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hijos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => hijos[i],
      ),
    );
  }

  // ---------------- Accesos rápidos ----------------
  Widget _tarjetaAccesos() {
    final accesos = [
      _Acceso(Icons.eco_rounded, 'Plantas', widget.irAPlantas),
      _Acceso(Icons.map_outlined, 'Mapa', widget.irAMapa),
      _Acceso(Icons.edit_note_rounded, 'Blog', widget.irABlog),
      const _Acceso(Icons.smart_display_outlined, 'Videos', null),
    ];
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            icono: Icons.bolt_rounded,
            texto: 'Accesos rápidos',
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: accesos.map((a) => _AccesoCard(acceso: a)).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- Noticias ----------------
  Widget _tarjetaNoticias() {
    Widget contenido;
    if (_cargandoNoticias) {
      contenido = Column(
        children: List.generate(2, (_) => const _NoticiaSkeleton()),
      );
    } else if (_errorNoticias != null) {
      contenido = MensajeEstado(
        icono: Icons.wifi_off_rounded,
        texto: _errorNoticias!,
        textoBoton: 'Reintentar',
        alPresionar: _cargarNoticias,
      );
    } else if (_noticias.isEmpty) {
      contenido = const MensajeEstado(
        icono: Icons.article_outlined,
        texto: 'Aún no hay noticias.',
      );
    } else {
      contenido = Column(
        children: _noticias.map((n) => _NoticiaCard(noticia: n)).toList(),
      );
    }

    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            icono: Icons.article_outlined,
            texto: 'Noticias recientes',
          ),
          const SizedBox(height: 14),
          contenido,
        ],
      ),
    );
  }
}

// ======================= Widgets privados =======================

class _ClimaCard extends StatelessWidget {
  final ClimaCiudad dato;
  const _ClimaCard({required this.dato});

  @override
  Widget build(BuildContext context) {
    final c = dato.clima;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColores.borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dato.ciudad.ciudad,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColores.titulo,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                c == null
                    ? Icons.thermostat_rounded
                    : iconoClimaOpenWeather(c.icono),
                color: AppColores.texto,
                size: 26,
              ),
              const SizedBox(width: 6),
              Text(
                c == null ? '—°C' : '${c.temp.round()}°C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColores.titulo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c == null ? 'Sin datos' : _capitalizar(c.descripcion),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColores.texto),
          ),
          const Spacer(),
          if (c != null)
            Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 13,
                  color: AppColores.texto,
                ),
                Text(
                  ' ${c.humedad}%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColores.texto,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.air_rounded,
                  size: 13,
                  color: AppColores.texto,
                ),
                Text(
                  ' ${c.viento.round()} m/s',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColores.texto,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _capitalizar(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

class _ClimaSkeleton extends StatelessWidget {
  const _ClimaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColores.borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(ancho: 80),
          SizedBox(height: 12),
          Skeleton(ancho: 90, alto: 26),
          SizedBox(height: 10),
          Skeleton(ancho: 70, alto: 10),
        ],
      ),
    );
  }
}

class _Acceso {
  final IconData icono;
  final String nombre;
  final VoidCallback? alTocar; // null = "Próximamente"
  const _Acceso(this.icono, this.nombre, this.alTocar);
}

class _AccesoCard extends StatelessWidget {
  final _Acceso acceso;
  const _AccesoCard({required this.acceso});

  @override
  Widget build(BuildContext context) {
    final activo = acceso.alTocar != null;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: acceso.alTocar,
        child: Opacity(
          opacity: activo ? 1 : 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: activo ? AppColores.verdeSuave : AppColores.grisChip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  acceso.icono,
                  color: activo ? AppColores.verdeOscuro : AppColores.titulo,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                acceso.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: AppColores.titulo,
                ),
              ),
              if (!activo)
                const Text(
                  'Próximamente',
                  style: TextStyle(fontSize: 10.5, color: AppColores.texto),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  final Noticia noticia;
  const _NoticiaCard({required this.noticia});

  String get _extracto {
    final t = noticia.contenido.trim();
    return t.length > 140 ? '${t.substring(0, 140).trimRight()}...' : t;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColores.borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: ImagenPlanta(url: noticia.urlImagen),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (noticia.destacada)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColores.grisChip,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppColores.titulo,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Destacada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColores.titulo,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  noticia.titulo,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColores.titulo,
                  ),
                ),
                if (noticia.fechaCorta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    noticia.fechaCorta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColores.texto,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _extracto,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColores.texto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticiaSkeleton extends StatelessWidget {
  const _NoticiaSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(alto: 140, radio: 12),
          SizedBox(height: 10),
          Skeleton(ancho: 220),
          SizedBox(height: 8),
          Skeleton(),
        ],
      ),
    );
  }
}
