// Bottom sheet para configurar el servidor de la API.
//
// Presets:
// - Nube (plantamoss.online): https://api.plantamoss.online/api (por defecto).
// - Red local (desarrollo): esquema http/https + IP + puerto.
//   El celular debe estar en la misma Wi-Fi que el PC. Emulador: 10.0.2.2;
//   Flutter web: localhost.
// - Personalizado: URL https completa.
// Si el usuario ya guardó un servidor, se respeta; "Volver a la nube" lo restablece.
import 'package:flutter/material.dart';

import '../config/constantes.dart';
import '../config/tema.dart';
import '../services/api_client.dart';
import '../services/validadores.dart';
import 'comunes.dart';

/// Abre el sheet. Devuelve true si se guardó un servidor nuevo.
Future<bool?> mostrarServidorSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ServidorSheet(),
  );
}

enum _Modo { nube, local, personalizado }

class _ServidorSheet extends StatefulWidget {
  const _ServidorSheet();

  @override
  State<_ServidorSheet> createState() => _ServidorSheetState();
}

class _ServidorSheetState extends State<_ServidorSheet> {
  final _api = ApiClient.instancia;
  final _formKey = GlobalKey<FormState>();
  late final _ipCtrl = TextEditingController(text: _api.ip);
  late final _puertoCtrl = TextEditingController(text: _api.puerto);
  late final _urlCtrl = TextEditingController(
    text: _api.urlCompleta.isEmpty ? kUrlNube : _api.urlCompleta,
  );
  late String _esquema = _api.esquema;
  late _Modo _modo = _modoGuardado();

  bool _probando = false;
  bool? _conectado; // null = sin probar
  String _mensaje = '';

