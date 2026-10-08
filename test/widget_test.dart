// Pruebas básicas de la app Plantamoss.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plantamoss/config/constantes.dart';
import 'package:plantamoss/main.dart';
import 'package:plantamoss/services/api_client.dart';
import 'package:plantamoss/services/auth_service.dart';

void main() {
  testWidgets('Sin sesión guardada muestra el login y valida campos', (
    tester,
  ) async {
    // Preferencias vacías: no hay token ni servidor guardado.
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const PlantamossApp());
    await tester.runAsync(() => AuthService.instancia.restaurarSesion());
    await tester.pumpAndSettle();

    expect(find.text('plantamoss'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    // El usuario no ve a qué servidor se conecta (ni selector ni aviso).
    expect(find.textContaining('Servidor'), findsNothing);
    expect(find.text('Conexión no cifrada (solo desarrollo)'), findsNothing);

    // Enviar vacío muestra los mensajes de validación.
    await tester.tap(find.byKey(const Key('boton_ingresar')));
    await tester.pump();
    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);

    // Correo mal formado.
    await tester.enterText(
      find.byKey(const Key('campo_email')),
      'admin@plantamoss',
    );
    await tester.tap(find.byKey(const Key('boton_ingresar')));
    await tester.pump();
    expect(find.text('Correo inválido.'), findsOneWidget);
  });

  test('Construye la URL base de la API', () {
    expect(
      ApiClient.construirBaseUrl(ip: '10.0.2.2', puerto: '5080'),
      'http://10.0.2.2:5080/api',
    );
    expect(
      ApiClient.construirBaseUrl(ip: ' localhost ', puerto: '5080'),
      'http://localhost:5080/api',
    );
    expect(
      ApiClient.construirBaseUrl(
        esquema: 'https',
        ip: 'localhost',
        puerto: '7080',
      ),
      'https://localhost:7080/api',
    );
    // La URL completa reemplaza ip/puerto y agrega /api si falta.
    expect(
      ApiClient.construirBaseUrl(url: 'https://x.azurewebsites.net/'),
      'https://x.azurewebsites.net/api',
    );
    expect(
      ApiClient.construirBaseUrl(url: 'https://x.azurewebsites.net/api'),
      'https://x.azurewebsites.net/api',
    );
  });

  test(
    'El servidor por defecto es la nube y el texto no muestra esquema ni /api',
    () {
      expect(kUrlNube, 'https://api.plantamoss.online/api');
      expect(ApiClient.textoServidor(kUrlNube), 'api.plantamoss.online');
      expect(
        ApiClient.textoServidor('http://10.16.0.72:5080/api'),
        '10.16.0.72:5080',
      );
    },
  );
}
