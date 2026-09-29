# Plantamoss (app móvil)

App Flutter del proyecto Plantamoss: catálogo de flora mexicana. Consume la misma
API .NET que la web (`ApiPlantamoss`). Flutter 3.44 / Dart 3.12.

## Cómo correrla

```bash
flutter pub get
flutter run              # elige el dispositivo (celular, emulador, Chrome, Windows)
```

Pruebas y análisis:

```bash
flutter analyze
flutter test
```

## Configurar el servidor (IP de la API)

En la pantalla de login toca **Servidor** (ícono de engrane, abajo). Escribe la IP y el
puerto, usa **Probar conexión** y luego **Guardar**. Se guarda en el teléfono
(`shared_preferences`). La URL que se arma es `http://<ip>:<puerto>/api`.

| Dónde corre la app | IP a usar |
|---|---|
| Celular físico | IP del PC en el Wi-Fi (por defecto `10.16.0.72`) |
| Emulador Android | `10.0.2.2` (apunta al PC) |
| Flutter web / Windows | `localhost` |

Puerto por defecto: `5080`.

Si el celular no conecta:

1. El celular y el PC deben estar en **la misma red Wi-Fi**.
2. La API debe escuchar en toda la red (`http://0.0.0.0:5080`).
3. Permite el puerto 5080 en el Firewall de Windows (PowerShell como administrador):

   ```
   netsh advfirewall firewall add rule name="Plantamoss API 5080" dir=in action=allow protocol=TCP localport=5080
   ```

4. Prueba desde el navegador del celular: `http://<ip-del-pc>:5080/api/estados`.

Notas de desarrollo: Android tiene el permiso `INTERNET` y `usesCleartextTraffic="true"`
(la API es http). En iOS, `Info.plist` tiene `NSAllowsArbitraryLoads` (solo desarrollo).

Las cuentas de prueba están en `ApiPlantamoss/database/README.md`.

## Pantallas

- **Login**: correo, contraseña, errores de la API y configuración del servidor.
  La sesión (token + usuario) se guarda; al abrir la app se valida con `/auth/me`.
- **Inicio**: banner, saludo, clima de tus ciudades, accesos rápidos y noticias.
- **Plantas**: imagen destacada con filtros de estado y clima/luz, buscador,
  lista y detalle de cada planta.
- **Perfil**: datos de la cuenta, servidor y cerrar sesión.

## Estructura

```
lib/
  main.dart                  Arranque: carga de sesión -> Login o Shell
  config/
    tema.dart                Colores (AppColores) y tema Material 3
    constantes.dart          Servidor por defecto, claves, climas y luces
  models/                    Usuario, Planta, Estado, Noticia, Clima
  services/
    api_client.dart          HTTP: baseUrl configurable, token, errores {message}
    auth_service.dart        Login, logout y sesión persistente
    plantas_service.dart     /plantas y /estados
    inicio_service.dart      /noticias/recientes, /perfil/ciudades-clima, /externo/clima
  screens/                   login, shell, inicio, plantas, planta_detalle, perfil
  widgets/                   Barra inferior, imagen de planta, sheet de servidor, comunes
assets/img/                  Logo, banner e imágenes copiadas de la web
```

Las imágenes con ruta relativa (`/img/agave-azul.jpeg`) se cargan desde `assets/img/`;
las absolutas desde internet. Si fallan se muestra un brote sobre fondo verde suave.

Paquetes: `http`, `shared_preferences`.
