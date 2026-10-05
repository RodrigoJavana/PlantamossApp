import 'package:flutter/foundation.dart';
// Pantalla de inicio de sesión + acceso a la configuración del servidor.
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/validadores.dart';
import '../widgets/servidor_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  /// Errores por campo que devuelve la API (422).
  String? _errorEmailApi;
  String? _errorPassApi;

  @override
  void initState() {
    super.initState();
    // Aviso pendiente (p. ej. "Tu sesión expiró").
    _error = AuthService.instancia.aviso;
    AuthService.instancia.aviso = null;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
      _errorEmailApi = null;
      _errorPassApi = null;
    });
    try {
      await AuthService.instancia.iniciarSesion(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      // Al iniciar sesión, main.dart cambia solo a la pantalla principal.
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorEmailApi = e.errorDe('email');
          _errorPassApi = e.errorDe('password');
          _error = e.message;
        });
      }
    } catch (e, st) {
      if (mounted) setState(() => _error = mensajeDeError(e, st));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo en un cuadro verde (el logo es claro).
                    // Solo en debug: mantener presionado abre el selector de servidor (desarrollo).
                    Center(
                      child: GestureDetector(
                        key: const Key('logo_login'),
                        onLongPress: kDebugMode
                            ? () => mostrarServidorSheet(context)
                            : null,
                        child: Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColores.verdeOscuro,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Image.asset('assets/img/logo-claro.png'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'plantamoss',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColores.titulo,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColores.titulo,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_error != null)
                      Container(
                        key: const Key('error_login'),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEA),
                          border: Border.all(color: const Color(0xFFF5C6C0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColores.rojo,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFF8A1F17),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextFormField(
                      key: const Key('campo_email'),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      maxLength: Limites.email,
                      forceErrorText: _errorEmailApi,
                      onChanged: (_) {
                        if (_errorEmailApi != null) {
                          setState(() => _errorEmailApi = null);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        counterText: '',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validadores.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('campo_password'),
                      controller: _passCtrl,
                      obscureText: _ocultar,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _ingresar(),
                      maxLength: Limites.password,
                      autocorrect: false,
                      enableSuggestions: false,
                      forceErrorText: _errorPassApi,
                      onChanged: (_) {
                        if (_errorPassApi != null) {
                          setState(() => _errorPassApi = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                          icon: Icon(
                            _ocultar
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: Validadores.password,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      key: const Key('boton_ingresar'),
                      onPressed: _cargando ? null : _ingresar,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Ingresar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
