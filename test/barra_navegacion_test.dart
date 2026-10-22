// Prueba de widget: la barra inferior muestra las 5 pestañas y avisa al tocar una.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plantamoss/widgets/barra_navegacion.dart';

void main() {
  const items = [
    ItemNavegacion(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    ItemNavegacion(Icons.eco_outlined, Icons.eco_rounded, 'Plantas'),
    ItemNavegacion(Icons.map_outlined, Icons.map_rounded, 'Mapa'),
    ItemNavegacion(Icons.article_outlined, Icons.article_rounded, 'Blog'),
    ItemNavegacion(
      Icons.person_outline_rounded,
      Icons.person_rounded,
      'Perfil',
    ),
  ];

  testWidgets('muestra las 5 pestañas y cambia de índice al tocar', (
    tester,
  ) async {
    int? elegido;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BarraNavegacion(
            items: items,
            indice: 0,
            alCambiar: (i) => elegido = i,
          ),
        ),
      ),
    );

    for (final item in items) {
      expect(find.text(item.texto), findsOneWidget);
    }

    await tester.tap(find.text('Blog'));
    await tester.pumpAndSettle();
    expect(elegido, 3);
  });
}
