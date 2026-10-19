// Tarjeta "Tu racha": planta, días seguidos, etapa y progreso a la siguiente.
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/racha.dart';
import '../services/racha_service.dart';
import 'comunes.dart';
import 'planta_racha.dart';

/// Se muestra solo cuando ya hay datos de racha (si no, no ocupa espacio).
class TarjetaRachaActual extends StatelessWidget {
  final EdgeInsetsGeometry margen;
  const TarjetaRachaActual({
    super.key,
    this.margen = const EdgeInsets.only(top: 16),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Racha?>(
      valueListenable: RachaService.instancia.racha,
      builder: (_, racha, _) {
        if (racha == null) return const SizedBox.shrink();
        return Padding(
          padding: margen,
          child: TarjetaRacha(racha: racha),
        );
      },
    );
  }
}

class TarjetaRacha extends StatelessWidget {
  final Racha racha;
  const TarjetaRacha({super.key, required this.racha});

  static const _colorFuego = Color(0xFFE67E22);

  String get _textoProgreso {
    final faltan = racha.diasSiguienteEtapa;
    final siguiente = racha.nombreSiguienteEtapa;
    if (racha.esEtapaMaxima || faltan == null || siguiente == null) {
      return 'Etapa máxima';
    }
    final dias = faltan == 1 ? '1 día' : '$faltan días';
    return 'Faltan $dias para $siguiente';
  }

  @override
  Widget build(BuildContext context) {
    final diasSeguidos = racha.rachaActual;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            icono: Icons.local_fire_department_rounded,
            texto: 'Tu racha',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              PlantaRacha(etapa: racha.etapa, tamano: 116),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: _colorFuego,
                          size: 30,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$diasSeguidos',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AppColores.titulo,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      diasSeguidos == 1 ? 'día seguido' : 'días seguidos',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColores.texto,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        racha.nombreEtapa,
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
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: racha.progreso,
              minHeight: 8,
              color: AppColores.verdeIntenso,
              backgroundColor: AppColores.grisChip,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _textoProgreso,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColores.titulo,
            ),
          ),
          if (diasSeguidos == 0) ...[
            const SizedBox(height: 6),
            const Text(
              'Entra cada día para hacer crecer tu planta.',
              style: TextStyle(fontSize: 12.5, color: AppColores.texto),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Racha máxima: ${racha.rachaMaxima}',
                  style: const TextStyle(fontSize: 12, color: AppColores.texto),
                ),
              ),
              Expanded(
                child: Text(
                  'Total: ${racha.totalDias} ${racha.totalDias == 1 ? 'día' : 'días'}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, color: AppColores.texto),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
