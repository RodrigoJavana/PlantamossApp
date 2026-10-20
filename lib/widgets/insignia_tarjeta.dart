// Tarjeta de una insignia (bloqueada o ganada) y el aviso "¡Ganaste una insignia!".
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/insignia.dart';
import 'comunes.dart';

/// Ícono por clave del contrato (Material Icons, sin emojis).
IconData iconoInsignia(String clave) {
  switch (clave) {
    case 'brote':
      return Icons.spa_outlined;
    case 'hoja':
      return Icons.eco_rounded;
    case 'flor':
      return Icons.local_florist_rounded;
    case 'mapa':
      return Icons.map_rounded;
    case 'brujula':
      return Icons.explore_rounded;
    case 'libro':
      return Icons.menu_book_rounded;
    case 'escribir':
      return Icons.edit_note_rounded;
    case 'gota':
      return Icons.water_drop_rounded;
    case 'sol':
      return Icons.wb_sunny_rounded;
    case 'corazon':
      return Icons.favorite_rounded;
    case 'nochebuena':
      return Icons.filter_vintage_rounded;
    case 'jacaranda':
      return Icons.park_rounded;
    default:
      return Icons.military_tech_rounded;
  }
}

/// Color sólido por categoría: Plantas verde, Mapa terracota, Blog azul, Racha naranja, Fechas rojo.
Color colorDeCategoria(String categoria) {
  switch (categoria.trim().toLowerCase()) {
    case 'plantas':
      return AppColores.verdeIntenso;
    case 'mapa':
      return const Color(0xFFB5563A);
    case 'blog':
      return const Color(0xFF1F6FB2);
    case 'racha':
      return const Color(0xFFE67E22);
    case 'fechas':
      return const Color(0xFFB5121B);
    default:
      return AppColores.verdeOscuro;
  }
}

/// Color de la barra y textos: el del tono si tiene uno propio; si no, el de la categoría.
Color colorDeTono(String tono, String categoria) {
  switch (tono.trim().toLowerCase()) {
    case 'rojo':
      return const Color(0xFFD7261E);
    case 'navidad':
      return const Color(0xFFB5121B);
    case 'morado':
      return const Color(0xFF8A4FD8);
    default:
      return colorDeCategoria(categoria);
  }
}

/// Tonos de la medalla: claro, base, oscuro y borde (mismos que la web).
class _Tonos {
  final Color claro;
  final Color base;
  final Color oscuro;
  final Color borde;
  const _Tonos(this.claro, this.base, this.oscuro, this.borde);
}

const _tonosPlantas = _Tonos(
  Color(0xFFA5E0A0),
  Color(0xFF3F9B46),
  Color(0xFF1D5E25),
  Color(0xFFD9F2C9),
);
const _tonosMapa = _Tonos(
  Color(0xFFF3B98F),
  Color(0xFFB5603A),
  Color(0xFF6E3216),
  Color(0xFFF7DCC4),
);
const _tonosBlog = _Tonos(
  Color(0xFF9CC8FF),
  Color(0xFF2B7BD6),
  Color(0xFF0F468C),
  Color(0xFFD3E6FF),
);
const _tonosRacha = _Tonos(
  Color(0xFFFFE07A),
  Color(0xFFF29A0E),
  Color(0xFFA65400),
  Color(0xFFFFF1B8),
);
const _tonosRojo = _Tonos(
  Color(0xFFFF9A8A),
  Color(0xFFD7261E),
  Color(0xFF7E0F0B),
  Color(0xFFFFD3CC),
);
const _tonosNavidad = _Tonos(
  Color(0xFFFF7A85),
  Color(0xFFB5121B),
  Color(0xFF5E050B),
  Color(0xFFFFE08A),
);
const _tonosMorado = _Tonos(
  Color(0xFFD2B4FF),
  Color(0xFF8A4FD8),
  Color(0xFF4A1F8C),
  Color(0xFFEADCFF),
);
const _tonosBloqueada = _Tonos(
  Color(0xFFEEF1EF),
  Color(0xFFBCC5BF),
  Color(0xFF8A958D),
  Color(0xFFF4F6F5),
);

/// Paleta por tono; si el tono no se reconoce, usa la de la categoría.
_Tonos _tonosDe(String tono, String categoria) {
  switch (tono.trim().toLowerCase()) {
    case 'plantas':
      return _tonosPlantas;
    case 'mapa':
      return _tonosMapa;
    case 'blog':
      return _tonosBlog;
    case 'racha':
      return _tonosRacha;
    case 'rojo':
      return _tonosRojo;
    case 'navidad':
      return _tonosNavidad;
    case 'morado':
      return _tonosMorado;
    default:
      return _tonosDeCategoria(categoria);
  }
}

_Tonos _tonosDeCategoria(String categoria) {
  switch (categoria.trim().toLowerCase()) {
    case 'mapa':
      return _tonosMapa;
    case 'blog':
      return _tonosBlog;
    case 'racha':
      return _tonosRacha;
    default:
      return _tonosPlantas;
  }
}

// Colores de brillo y sombra (con alfa fijo).
const _brilloReflejo = Color(0xBFFFFFFF); // blanco 75%
const _brilloBloqueada = Color(0x59FFFFFF); // blanco 35%
const _sombraInterna = Color(0x40000000); // negro 25%
const _sombraMedalla = Color(0x2E000000); // negro 18%
const _sombraIcono = Color(0x59000000); // negro 35%
const _destelloCentro = Color(0x99FFFFFF);
const _transparente = Color(0x00FFFFFF);

String _fecha(DateTime f) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year}';
}

