// Pruebas de la racha: lectura robusta del JSON y tarjeta en pantalla.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plantamoss/models/racha.dart';
import 'package:plantamoss/widgets/tarjeta_racha.dart';

void main() {
  group('Racha.fromJson', () {
    test('lee la respuesta completa de la API', () {
      final r = Racha.fromJson({
        'rachaActual': 5,
        'rachaMaxima': 9,
        'totalDias': 12,
        'ultimoDia': '2026-10-21',
        'registradaHoy': true,
        'etapa': 3,
        'nombreEtapa': 'Planta joven',
        'diasSiguienteEtapa': 2,
      });

      expect(r.rachaActual, 5);
      expect(r.rachaMaxima, 9);
      expect(r.totalDias, 12);
      expect(r.ultimoDia, '2026-10-21');
      expect(r.registradaHoy, isTrue);
      expect(r.etapa, 3);
      expect(r.nombreEtapa, 'Planta joven');
      expect(r.diasSiguienteEtapa, 2);
      expect(r.nombreSiguienteEtapa, 'Planta adulta');
    });

    test('tolera nulls, números como texto y decimales', () {
      final r = Racha.fromJson({
        'rachaActual': '4',
        'rachaMaxima': 7.0,
        'totalDias': null,
        'ultimoDia': null,
        'registradaHoy': 'false',
        'etapa': 2.0,
        'nombreEtapa': null,
        'diasSiguienteEtapa': '3',
      });

      expect(r.rachaActual, 4);
      expect(r.rachaMaxima, 7);
      expect(r.totalDias, 0);
      expect(r.ultimoDia, isNull);
      expect(r.registradaHoy, isFalse);
      expect(r.etapa, 2);
      expect(r.nombreEtapa, 'Plántula');
      expect(r.diasSiguienteEtapa, 3);
    });

    test(
      'etapa fuera de rango se ajusta y etapa máxima no tiene siguiente',
      () {
        final alta = Racha.fromJson({'etapa': 9, 'diasSiguienteEtapa': null});
        expect(alta.etapa, 5);
        expect(alta.nombreEtapa, 'En flor');
        expect(alta.esEtapaMaxima, isTrue);
        expect(alta.nombreSiguienteEtapa, isNull);
        expect(alta.progreso, 1);

        final baja = Racha.fromJson({'etapa': -3});
        expect(baja.etapa, 0);
        expect(baja.nombreEtapa, 'Semilla');
      },
    );

    test('progreso dentro de la etapa actual', () {
      // Planta joven (7 a 13 días): faltan 2 para la adulta (14) -> 5 de 7.
      final r = Racha.fromJson({'etapa': 3, 'diasSiguienteEtapa': 2});
      expect(r.progreso, closeTo(5 / 7, 0.0001));
    });
  });

  group('TarjetaRacha', () {
    Widget envolver(Racha r) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: TarjetaRacha(racha: r)),
      ),
    );

    testWidgets('muestra racha, etapa y los días que faltan', (tester) async {
      final r = Racha.fromJson({
        'rachaActual': 5,
        'rachaMaxima': 9,
        'totalDias': 12,
        'etapa': 3,
        'nombreEtapa': 'Planta joven',
        'diasSiguienteEtapa': 2,
      });
      await tester.pumpWidget(envolver(r));
      await tester.pumpAndSettle();

      expect(find.text('Tu racha'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('días seguidos'), findsOneWidget);
      expect(find.text('Planta joven'), findsOneWidget);
      expect(find.text('Faltan 2 días para Planta adulta'), findsOneWidget);
      expect(find.text('Racha máxima: 9'), findsOneWidget);
      expect(find.text('Total: 12 días'), findsOneWidget);
      expect(
        find.text('Entra cada día para hacer crecer tu planta.'),
        findsNothing,
      );
    });

    testWidgets(
      'con racha 0 anima a entrar y en etapa máxima no muestra faltantes',
      (tester) async {
        final cero = Racha.fromJson({
          'rachaActual': 0,
          'etapa': 0,
          'diasSiguienteEtapa': 1,
        });
        await tester.pumpWidget(envolver(cero));
        await tester.pumpAndSettle();
        expect(
          find.text('Entra cada día para hacer crecer tu planta.'),
          findsOneWidget,
        );
        expect(find.text('Faltan 1 día para Brote'), findsOneWidget);

        final maxima = Racha.fromJson({
          'rachaActual': 40,
          'etapa': 5,
          'nombreEtapa': 'En flor',
        });
        await tester.pumpWidget(envolver(maxima));
        await tester.pumpAndSettle();
        expect(find.text('Etapa máxima'), findsOneWidget);
      },
    );
  });
}
