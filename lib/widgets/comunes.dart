// Widgets pequeños reutilizables: skeleton, mensajes de estado,
// chips de información, tarjeta blanca y logo de la marca.
import 'package:flutter/material.dart';

import '../config/tema.dart';

/// Rectángulo gris que "parpadea" mientras se cargan los datos.
class Skeleton extends StatefulWidget {
  final double? ancho;
  final double alto;
  final double radio;
  const Skeleton({super.key, this.ancho, this.alto = 14, this.radio = 8});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_ctrl),
      child: Container(
        width: widget.ancho,
        height: widget.alto,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDEA),
          borderRadius: BorderRadius.circular(widget.radio),
        ),
      ),
    );
  }
}

/// Mensaje centrado para estados vacíos o de error, con botón opcional.
class MensajeEstado extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String? textoBoton;
  final VoidCallback? alPresionar;

  const MensajeEstado({
    super.key,
    required this.icono,
    required this.texto,
    this.textoBoton,
    this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 36, color: AppColores.texto),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColores.texto),
          ),
          if (textoBoton != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: alPresionar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(textoBoton!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip pequeño con ícono (estado, clima, luz, riego).
class ChipInfo extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool grande;
  const ChipInfo({
    super.key,
    required this.icono,
    required this.texto,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: grande ? 12 : 8,
        vertical: grande ? 7 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColores.grisChip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: grande ? 16 : 13, color: AppColores.verdeOscuro),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: grande ? 13 : 11.5,
                fontWeight: FontWeight.w600,
                color: AppColores.titulo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca con borde sutil (sin sombras pesadas).
class Tarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Tarjeta({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadios.tarjeta),
        border: Border.all(color: AppColores.borde),
      ),
      child: child,
    );
  }
}

/// Título de sección: ícono + texto en negro.
class TituloSeccion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Widget? accion;
  const TituloSeccion({
    super.key,
    required this.icono,
    required this.texto,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 19, color: AppColores.titulo),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColores.titulo,
            ),
          ),
        ),
        ?accion,
      ],
    );
  }
}

/// Logo + "plantamoss" en minúsculas y negritas (como la web).
class LogoMarca extends StatelessWidget {
  final bool claro; // true = sobre fondo verde
  final double tamano;
  const LogoMarca({super.key, this.claro = true, this.tamano = 30});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          claro ? 'assets/img/logo-claro.png' : 'assets/img/logo.png',
          height: tamano,
          width: tamano,
        ),
        const SizedBox(width: 8),
        Text(
          'plantamoss',
          style: TextStyle(
            color: claro ? Colors.white : AppColores.titulo,
            fontWeight: FontWeight.w800,
            fontSize: tamano * 0.68,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Aviso discreto cuando el servidor usa http (sin cifrar).
class AvisoSinCifrar extends StatelessWidget {
  const AvisoSinCifrar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: Key('aviso_sin_cifrar'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_open_rounded, size: 14, color: Color(0xFFB26A00)),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            'Conexión no cifrada (solo desarrollo)',
            style: TextStyle(fontSize: 12, color: Color(0xFFB26A00)),
          ),
        ),
      ],
    );
  }
}
