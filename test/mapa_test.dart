// Pruebas del mapa: geografía de los estados, nombres, clima y estado con plantas.
import 'package:flutter_test/flutter_test.dart';

import 'package:plantamoss/models/clima.dart';
import 'package:plantamoss/models/estado_mapa.dart';
import 'package:plantamoss/models/planta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizarNombre', () {
    test('quita acentos, mayúsculas y espacios extra', () {
      expect(normalizarNombre('  Estado de México '), 'estado de mexico');
      expect(normalizarNombre('Michoacán'), 'michoacan');
      expect(normalizarNombre('Nuevo León'), 'nuevo leon');
    });
  });

  group('parsearPathSvg', () {
    test('un cuadrado contiene el centro y no contiene puntos fuera', () {
      final path = parsearPathSvg('M0,0 L10,0 L10,10 L0,10 Z');

      expect(path.contains(const Offset(5, 5)), isTrue);
      expect(path.contains(const Offset(20, 5)), isFalse);
    });

    test('soporta varios subcaminos (M ... Z M ... Z)', () {
      final path = parsearPathSvg(
        'M0,0 L4,0 L4,4 L0,4 Z M20,20 L24,20 L24,24 L20,24 Z',
      );

      expect(path.contains(const Offset(2, 2)), isTrue);
      expect(path.contains(const Offset(22, 22)), isTrue);
      expect(path.contains(const Offset(10, 10)), isFalse);
    });
  });

  test('cargarMapaMexico lee los 32 estados con contorno y clave', () async {
    final estados = await cargarMapaMexico();

    expect(estados, hasLength(32));
    final cdmx = estados.firstWhere((e) => e.clave == 'ciudad de mexico');
    expect(cdmx.nombre, 'Ciudad de México');
    // Todos los estados caben en el viewBox del mapa.
    for (final e in estados) {
      final b = e.path.getBounds();
      expect(b.left, greaterThanOrEqualTo(-1));
      expect(b.right, lessThanOrEqualTo(kMapaAncho + 1));
      expect(b.bottom, lessThanOrEqualTo(kMapaAlto + 1));
    }
  });

  test('capitales y consulta de clima por estado', () {
    expect(consultaClimaEstado('Ciudad de México'), 'Mexico City,MX');
    expect(capitalEtiqueta('Yucatán'), 'Mérida');
    // Un estado sin capital registrada usa su nombre.
    expect(consultaClimaEstado('Algo Nuevo'), 'Algo Nuevo,MX');
    expect(capitalEtiqueta('Algo Nuevo'), '');
  });

  test('ClimaActual.fromJson lee ClimaDto y ok', () {
    final c = ClimaActual.fromJson({
      'ok': true,
      'temp': 23.6,
      'sensacion': 22.1,
      'humedad': 40,
      'viento': 3.5,
      'descripcion': 'cielo claro',
      'icono': '01d',
    });

    expect(c.ok, isTrue);
    expect(c.temp, 23.6);
    expect(c.humedad, 40);
    expect(c.icono, '01d');

    final fallo = ClimaActual.fromJson({'ok': false});
    expect(fallo.ok, isFalse);
    expect(fallo.temp, isNull);
  });

  test('EstadoConPlantas.fromJson lee estado y plantas', () {
    final r = EstadoConPlantas.fromJson({
      'estado': {
        'idEstado': 9,
        'nombreEstado': 'Oaxaca',
        'climaPredominante': 'Templado',
        'cantidadPlantas': 1,
      },
      'plantas': [
        {
          'idPlanta': 4,
          'nombrePlanta': 'Biznaga',
          'letraInicial': 'B',
          'idEstado': 9,
          'nombreEstado': 'Oaxaca',
          'tipoClima': 'arido',
          'luzSol': 'sol_directo',
        },
      ],
    });

    expect(r.estado.idEstado, 9);
    expect(r.estado.nombreEstado, 'Oaxaca');
    expect(r.estado.cantidadPlantas, 1);
    expect(r.plantas, hasLength(1));
    expect(r.plantas.first.nombrePlanta, 'Biznaga');
    expect(r.plantas.first.tipoClima, 'arido');
  });

  test('EstadoConPlantas tolera respuesta sin plantas', () {
    final r = EstadoConPlantas.fromJson({
      'estado': {'idEstado': 1, 'nombreEstado': 'Sonora'},
    });

    expect(r.plantas, isEmpty);
  });
}