/// Medalla 3D con brillo. Si está bloqueada sale en gris, sin destello y con candado.
class MedallaInsignia extends StatefulWidget {
  final Insignia insignia;
  final double tamano;

  /// Si es true, el destello se repite en bucle; si no, pasa una vez al aparecer.
  final bool enBucle;

  const MedallaInsignia({
    super.key,
    required this.insignia,
    this.tamano = 64,
    this.enBucle = false,
  });

  @override
  State<MedallaInsignia> createState() => _MedallaInsigniaState();
}

class _MedallaInsigniaState extends State<MedallaInsignia>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>? _pos;
  bool _destello = false; // hay destello visible
  bool _pasada = false; // el destello ya pasó una vez

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  @override
  void didUpdateWidget(MedallaInsignia anterior) {
    super.didUpdateWidget(anterior);
    _sincronizar();
  }

  // Arranca o detiene el destello según si está ganada y si el sistema permite animar.
  void _sincronizar() {
    final sinAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final debeBrillar = widget.insignia.desbloqueada && !sinAnim;
    _destello = debeBrillar;
    if (!debeBrillar) {
      _pasada = false;
      _ctrl?.stop();
      return;
    }
    _ctrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pos ??= CurvedAnimation(
      parent: _ctrl!,
      curve: const Interval(0, 0.7, curve: Curves.easeInOut),
    );
    if (widget.enBucle) {
      if (!_ctrl!.isAnimating) _ctrl!.repeat();
    } else if (!_pasada) {
      _pasada = true;
      _ctrl!.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.tamano;
    final i = widget.insignia;
    final bloqueada = !i.desbloqueada;
    final t = bloqueada ? _tonosBloqueada : _tonosDe(i.tono, i.categoria);
    final icono = iconoInsignia(i.icono);

    final medalla = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Aro metálico exterior con sombra suave hacia abajo.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.borde, t.base, t.oscuro],
        ),
        boxShadow: [
          BoxShadow(
            color: _sombraMedalla,
            blurRadius: s * 0.18,
            offset: Offset(0, s * 0.08),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Disco interior: degradado radial desplazado a arriba-izquierda con sombra abajo.
            Padding(
              padding: EdgeInsets.all(s * 0.07),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.36, -0.48),
                    radius: 0.9,
                    colors: [t.claro, t.base, t.oscuro],
                    stops: const [0, 0.52, 1],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_transparente, _transparente, _sombraInterna],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
            ),
            // Reflejo superior en óvalo; en bloqueada, al 35%.
            Positioned(
              top: s * 0.06,
              left: s * 0.16,
              width: s * 0.68,
              height: s * 0.42,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const OvalBorder(),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bloqueada ? _brilloBloqueada : _brilloReflejo,
                      _transparente,
                    ],
                  ),
                ),
              ),
            ),
            // Destello: banda diagonal blanca recortada por el círculo.
            if (_destello && _pos != null)
              AnimatedBuilder(
                key: const Key('destello_insignia'),
                animation: _pos!,
                builder: (_, child) {
                  final x = s * (-0.9 + 1.8 * _pos!.value);
                  return Transform.rotate(
                    angle: -0.6,
                    child: Transform.translate(
                      offset: Offset(x, 0),
                      child: child,
                    ),
                  );
                },
                child: Center(
                  child: Container(
                    width: s * 0.3,
                    height: s * 2.4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_transparente, _destelloCentro, _transparente],
                      ),
                    ),
                  ),
                ),
              ),
            // Ícono blanco centrado; en bloqueada, algo transparente y sin sombra.
            Center(
              child: bloqueada
                  ? Opacity(
                      opacity: 0.85,
                      child: Icon(icono, color: Colors.white, size: s * 0.44),
                    )
                  : Icon(
                      icono,
                      color: Colors.white,
                      size: s * 0.44,
                      shadows: const [
                        Shadow(
                          color: _sombraIcono,
                          offset: Offset(0, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    if (!bloqueada) return medalla;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        medalla,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            key: const Key('candado_insignia'),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColores.borde),
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 14,
              color: AppColores.texto,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de una insignia para la cuadrícula. Ocupa todo el alto que le den.
class InsigniaTarjeta extends StatelessWidget {
  final Insignia insignia;
  const InsigniaTarjeta({super.key, required this.insignia});

  @override
  Widget build(BuildContext context) {
    final i = insignia;
    final color = colorDeTono(i.tono, i.categoria);
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          MedallaInsignia(insignia: i, tamano: 64),
          const SizedBox(height: 12),
          Text(
            i.titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColores.titulo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i.descripcion,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColores.texto,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: i.avanceFraccion,
              minHeight: 6,
              color: color,
              backgroundColor: AppColores.grisChip,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${i.avance} / ${i.meta}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (i.desbloqueada && i.desbloqueadaEn != null) ...[
            const SizedBox(height: 4),
            Text(
              'Obtenida el ${_fecha(i.desbloqueadaEn!)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aviso "¡Ganaste una insignia!". Devuelve true si el usuario toca "Ver mis insignias".
class InsigniaGanadaDialogo extends StatelessWidget {
  final Insignia insignia;
  const InsigniaGanadaDialogo({super.key, required this.insignia});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('¡Ganaste una insignia!', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // La medalla crece con un pequeño rebote y el destello se repite.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (_, escala, child) =>
                Transform.scale(scale: escala, child: child),
            child: MedallaInsignia(
              insignia: insignia,
              tamano: 112,
              enBucle: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            insignia.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColores.titulo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insignia.descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColores.texto),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ver mis insignias'),
        ),
      ],
    );
  }
}
