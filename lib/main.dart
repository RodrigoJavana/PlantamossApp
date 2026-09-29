// Punto de entrada de la app Plantamoss.
//
// Flujo:
// 1. Se muestra una pantalla de carga mientras se revisa la sesión guardada.
// 2. Si hay sesión válida -> ShellScreen (Inicio / Plantas / Perfil).
// 3. Si no -> LoginScreen.
//
// Captura global de errores: se registran (Registro) y el usuario solo ve un
// mensaje amigable, nunca el detalle técnico.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config/tema.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/registro.dart';
import 'widgets/comunes.dart';

/// Para mostrar avisos desde la captura global de errores.
final GlobalKey<ScaffoldMessengerState> mensajeroGlobal =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    configurarErroresGlobales();
    runApp(const PlantamossApp());
    // Revisa token + servidor guardados (no bloquea el primer frame).
    AuthService.instancia.restaurarSesion();
  }, (error, pila) => _reportar('Zona', error, pila));
}

/// Errores de Flutter (build/layout) y de la plataforma (async sin capturar).
void configurarErroresGlobales() {
  FlutterError.onError = (detalles) {
    if (kDebugMode) FlutterError.presentError(detalles);
    _reportar('Flutter', detalles.exception, detalles.stack, avisar: false);
  };
  PlatformDispatcher.instance.onError = (error, pila) {
    _reportar('Plataforma', error, pila);
    return true;
  };
  // En release un widget que falla muestra un texto amigable (no la pila roja).
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(kMsgErrorGenerico, textAlign: TextAlign.center),
      ),
    );
  }
}

void _reportar(
  String origen,
  Object error,
  StackTrace? pila, {
  bool avisar = true,
}) {
  Registro.error(origen, 'Error no controlado', error, pila);
  if (avisar) {
    mensajeroGlobal.currentState?.showSnackBar(
      const SnackBar(content: Text('Algo salió mal. Intenta de nuevo.')),
    );
  }
}

class PlantamossApp extends StatelessWidget {
  const PlantamossApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instancia;
    return MaterialApp(
      title: 'Plantamoss',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: mensajeroGlobal,
      theme: construirTema(),
      // ListenableBuilder vuelve a construir cuando AuthService cambia.
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          if (auth.iniciando) return const _PantallaCarga();
          return auth.autenticado ? const ShellScreen() : const LoginScreen();
        },
      ),
    );
  }
}

class _PantallaCarga extends StatelessWidget {
  const _PantallaCarga();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColores.verdeOscuro,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoMarca(tamano: 44),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
