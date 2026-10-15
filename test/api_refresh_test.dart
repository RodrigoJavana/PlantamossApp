// Pruebas del flujo de sesión: refresh automático ante 401 con un
// http.Client simulado (MockClient).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plantamoss/services/almacen_seguro.dart';
import 'package:plantamoss/services/api_client.dart';
import 'package:plantamoss/services/auth_service.dart';

const _usuario = {
  'id': 1,
  'name': 'Admin',
  'email': 'admin@plantamoss.com',
  'role': 'admin',
};

http.Response _json(int status, Object? cuerpo) => http.Response(
  cuerpo == null ? '' : jsonEncode(cuerpo),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    '401 -> refresh una vez -> reintenta con el token nuevo y lo guarda',
    () async {
      var refrescos = 0;
      final api = ApiClient.prueba(
        MockClient((req) async {
          if (req.url.path.endsWith('/auth/refresh')) {
            refrescos++;
            expect(jsonDecode(req.body)['refreshToken'], 'r1');
            return _json(200, {
              'token': 't2',
              'refreshToken': 'r2',
              'expiresIn': 3600,
              'user': _usuario,
            });
          }
          // Solo el token nuevo es válido.
          return req.headers['Authorization'] == 'Bearer t2'
              ? _json(200, {'ok': true})
              : _json(401, null);
        }),
      );
      final almacen = AlmacenMemoria();
      AuthService.prueba(api, almacen);
      api.token = 't1';
      api.refreshToken = 'r1';

      final r = await api.get('/plantas');

      expect(r, {'ok': true});
      expect(refrescos, 1);
      expect(api.token, 't2');
      expect(api.refreshToken, 'r2');
      expect(almacen.datos['token'], 't2');
      expect(almacen.datos['refresh'], 'r2');
    },
  );

  test('Peticiones simultáneas esperan el MISMO refresh (candado)', () async {
    var refrescos = 0;
    final liberar = Completer<void>();
    final api = ApiClient.prueba(
      MockClient((req) async {
        if (req.url.path.endsWith('/auth/refresh')) {
          refrescos++;
          await liberar.future; // refresh lento
          return _json(200, {
            'token': 't2',
            'refreshToken': 'r2',
            'expiresIn': 3600,
            'user': _usuario,
          });
        }
        return req.headers['Authorization'] == 'Bearer t2'
            ? _json(200, [req.url.path])
            : _json(401, null);
      }),
    );
    api.token = 't1';
    api.refreshToken = 'r1';

    final futuros = [
      api.get('/plantas'),
      api.get('/estados'),
      api.get('/noticias/recientes'),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 20));
    liberar.complete();
    final res = await Future.wait(futuros);

    expect(refrescos, 1);
    expect(res.length, 3);
  });

  test(
    'Si el refresh falla: limpia la sesión y avisa "Tu sesión expiró"',
    () async {
      final api = ApiClient.prueba(
        MockClient((req) async {
          if (req.url.path.endsWith('/auth/refresh')) {
            return _json(401, {'message': 'Refresh inválido'});
          }
          return _json(401, null);
        }),
      );
      final almacen = AlmacenMemoria()
        ..datos.addAll({'token': 't1', 'refresh': 'r1'});
      final auth = AuthService.prueba(api, almacen);
      api.token = 't1';
      api.refreshToken = 'r1';

      await expectLater(
        api.get('/plantas'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            kMsgSesionExpirada,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.token, isNull);
      expect(api.refreshToken, isNull);
      expect(almacen.datos, isEmpty);
      expect(auth.aviso, kMsgSesionExpirada);
      expect(auth.autenticado, isFalse);
    },
  );

  test(
    'El login con 401 NO intenta refresh y devuelve el mensaje de la API',
    () async {
      var refrescos = 0;
      final api = ApiClient.prueba(
        MockClient((req) async {
          if (req.url.path.endsWith('/auth/refresh')) refrescos++;
          return _json(401, {'message': 'Credenciales inválidas.'});
        }),
      );
      final auth = AuthService.prueba(api, AlmacenMemoria());
      await expectLater(
        auth.iniciarSesion('a@b.com', 'x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Credenciales inválidas.',
          ),
        ),
      );
      expect(refrescos, 0);
    },
  );

  test(
    'Login guarda token, refresh y usuario; logout llama /auth/logout y borra',
    () async {
      String? logoutBody;
      final api = ApiClient.prueba(
        MockClient((req) async {
          if (req.url.path.endsWith('/auth/login')) {
            return _json(200, {
              'token': 't1',
              'refreshToken': 'r1',
              'expiresIn': 3600,
              'user': _usuario,
            });
          }
          if (req.url.path.endsWith('/auth/logout')) {
            logoutBody = req.body;
            return _json(204, null);
          }
          return _json(404, null);
        }),
      );
      final almacen = AlmacenMemoria();
      final auth = AuthService.prueba(api, almacen);

      await auth.iniciarSesion(' admin@plantamoss.com ', 'secreta');
      expect(auth.autenticado, isTrue);
      expect(almacen.datos['token'], 't1');
      expect(almacen.datos['refresh'], 'r1');
      expect(almacen.datos['user'], contains('admin@plantamoss.com'));

      await auth.cerrarSesion();
      expect(jsonDecode(logoutBody!)['refreshToken'], 'r1');
      expect(auth.autenticado, isFalse);
      expect(almacen.datos, isEmpty);
    },
  );

  test('Errores 422 por campo', () async {
    final api = ApiClient.prueba(
      MockClient(
        (req) async => _json(422, {
          'message': 'Datos inválidos',
          'errors': {
            'Email': ['El correo no es válido.'],
          },
        }),
      ),
    );
    try {
      await api.post('/auth/login', {'email': 'x', 'password': 'y'});
      fail('Debió fallar');
    } on ApiException catch (e) {
      expect(e.status, 422);
      expect(e.errorDe('email'), 'El correo no es válido.');
    }
  });

  test('Sin red da un mensaje claro', () async {
    final api = ApiClient.prueba(
      MockClient((req) async => throw http.ClientException('fallo')),
    );
    await expectLater(
      api.get('/plantas'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Sin conexión con el servidor.',
        ),
      ),
    );
  });

  test('Errores técnicos no llegan a la UI', () {
    expect(mensajeDeError(TypeError()), kMsgErrorGenerico);
    expect(mensajeDeError(const ApiException('Sin permiso.')), 'Sin permiso.');
  });
}
