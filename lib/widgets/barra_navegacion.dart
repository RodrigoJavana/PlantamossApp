// Barra de navegación inferior estándar (Material 3 NavigationBar):
// de borde a borde, fondo blanco, línea superior sutil, ícono + etiqueta
// siempre visibles. El destino activo lleva ícono relleno, etiqueta negra
// y una píldora gris muy clara detrás del ícono (sin verde).
import 'package:flutter/material.dart';

import '../config/tema.dart';

class ItemNavegacion {
  final IconData icono;
  final IconData iconoActivo;
  final String texto;
  const ItemNavegacion(this.icono, this.iconoActivo, this.texto);
}

class BarraNavegacion extends StatelessWidget {
  final List<ItemNavegacion> items;
  final int indice;
  final ValueChanged<int> alCambiar;

  const BarraNavegacion({
    super.key,
    required this.items,
    required this.indice,
    required this.alCambiar,
  });

  static const _grisInactivo = Color(0xFF8A968E);
  static const _indicador = Color(0xFFEEF1EF);

  @override
  Widget build(BuildContext context) {
    // Con 5 destinos, el texto grande del sistema se limita para que las etiquetas no se corten.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: DecoratedBox(
        // Línea superior sutil en lugar de sombra.
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColores.borde)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            indicatorColor: _indicador,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            iconTheme: WidgetStateProperty.resolveWith(
              (estados) => IconThemeData(
                size: 24,
                color: estados.contains(WidgetState.selected)
                    ? AppColores.titulo
                    : _grisInactivo,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (estados) => TextStyle(
                fontSize: 11.5,
                fontWeight: estados.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: estados.contains(WidgetState.selected)
                    ? AppColores.titulo
                    : _grisInactivo,
              ),
            ),
          ),
          // NavigationBar ya respeta el SafeArea inferior y anima el indicador.
          child: NavigationBar(
            selectedIndex: indice,
            onDestinationSelected: alCambiar,
            animationDuration: const Duration(milliseconds: 300),
            destinations: [
              for (final item in items)
                NavigationDestination(
                  icon: Icon(item.icono),
                  selectedIcon: Icon(item.iconoActivo),
                  label: item.texto,
                  tooltip: '',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
