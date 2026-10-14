// Detalle de una planta: imagen grande (Hero), datos y cuidados.
import 'package:flutter/material.dart';

import '../config/constantes.dart';
import '../config/tema.dart';
import '../models/planta.dart';
import '../services/insignias_service.dart';
import '../widgets/comunes.dart';
import '../widgets/imagen_planta.dart';

class PlantaDetalleScreen extends StatefulWidget {
  final Planta planta;
  const PlantaDetalleScreen({super.key, required this.planta});

  @override
  State<PlantaDetalleScreen> createState() => _PlantaDetalleScreenState();
}

class _PlantaDetalleScreenState extends State<PlantaDetalleScreen> {
  @override
  void initState() {
    super.initState();
    // Cuenta como planta vista para las insignias (una vez por sesión).
    InsigniasService.instancia.evento(
      'VER_PLANTA',
      '${widget.planta.idPlanta}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final planta = widget.planta;
    final clima = buscarClima(planta.tipoClima);
    final luz = buscarLuz(planta.luzSol);

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColores.verdeOscuro,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  key: const Key('boton_volver'),
                  tooltip: 'Volver',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColores.titulo,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'planta-${planta.idPlanta}',
                child: ImagenPlanta(url: planta.urlImagen, tamanoIcono: 64),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planta.nombrePlanta,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColores.titulo,
                    ),
                  ),
                  if ((planta.nombreCientifico ?? '').isNotEmpty)
                    Text(
                      planta.nombreCientifico!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppColores.texto,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((planta.nombreEstado ?? '').isNotEmpty)
                        ChipInfo(
                          icono: Icons.location_on_outlined,
                          texto: planta.nombreEstado!,
                          grande: true,
                        ),
                      if (clima != null)
                        ChipInfo(
                          icono: clima.icono,
                          texto: clima.etiqueta,
                          grande: true,
                        ),
                      if (luz != null)
                        ChipInfo(
                          icono: luz.icono,
                          texto: luz.etiqueta,
                          grande: true,
                        ),
                      if ((planta.riego ?? '').isNotEmpty)
                        ChipInfo(
                          icono: Icons.water_drop_outlined,
                          texto: planta.riego!,
                          grande: true,
                        ),
                    ],
                  ),
                  if ((planta.descripcion ?? '').isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Tarjeta(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TituloSeccion(
                            icono: Icons.info_outline_rounded,
                            texto: 'Descripción',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            planta.descripcion!,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.55,
                              color: AppColores.titulo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if ((planta.cuidadosTexto ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Tarjeta(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TituloSeccion(
                            icono: Icons.spa_outlined,
                            texto: 'Cuidados',
                          ),
                          const SizedBox(height: 10),
                          // Text respeta los saltos de línea (\n) del texto.
                          Text(
                            planta.cuidadosTexto!.replaceAll('\r\n', '\n'),
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.6,
                              color: AppColores.titulo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
