// Estructura principal después del login:
// header verde con la marca + 3 pestañas con barra inferior tipo píldora.
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../services/insignias_service.dart';
import '../services/racha_service.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/comunes.dart';
import '../widgets/insignia_tarjeta.dart';
import 'blog_screen.dart';
import 'inicio_screen.dart';
import 'insignias_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';
import 'plantas_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  int _indice = 0;

  /// true mientras hay un aviso de insignia abierto (o la pantalla de insignias).
  bool _mostrandoInsignia = false;

  static const _items = [
    ItemNavegacion(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    ItemNavegacion(Icons.eco_outlined, Icons.eco_rounded, 'Plantas'),
    ItemNavegacion(Icons.map_outlined, Icons.map_rounded, 'Mapa'),
    ItemNavegacion(Icons.article_outlined, Icons.article_rounded, 'Blog'),
    ItemNavegacion(
      Icons.person_outline_rounded,
      Icons.person_rounded,
      'Perfil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Esta pantalla solo existe con sesión (login o restaurada): registra la visita de hoy.
    WidgetsBinding.instance.addObserver(this);
    _registrarVisita();
    InsigniasService.instancia.porMostrar.addListener(_revisarInsignias);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    InsigniasService.instancia.porMostrar.removeListener(_revisarInsignias);
    super.dispose();
  }

  // Si la app vuelve a primer plano otro día, cuenta como nueva visita.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _registrarVisita();
  }

  // Registra la racha y luego revisa si se ganó alguna insignia.
  Future<void> _registrarVisita() async {
    await RachaService.instancia.registrar();
    await InsigniasService.instancia.cargar();
  }

  // Muestra la primera insignia de la cola, una a la vez, desde cualquier pestaña.
  void _revisarInsignias() {
    if (_mostrandoInsignia || !mounted) return;
    final cola = InsigniasService.instancia.porMostrar.value;
    if (cola.isEmpty) return;
    _mostrandoInsignia = true;
    showDialog<bool>(
      context: context,
      builder: (_) => InsigniaGanadaDialogo(insignia: cola.first),
    ).then((verTodas) async {
      InsigniasService.instancia.quitarPrimera();
      if (verTodas == true && mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const InsigniasScreen()));
      }
      _mostrandoInsignia = false;
      _revisarInsignias();
    });
  }

  void _cambiar(int i) => setState(() => _indice = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      appBar: AppBar(toolbarHeight: 60, title: const LogoMarca(tamano: 30)),
      // IndexedStack conserva el estado de cada pestaña al cambiar.
      body: IndexedStack(
        index: _indice,
        children: [
          InicioScreen(
            irAPlantas: () => _cambiar(1),
            irAMapa: () => _cambiar(2),
            irABlog: () => _cambiar(3),
          ),
          const PlantasScreen(),
          const MapaScreen(),
          const BlogScreen(),
          const PerfilScreen(),
        ],
      ),
      bottomNavigationBar: BarraNavegacion(
        items: _items,
        indice: _indice,
        alCambiar: _cambiar,
      ),
    );
  }
}
