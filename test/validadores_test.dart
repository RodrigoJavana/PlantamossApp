// Pruebas de validación de entradas y del saneo de logs.
import 'package:flutter_test/flutter_test.dart';

import 'package:plantamoss/services/registro.dart';
import 'package:plantamoss/services/validadores.dart';

void main() {
  group('Correo', () {
    test('acepta correos válidos', () {
      expect(Validadores.email('admin@plantamoss.com'), isNull);
      expect(Validadores.email('  ana.perez+1@uni.edu.mx '), isNull);
    });
    test('rechaza vacíos y mal formados', () {
      expect(Validadores.email(''), 'Escribe tu correo.');
      expect(Validadores.email('admin'), 'Correo inválido.');
      expect(Validadores.email('admin@plantamoss'), 'Correo inválido.');
      expect(Validadores.email('a b@x.com'), 'Correo inválido.');
      expect(Validadores.email('${'a' * 250}@x.com'), 'Correo inválido.');
    });
  });

  group('Contraseña', () {
    test('no vacía y con longitud máxima', () {
      expect(Validadores.password(''), isNotNull);
      expect(Validadores.password('   '), isNotNull);
      expect(Validadores.password('secreta1'), isNull);
      expect(Validadores.password('x' * (Limites.password + 1)), isNotNull);
    });
  });

  group('Servidor', () {
    test('IP y host', () {
      expect(Validadores.host('10.16.0.72'), isNull);
      expect(Validadores.host('localhost'), isNull);
      expect(Validadores.host('api.plantamoss.mx'), isNull);
      expect(Validadores.host(''), isNotNull);
      expect(Validadores.host('300.1.1.1'), isNotNull);
      expect(Validadores.host('10.0.2'), isNotNull);
      expect(Validadores.host('http://x'), isNotNull);
      expect(Validadores.host('mal host'), isNotNull);
    });
    test('puerto 1-65535', () {
      expect(Validadores.puerto('5080'), isNull);
      expect(Validadores.puerto('1'), isNull);
      expect(Validadores.puerto('65535'), isNull);
      expect(Validadores.puerto('0'), isNotNull);
      expect(Validadores.puerto('65536'), isNotNull);
      expect(Validadores.puerto('-1'), isNotNull);
      expect(Validadores.puerto('80a'), isNotNull);
    });
    test('URL https', () {
      expect(Validadores.urlHttps(''), isNull); // opcional
      expect(
        Validadores.urlHttps('https://plantamoss-api.azurewebsites.net'),
        isNull,
      );
      expect(Validadores.urlHttps('https://x.azurewebsites.net/api'), isNull);
      expect(Validadores.urlHttps('http://x.azurewebsites.net'), isNotNull);
      expect(Validadores.urlHttps('ftp://x.com'), isNotNull);
      expect(Validadores.urlHttps('https://'), isNotNull);
      expect(Validadores.urlHttps('https://user:pw@x.com'), isNotNull);
    });
  });

  test('Búsqueda saneada', () {
    expect(Validadores.sanearBusqueda('  agave   azul '), 'agave azul');
    expect(Validadores.sanearBusqueda('<script>\n'), 'script');
    expect(Validadores.sanearBusqueda('a' * 200).length, Limites.busqueda);
    expect(Validadores.sanearBusqueda(null), '');
  });

  test('Registro quita tokens y enmascara correos', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc_DEF-123';
    final t = Registro.sanear(
      'login admin@plantamoss.com Bearer $jwt {"password":"secreta","refreshToken":"zzz"}',
    );
    expect(t, isNot(contains('admin@')));
    expect(t, contains('a***@plantamoss.com'));
    expect(t, isNot(contains(jwt)));
    expect(t, isNot(contains('secreta')));
    expect(t, isNot(contains('zzz')));
  });

  test('En release no registra depuración/info', () {
    Registro.forzarRelease = true;
    Registro.historial.clear();
    Registro.info('Prueba', 'no debe quedar');
    Registro.error('Prueba', 'sí queda');
    expect(Registro.historial.length, 1);
    Registro.forzarRelease = null;
  });
}
