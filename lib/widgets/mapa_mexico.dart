// Mapa de México: dibuja los 32 estados con CustomPainter y detecta el toque
// con Path.contains. Zoom y arrastre con InteractiveViewer.
import 'package:flutter/material.dart';

import '../models/estado_mapa.dart';

const Color _colorMar = Color(0xFFE1F5FE);
const Color _relleno = Color(0xFFA5D6A7);
const Color _rellenoSin = Color(0xFFF5F5F5);
const Color _bordeSin = Color(0xFFCCCCCC);
const Color _rellenoActivo = Color(0xFF2E7D32);
const Color _bordeActivo = Color(0xFF003300);

class MapaMexico extends StatelessWidget {
  final List<EstadoMapa> estados;

  /// Claves de los estados que tienen plantas registradas.
  final Set<String> conDatos;

  /// Clave del estado seleccionado (o null).
  final String? seleccionado;
  final ValueChanged<EstadoMapa> alTocar;

  const MapaMexico({
    super.key,
    required this.estados,
    required this.conDatos,
    required this.seleccionado,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kMapaAncho / kMapaAlto,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: _colorMar,
          child: InteractiveViewer(
            maxScale: 6,
            child: LayoutBuilder(
              builder: (context, c) {
                final escala = c.maxWidth / kMapaAncho;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tocar(d.localPosition, escala),
                  child: CustomPaint(
                    size: Size(c.maxWidth, c.maxHeight),
                    painter: _PintorMapa(
                      estados: estados,
                      conDatos: conDatos,
                      seleccionado: seleccionado,
                      escala: escala,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _tocar(Offset punto, double escala) {
    final v = punto / escala + const Offset(kMapaX, kMapaY); // pasa a coordenadas de los contornos
    for (final e in estados.reversed) {
      if (e.path.contains(v)) {
        alTocar(e);
        return;
      }
    }
  }
}

class _PintorMapa extends CustomPainter {
  final List<EstadoMapa> estados;
  final Set<String> conDatos;
  final String? seleccionado;
  final double escala;

  _PintorMapa({
    required this.estados,
    required this.conDatos,
    required this.seleccionado,
    required this.escala,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(escala);
    canvas.translate(-kMapaX, -kMapaY);
    final relleno = Paint()..style = PaintingStyle.fill;
    final borde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // El seleccionado va al final para que su borde quede encima.
    final ordenados = [
      ...estados.where((e) => e.clave != seleccionado),
      ...estados.where((e) => e.clave == seleccionado),
    ];
    for (final e in ordenados) {
      final activo = e.clave == seleccionado;
      final datos = conDatos.contains(e.clave);
      relleno.color = activo
          ? _rellenoActivo
          : (datos ? _relleno : _rellenoSin);
      borde.color = activo ? _bordeActivo : (datos ? Colors.white : _bordeSin);
      borde.strokeWidth = activo ? 3 : (datos ? 1.5 : 1);
      canvas.drawPath(e.path, relleno);
      canvas.drawPath(e.path, borde);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorMapa old) =>
      old.escala != escala ||
      old.seleccionado != seleccionado ||
      old.estados != estados ||
      old.conDatos != conDatos;
}
