// Muestra la imagen de una planta/noticia.
//
// - URL absoluta (http/https)  -> imagen de red.
// - Ruta relativa "/img/x.jpeg" -> asset local "assets/img/x.jpeg"
//   (esas imágenes las sirve el front web, por eso se copiaron a la app).
// - Sin URL o si falla          -> placeholder verde suave con un brote.
import 'package:flutter/material.dart';

import '../config/tema.dart';

class ImagenPlanta extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double tamanoIcono;

  const ImagenPlanta({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.tamanoIcono = 32,
  });

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();
    final placeholder = PlaceholderPlanta(tamanoIcono: tamanoIcono);

    if (u.startsWith('http://') || u.startsWith('https://')) {
      return Image.network(
        u,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        // En Flutter web, si el servidor no permite CORS se usa un <img> normal.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progreso) =>
            progreso == null ? child : Container(color: AppColores.verdeSuave),
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    if (u.startsWith('/img/')) {
      return Image.asset(
        'assets${u.split('?').first}',
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return placeholder;
  }
}

/// Fondo verde suave con ícono de brote (cuando no hay imagen).
class PlaceholderPlanta extends StatelessWidget {
  final double tamanoIcono;
  const PlaceholderPlanta({super.key, this.tamanoIcono = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColores.verdeSuave,
      alignment: Alignment.center,
      child: Icon(
        Icons.eco_rounded,
        size: tamanoIcono,
        color: AppColores.verdeClaro,
      ),
    );
  }
}
