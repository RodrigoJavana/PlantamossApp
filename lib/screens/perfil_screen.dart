// Perfil (mínimo): datos del usuario, servidor y cerrar sesión.
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/insignia.dart';
import '../services/auth_service.dart';
import '../services/insignias_service.dart';
import '../widgets/comunes.dart';
import '../widgets/insignia_tarjeta.dart';
import '../widgets/tarjeta_racha.dart';
import 'insignias_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _confirmarSalida(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColores.rojo,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (ok == true) await AuthService.instancia.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final u = AuthService.instancia.usuario;
    if (u == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColores.titulo,
          ),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar cuadrado blanco con inicial negra (como la web).
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColores.borde, width: 1.5),
                ),
                child: Text(
                  u.inicial,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColores.titulo,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                u.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColores.titulo,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColores.verdeSuave,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  u.rolTexto,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColores.verdeOscuro,
                  ),
                ),
              ),
            ],
          ),
        ),
        const TarjetaRachaActual(margen: EdgeInsets.only(top: 14)),
        const SizedBox(height: 14),
        const _TarjetaInsignias(),
        const SizedBox(height: 14),
        Tarjeta(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _Fila(
                icono: Icons.mail_outline_rounded,
                etiqueta: 'Correo',
                valor: u.email,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _Fila(
                icono: u.emailVerificado
                    ? Icons.verified_outlined
                    : Icons.error_outline_rounded,
                etiqueta: 'Verificación',
                valor: u.emailVerificado ? 'Verificado' : 'Pendiente',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          key: const Key('boton_cerrar_sesion'),
          onPressed: () => _confirmarSalida(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColores.rojo,
            side: const BorderSide(color: AppColores.rojo),
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: AppColores.texto),
      title: Text(
        etiqueta,
        style: const TextStyle(fontSize: 12.5, color: AppColores.texto),
      ),
      subtitle: Text(
        valor,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColores.titulo,
        ),
      ),
    );
  }
}

/// Fila "Mis insignias": N de 9, unos iconos de las ganadas y abre la pantalla de insignias.
class _TarjetaInsignias extends StatelessWidget {
  const _TarjetaInsignias();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Insignia>>(
      valueListenable: InsigniasService.instancia.insignias,
      builder: (_, lista, _) {
        final ganadas = lista.where((i) => i.desbloqueada).toList();
        return Tarjeta(
          padding: EdgeInsets.zero,
          child: InkWell(
            key: const Key('boton_mis_insignias'),
            borderRadius: BorderRadius.circular(AppRadios.tarjeta),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InsigniasScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mis insignias',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColores.titulo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lista.isEmpty
                              ? 'Sin datos todavía'
                              : '${ganadas.length} de ${lista.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColores.texto,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final i in ganadas.take(4))
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: MedallaInsignia(insignia: i, tamano: 32),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColores.texto,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
