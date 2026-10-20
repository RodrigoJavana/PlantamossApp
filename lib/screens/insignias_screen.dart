// Pantalla "Insignias": resumen, filtro por categoría y cuadrícula de logros.
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/insignia.dart';
import '../services/insignias_service.dart';
import '../widgets/comunes.dart';
import '../widgets/insignia_tarjeta.dart';

class InsigniasScreen extends StatefulWidget {
  const InsigniasScreen({super.key});

  @override
  State<InsigniasScreen> createState() => _InsigniasScreenState();
}

class _InsigniasScreenState extends State<InsigniasScreen> {
  static const _todas = 'Todas';

  /// Categorías del contrato, en orden de chips. Las que lleguen de la API y no estén aquí se agregan al final.
  static const _categoriasBase = ['Plantas', 'Mapa', 'Blog', 'Racha', 'Fechas'];
  String _filtro = _todas;

  @override
  void initState() {
    super.initState();
    InsigniasService.instancia.cargar();
  }

  Future<void> _recargar() => InsigniasService.instancia.cargar();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      appBar: AppBar(title: const Text('Insignias')),
      body: ValueListenableBuilder<List<Insignia>>(
        valueListenable: InsigniasService.instancia.insignias,
        builder: (_, lista, _) {
          final ganadas = lista.where((i) => i.desbloqueada).length;
          final categorias = <String>[..._categoriasBase];
          for (final i in lista) {
            if (!categorias.contains(i.categoria)) categorias.add(i.categoria);
          }
          // Si la categoría elegida ya no existe, vuelve a "Todas".
          final filtro = _filtro == _todas || categorias.contains(_filtro)
              ? _filtro
              : _todas;
          final visibles = filtro == _todas
              ? lista
              : lista.where((i) => i.categoria == filtro).toList();

          return RefreshIndicator(
            color: AppColores.verdeOscuro,
            onRefresh: _recargar,
            child: CustomScrollView(
              // Así se puede jalar para recargar aunque haya pocas insignias.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$ganadas de ${lista.length} ganadas',
                          key: const Key('resumen_insignias'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColores.titulo,
                          ),
                        ),
                        if (lista.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final c in [_todas, ...categorias])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(c),
                                      selected: filtro == c,
                                      selectedColor: AppColores.verdeOscuro,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: AppColores.borde,
                                      ),
                                      showCheckmark: false,
                                      labelStyle: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: filtro == c
                                            ? Colors.white
                                            : AppColores.titulo,
                                      ),
                                      onSelected: (_) =>
                                          setState(() => _filtro = c),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (lista.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: MensajeEstado(
                        icono: Icons.military_tech_outlined,
                        texto: 'Aún no hay insignias para mostrar.',
                        textoBoton: 'Reintentar',
                        alPresionar: _recargar,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 300,
                          ),
                      itemCount: visibles.length,
                      itemBuilder: (_, i) =>
                          InsigniaTarjeta(insignia: visibles[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
