// Planta dibujada a mano (CustomPainter) según la etapa de la racha.
// Cada etapa crece desde la semilla con una animación suave.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/tema.dart';

class PlantaRacha extends StatelessWidget {
  final int etapa; // 0..5
  final double tamano;
  const PlantaRacha({super.key, required this.etapa, this.tamano = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      // La key por etapa hace que la animación se repita al cambiar de etapa.
      child: TweenAnimationBuilder<double>(
        key: ValueKey(etapa),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, crecimiento, _) => CustomPaint(
          painter: _PlantaPainter(etapa: etapa, crecimiento: crecimiento),
        ),
      ),
    );
  }
}

class _PlantaPainter extends CustomPainter {
  final int etapa;
  final double crecimiento; // 0..1

  _PlantaPainter({required this.etapa, required this.crecimiento});

  static const _maceta = Color(0xFFB8734F);
  static const _macetaBorde = Color(0xFFC9845F);
  static const _tierra = Color(0xFF5D4037);
  static const _semilla = Color(0xFF8D6E63);
  static const _flor = Color(0xFFEF8AAE);
  static const _centroFlor = Color(0xFFFFD54F);

  // Altura del tallo por etapa (fracción de la altura total).
  static const _alturas = [0.0, 0.12, 0.24, 0.36, 0.44, 0.48];

  // Hojas por etapa: pares (posición en el tallo 0..1, largo como fracción).
  static const _hojas = [
    <(double, double)>[],
    <(double, double)>[(0.9, 0.09)],
    <(double, double)>[(0.6, 0.11), (1.0, 0.09)],
    <(double, double)>[(0.35, 0.13), (0.65, 0.13), (0.95, 0.10)],
    <(double, double)>[(0.3, 0.16), (0.55, 0.16), (0.8, 0.14), (1.0, 0.12)],
    <(double, double)>[(0.3, 0.16), (0.55, 0.16), (0.8, 0.14), (1.0, 0.12)],
  ];

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final cx = w / 2;
    final sueloY = h * 0.715;

    _dibujarMaceta(c, w, h);

    if (etapa <= 0) {
      // Semilla: un óvalo en la tierra.
      final paint = Paint()..color = _semilla;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx, sueloY - h * 0.012),
          width: w * 0.09,
          height: h * 0.05,
        ),
        paint,
      );
      return;
    }

    final e = etapa > _alturas.length - 1 ? _alturas.length - 1 : etapa;
    final altura = h * _alturas[e] * crecimiento;
    final base = Offset(cx, sueloY);
    final top = Offset(cx, sueloY - altura);
    final curva = w * 0.03; // curvatura del tallo

    // Tallo (curva cuadrática; su punto a fracción f está en y = base - altura*f).
    final tallo = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + curva,
        base.dy - altura * 0.5,
        top.dx,
        top.dy,
      );
    c.drawPath(
      tallo,
      Paint()
        ..color = AppColores.verde
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.5, w * 0.03)
        ..strokeCap = StrokeCap.round,
    );

    // Copa frondosa (etapas 4 y 5).
    if (etapa >= 4) {
      final copa = Paint()..color = AppColores.verdeIntenso;
      final r = h * 0.08 * crecimiento;
      c.drawCircle(top + Offset(-w * 0.08, h * 0.02 * crecimiento), r, copa);
      c.drawCircle(top + Offset(w * 0.08, h * 0.02 * crecimiento), r, copa);
      c.drawCircle(top + Offset(0, -h * 0.03 * crecimiento), r * 1.1, copa);
    }

    // Hojas a ambos lados del tallo, alternando el verde.
    for (final (i, (f, largo)) in _hojas[e].indexed) {
      final punto = Offset(cx + 2 * f * (1 - f) * curva, sueloY - altura * f);
      final color = i.isEven ? AppColores.verde : AppColores.verdeIntenso;
      final l = h * largo * crecimiento;
      _hoja(c, punto, -math.pi / 2 + 0.6, l, color);
      _hoja(c, punto, -math.pi / 2 - 0.6, l, color);
    }

    if (etapa == 5) _flores(c, top, w, h);
  }

  void _dibujarMaceta(Canvas c, double w, double h) {
    final cuerpo = Path()
      ..moveTo(w * 0.24, h * 0.80)
      ..lineTo(w * 0.76, h * 0.80)
      ..lineTo(w * 0.66, h * 0.97)
      ..lineTo(w * 0.34, h * 0.97)
      ..close();
    c.drawPath(cuerpo, Paint()..color = _maceta);

    final borde = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.72, w * 0.6, h * 0.085),
      Radius.circular(h * 0.03),
    );
    c.drawRRect(borde, Paint()..color = _macetaBorde);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.27, h * 0.715, w * 0.46, h * 0.03),
        Radius.circular(h * 0.015),
      ),
      Paint()..color = _tierra,
    );
  }

  /// Hoja: forma de gota desde [base] en el ángulo [angulo] (radianes).
  void _hoja(Canvas c, Offset base, double angulo, double largo, Color color) {
    if (largo <= 0) return;
    final ancho = largo * 0.38;
    final forma = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(largo * 0.5, -ancho, largo, 0)
      ..quadraticBezierTo(largo * 0.5, ancho, 0, 0)
      ..close();
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angulo);
    c.drawPath(forma, Paint()..color = color);
    c.restore();
  }

  /// Tres flores de cinco pétalos en la copa.
  void _flores(Canvas c, Offset top, double w, double h) {
    final centros = [
      top + Offset(-w * 0.14, -h * 0.03 * crecimiento),
      top + Offset(w * 0.13, -h * 0.06 * crecimiento),
      top + Offset(0, -h * 0.13 * crecimiento),
    ];
    final r = w * 0.05 * crecimiento;
    final petalo = Paint()..color = _flor;
    for (final centro in centros) {
      for (var k = 0; k < 5; k++) {
        final a = -math.pi / 2 + k * 2 * math.pi / 5;
        c.drawCircle(
          centro + Offset(math.cos(a), math.sin(a)) * r,
          r * 0.6,
          petalo,
        );
      }
      c.drawCircle(centro, r * 0.45, Paint()..color = _centroFlor);
    }
  }

  @override
  bool shouldRepaint(covariant _PlantaPainter old) =>
      old.etapa != etapa || old.crecimiento != crecimiento;
}
