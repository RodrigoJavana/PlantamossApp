// Pruebas de las insignias: lectura robusta del JSON y tarjeta bloqueada/ganada.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plantamoss/models/insignia.dart';
import 'package:plantamoss/widgets/insignia_tarjeta.dart';

void main() {
  group('Insignia.fromJson', () {
    test('lee la respuesta completa de la API', () {
      final i = Insignia.fromJson({
        'codigo': 'amigo_del_nopal',
        'titulo': 'Amigo del nopal',
        'descripcion': 'Conoce 10 plantas mexicanas.',
        'icono': 'hoja',
        'categoria': 'Plantas',
        'tono': 'Plantas',
        'meta': 10,
        'avance': 4,
        'progreso': 40,
        'desbloqueada': false,
        'desbloqueadaEn': null,
      });

      expect(i.codigo, 'amigo_del_nopal');
      expect(i.titulo, 'Amigo del nopal');
      expect(i.icono, 'hoja');
      expect(i.categoria, 'Plantas');
      expect(i.tono, 'Plantas');
      expect(i.meta, 10);
      expect(i.avance, 4);
      expect(i.progreso, 40);
      expect(i.avanceFraccion, closeTo(0.4, 0.0001));
      expect(i.desbloqueada, isFalse);
      expect(i.desbloqueadaEn, isNull);
    });

    test('tolera nulls, números como texto y fechas inválidas', () {
      final i = Insignia.fromJson({
        'codigo': 'primer_brote',
        'titulo': null,
        'descripcion': null,
        'icono': '',
        'categoria': null,
        'meta': '1',
        'avance': 7.0,
        'progreso': '150',
        'desbloqueada': 'true',
        'desbloqueadaEn': 'no es fecha',
      });

      expect(i.titulo, 'primer_brote');
      expect(i.descripcion, '');
      expect(i.icono, 'brote');
      expect(i.categoria, 'Plantas');
      // Sin tono, la medalla usa la categoría.
      expect(i.tono, 'Plantas');
      expect(i.meta, 1);
      // El avance nunca pasa de la meta y el progreso tiene tope de 100.
      expect(i.avance, 1);
      expect(i.progreso, 100);
      expect(i.desbloqueada, isTrue);
      expect(i.desbloqueadaEn, isNull);
    });

    test('lee el tono cuando viene en la respuesta', () {
      final i = Insignia.fromJson({
        'codigo': 'nochebuena',
        'categoria': 'Fechas',
        'tono': 'navidad',
        'meta': 1,
        'avance': 0,
        'progreso': 0,
        'desbloqueada': false,
      });
      expect(i.categoria, 'Fechas');
      expect(i.tono, 'navidad');
    });

    test('si el tono viene vacío o null usa la categoría', () {
      final vacio = Insignia.fromJson({
        'codigo': 'x',
        'categoria': 'Blog',
        'tono': '  ',
      });
      final nulo = Insignia.fromJson({
        'codigo': 'x',
        'categoria': 'Racha',
        'tono': null,
      });
      expect(vacio.tono, 'Blog');
      expect(nulo.tono, 'Racha');
    });

    test('lee la fecha de obtención', () {
      final i = Insignia.fromJson({
        'codigo': 'pulgar_verde',
        'meta': 7,
        'avance': 7,
        'progreso': 100,
        'desbloqueada': true,
        'desbloqueadaEn': '2026-10-21T12:00:00Z',
      });
      expect(i.desbloqueadaEn, isNotNull);
      expect(i.desbloqueadaEn!.toUtc(), DateTime.utc(2026, 10, 21, 12, 0));
    });
  });

  group('Colores e íconos', () {
    test('Fechas tiene su color de categoría', () {
      expect(colorDeCategoria('Fechas'), const Color(0xFFB5121B));
    });

    test(
      'colorDeTono usa el color del tono cuando existe y si no el de la categoría',
      () {
        expect(colorDeTono('rojo', 'Fechas'), const Color(0xFFD7261E));
        expect(colorDeTono('navidad', 'Fechas'), const Color(0xFFB5121B));
        expect(colorDeTono('morado', 'Fechas'), const Color(0xFF8A4FD8));
        expect(colorDeTono('Plantas', 'Plantas'), colorDeCategoria('Plantas'));
        expect(colorDeTono('', 'Mapa'), colorDeCategoria('Mapa'));
      },
    );

    test('iconos nuevos del contrato', () {
      expect(iconoInsignia('corazon'), Icons.favorite_rounded);
      expect(iconoInsignia('nochebuena'), Icons.filter_vintage_rounded);
      expect(iconoInsignia('jacaranda'), Icons.park_rounded);
    });
  });

  group('InsigniaTarjeta', () {
    Insignia crear({required bool ganada}) => Insignia.fromJson({
      'codigo': 'viajero',
      'titulo': 'Viajero de la República',
      'descripcion': 'Explora 5 estados en el mapa.',
      'icono': 'mapa',
      'categoria': 'Mapa',
      'tono': 'Mapa',
      'meta': 5,
      'avance': ganada ? 5 : 2,
      'progreso': ganada ? 100 : 40,
      'desbloqueada': ganada,
      'desbloqueadaEn': ganada ? '2026-10-21T12:00:00Z' : null,
    });

    Widget envolver(Insignia i) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 300,
          child: InsigniaTarjeta(insignia: i),
        ),
      ),
    );

    testWidgets('bloqueada: en gris, con candado y sin fecha', (tester) async {
      await tester.pumpWidget(envolver(crear(ganada: false)));
      await tester.pumpAndSettle();

      expect(find.text('Viajero de la República'), findsOneWidget);
      expect(find.text('2 / 5'), findsOneWidget);
      expect(find.byKey(const Key('candado_insignia')), findsOneWidget);
      // Gris por tonos, sin filtro ni destello.
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byKey(const Key('destello_insignia')), findsNothing);
      expect(find.textContaining('Obtenida el'), findsNothing);
    });

    testWidgets('ganada: a color, sin candado y con la fecha', (tester) async {
      await tester.pumpWidget(envolver(crear(ganada: true)));
      await tester.pumpAndSettle();

      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.byKey(const Key('candado_insignia')), findsNothing);
      expect(find.byType(ColorFiltered), findsNothing);
      // El destello pasó una vez y ya terminó (pumpAndSettle).
      expect(find.byKey(const Key('destello_insignia')), findsOneWidget);
      expect(find.text('Obtenida el 21/10/2026'), findsOneWidget);
    });

    testWidgets('tono navidad: se dibuja ganada sin errores', (tester) async {
      final i = Insignia.fromJson({
        'codigo': 'nochebuena',
        'titulo': 'Flor de Nochebuena',
        'descripcion': 'Entra a Plantamoss en Navidad.',
        'icono': 'nochebuena',
        'categoria': 'Fechas',
        'tono': 'navidad',
        'meta': 1,
        'avance': 1,
        'progreso': 100,
        'desbloqueada': true,
        'desbloqueadaEn': '2026-12-24T18:00:00Z',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: InsigniaTarjeta(insignia: i),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flor de Nochebuena'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.byKey(const Key('candado_insignia')), findsNothing);
    });
  });
}
