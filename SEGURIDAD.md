# Seguridad de la app móvil Plantamoss (Unidad II, Actividad 3)

Codificación segura aplicada a la app Flutter. La API .NET implementa su parte en
`CONTRATO.md`, sección 5 (refresh tokens con rotación, bitácora y HTTPS).

| # | Punto | Qué se hizo | Dónde | Cómo probarlo |
|---|---|---|---|---|
| 1 | Almacenamiento seguro | Token, refreshToken y usuario se guardan con `flutter_secure_storage`: Android cifra con AES-GCM y la llave vive en el **Android Keystore**; iOS usa **Keychain** (`unlocked_this_device`, no se copia a iCloud); web cifra con **WebCrypto**. En `shared_preferences` solo queda el servidor (esquema, IP, puerto, URL). Si existe una sesión de la versión anterior en `shared_preferences` se mueve al almacén seguro y se borra. Android con `allowBackup="false"`. | `lib/services/almacen_seguro.dart`, `lib/services/auth_service.dart`, `lib/config/constantes.dart`, `android/app/src/main/AndroidManifest.xml` | Iniciar sesión y revisar `shared_preferences` (Android: `adb shell run-as com.plantamoss.plantamoss cat shared_prefs/FlutterSharedPreferences.xml`): no aparece `pm_token`. Test `api_refresh_test.dart` ("Login guarda token...") |
| 2 | Comunicación segura (HTTPS) | Hoja **Servidor** con esquema `http`/`https`, IP/host y puerto, o preset **Nube (Azure)** con URL https completa (reemplaza IP/puerto). Con `http` se muestra "Conexión no cifrada (solo desarrollo)". Android: se quitó `usesCleartextTraffic`; `network_security_config.xml` prohíbe http salvo en `10.0.2.2`, `localhost`, `127.0.0.1` y `10.16.0.72` (en *debug* se permite más). iOS: `NSAllowsArbitraryLoads` se reemplazó por `NSAllowsLocalNetworking` + excepciones de desarrollo. | `lib/widgets/servidor_sheet.dart`, `lib/services/api_client.dart`, `android/app/src/main/res/xml/network_security_config.xml`, `android/app/src/debug/res/xml/network_security_config.xml`, `ios/Runner/Info.plist` | En el login aparece el aviso con `http`. Elegir "Nube (Azure)" o `https` y el aviso desaparece. En un APK release, apuntar con `http` a una IP no listada: la conexión es rechazada por Android |
| 3 | Validación de entradas | Correo con regex, contraseña no vacía (máx. 128), IP v4 / host, puerto 1-65535, URL https válida (sin usuario ni parámetros). `trim` y `maxLength` en todos los campos. Búsqueda saneada (sin caracteres de control ni `<>`, espacios colapsados, máx. 80). Errores 422 de la API se muestran bajo el campo correspondiente. | `lib/services/validadores.dart`, `lib/screens/login_screen.dart`, `lib/widgets/servidor_sheet.dart`, `lib/screens/plantas_screen.dart` | Escribir `admin@plantamoss` o un puerto `70000`: aparece el error. Tests `validadores_test.dart` y "Errores 422 por campo" |
| 4 | Autenticación y sesiones | Login guarda `{token, refreshToken}`. Ante un **401** el `ApiClient` llama **una vez** a `POST /auth/refresh` con un **candado** (las peticiones simultáneas esperan el mismo refresh), guarda los tokens rotados y reintenta. Si el refresh falla: borra la sesión segura y vuelve al login con "Tu sesión expiró". Cerrar sesión llama `POST /auth/logout {refreshToken}` (revoca en el servidor). Timeout de 15 s con mensaje claro. | `lib/services/api_client.dart`, `lib/services/auth_service.dart`, `lib/screens/login_screen.dart` | Tests `api_refresh_test.dart` (refresh + reintento, candado con 3 peticiones, refresh fallido, logout). Manual: bajar `Jwt:ExpiracionMinutos` a 1 en la API, esperar y navegar: la app sigue funcionando (refresh) |
| 5 | Errores y registro (logs) | `Registro` con niveles (depuración, info, aviso, error). En debug usa `debugPrint`; en release solo guarda avisos/errores en memoria. Siempre sanea: quita JWT, `Bearer`, `password`, `token`, `refreshToken` y enmascara correos (`a***@dominio`). Captura global con `runZonedGuarded`, `FlutterError.onError` y `PlatformDispatcher.instance.onError`; en release `ErrorWidget` muestra texto amigable. La UI ya no muestra mensajes crudos: los errores técnicos se registran y el usuario ve "No se pudo cargar. Intenta de nuevo." | `lib/services/registro.dart`, `lib/main.dart`, `lib/services/api_client.dart` (`mensajeDeError`) | Tests "Registro quita tokens...", "En release no registra..." y "Errores técnicos no llegan a la UI". Manual: `flutter run` y ver la consola al iniciar sesión (correo enmascarado, sin token) |
| 6 | Protección de código fuente | `scripts/build_release.ps1` compila APK y App Bundle con `--obfuscate --split-debug-info=build/debug-info` y web release. R8 activo en release (`isMinifyEnabled`, `isShrinkResources`, `proguard-rules.pro`; también quita `Log.d/i/v`). Firma con `android/key.properties` si existe. `.gitignore` excluye `build/`, `debug-info`, keystores (`*.jks`, `*.keystore`), `key.properties`, `.env` y `local.properties`. Repositorio git local creado. | `scripts/build_release.ps1`, `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`, `.gitignore` | `powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1 -Solo apk`. `git ls-files` no lista llaves ni `build/` |

## Pruebas automáticas

```bash
flutter analyze
flutter test        # validadores, logs, refresh/candado/logout, 422, widget de login
```

## Pendientes del usuario

- Crear la llave de firma y `android/key.properties` (no se suben a git):
  `keytool -genkey -v -keystore %USERPROFILE%\plantamoss.jks -keyalg RSA -keysize 2048 -validity 10000 -alias plantamoss`
  y en `android/key.properties`: `storePassword=...`, `keyPassword=...`, `keyAlias=plantamoss`, `storeFile=C:/Users/<usuario>/plantamoss.jks`.
- Al publicar la API en Azure, poner la URL real en "Nube (Azure)" (por defecto
  `https://plantamoss-api.azurewebsites.net`, editable) o cambiar `kUrlNubePorDefecto`.
- Si la IP del PC cambia, agregarla en `network_security_config.xml` (main) y en `Info.plist`.
- Guardar en privado `build/debug-info` de cada versión publicada (sirve para leer trazas ofuscadas con `flutter symbolize`).