  /// Modo que corresponde al servidor guardado.
  _Modo _modoGuardado() {
    final u = _api.urlCompleta.trim();
    if (u.isEmpty) return _Modo.local;
    return ApiClient.construirBaseUrl(url: u) == kUrlNube
        ? _Modo.nube
        : _Modo.personalizado;
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _puertoCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  String get _baseUrl => switch (_modo) {
    _Modo.nube => kUrlNube,
    _Modo.local => ApiClient.construirBaseUrl(
      esquema: _esquema,
      ip: _ipCtrl.text,
      puerto: _puertoCtrl.text,
    ),
    _Modo.personalizado => ApiClient.construirBaseUrl(url: _urlCtrl.text),
  };

  /// Lo que se guarda como URL completa: nube y personalizado la usan; local no.
  String get _urlGuardada => switch (_modo) {
    _Modo.nube => kUrlNube,
    _Modo.local => '',
    _Modo.personalizado => _urlCtrl.text,
  };

  bool _validar() {
    final ok = _formKey.currentState!.validate();
    if (!ok) setState(() => _conectado = null);
    return ok;
  }

  void _cambio() => setState(() => _conectado = null);

  void _elegir(_Modo m) => setState(() {
    _modo = m;
    _conectado = null;
  });

  Future<void> _probar() async {
    if (!_validar()) return;
    setState(() {
      _probando = true;
      _conectado = null;
    });
    try {
      await _api.probarConexion(_baseUrl);
      _conectado = true;
      _mensaje = 'Conectado';
    } on ApiException catch (e) {
      _conectado = false;
      _mensaje = e.message;
    }
    if (mounted) setState(() => _probando = false);
  }

  Future<void> _guardar() async {
    if (!_validar()) return;
    await _api.guardarServidor(
      esquema: _esquema,
      ip: _ipCtrl.text,
      puerto: _puertoCtrl.text,
      url: _urlGuardada,
    );
    if (mounted) Navigator.pop(context, true);
  }

  /// Restablece la nube y cierra. No valida campos (se van a descartar).
  Future<void> _volverANube() async {
    await _api.guardarServidor(
      esquema: _esquema,
      ip: _ipCtrl.text,
      puerto: _puertoCtrl.text,
      url: kUrlNube,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Widget _opcion(_Modo m, IconData icono, String titulo, String detalle) {
    final sel = _modo == m;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: Key('opcion_${m.name}'),
        borderRadius: BorderRadius.circular(AppRadios.boton),
        onTap: () => _elegir(m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColores.verdeSuave : AppColores.blanco,
            borderRadius: BorderRadius.circular(AppRadios.boton),
            border: Border.all(
              color: sel ? AppColores.verdeOscuro : AppColores.borde,
              width: sel ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icono,
                color: sel ? AppColores.verdeOscuro : AppColores.texto,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColores.titulo,
                      ),
                    ),
                    Text(
                      detalle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColores.texto,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: sel ? AppColores.verdeOscuro : AppColores.texto,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cifrado = _baseUrl.startsWith('https://');
    return Padding(
      // Sube el contenido cuando aparece el teclado.
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Servidor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColores.titulo,
                ),
              ),
              const SizedBox(height: 12),
              _opcion(
                _Modo.nube,
                Icons.cloud_outlined,
                'Nube (plantamoss.online)',
                'api.plantamoss.online, https',
              ),
              _opcion(
                _Modo.local,
                Icons.lan_rounded,
                'Red local (desarrollo)',
                'PC en la misma Wi-Fi, http',
              ),
              _opcion(
                _Modo.personalizado,
                Icons.link_rounded,
                'Personalizado',
                'Escribe una URL https completa',
              ),
              const SizedBox(height: 6),
              if (_modo == _Modo.personalizado)
                TextFormField(
                  key: const Key('campo_url'),
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  maxLength: Limites.url,
                  decoration: const InputDecoration(
                    labelText: 'URL completa (https)',
                    hintText: 'https://mi-api.ejemplo.com',
                    counterText: '',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Escribe la URL.'
                      : Validadores.urlHttps(v),
                  onChanged: (_) => _cambio(),
                )
              else if (_modo == _Modo.local)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 104,
                      child: DropdownButtonFormField<String>(
                        key: const Key('campo_esquema'),
                        initialValue: _esquema,
                        decoration: const InputDecoration(labelText: 'Esquema'),
                        items: const [
                          DropdownMenuItem(value: 'http', child: Text('http')),
                          DropdownMenuItem(
                            value: 'https',
                            child: Text('https'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _esquema = v ?? 'http';
                          _conectado = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: const Key('campo_ip'),
                        controller: _ipCtrl,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        maxLength: Limites.host,
                        decoration: const InputDecoration(
                          labelText: 'IP o host',
                          counterText: '',
                        ),
                        validator: Validadores.host,
                        onChanged: (_) => _cambio(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: const Key('campo_puerto'),
                        controller: _puertoCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: Limites.puerto,
                        decoration: const InputDecoration(
                          labelText: 'Puerto',
                          counterText: '',
                        ),
                        validator: Validadores.puerto,
                        onChanged: (_) => _cambio(),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                _baseUrl,
                style: const TextStyle(fontSize: 12, color: AppColores.texto),
              ),
              if (!cifrado) ...[
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AvisoSinCifrar(),
                ),
              ],
              const SizedBox(height: 14),
              if (_conectado != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _conectado!
                        ? AppColores.verdeSuave
                        : const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _conectado!
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 18,
                        color: _conectado!
                            ? AppColores.verdeIntenso
                            : AppColores.rojo,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mensaje,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _conectado!
                                ? AppColores.verdeIntenso
                                : AppColores.rojo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: _probando ? null : _probar,
                      icon: _probando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering_rounded, size: 18),
                      label: const Text('Probar conexión'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _guardar,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                key: const Key('boton_volver_nube'),
                onPressed: _volverANube,
                icon: const Icon(Icons.cloud_done_outlined, size: 18),
                label: const Text('Volver a la nube (plantamoss.online)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
