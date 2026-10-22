// Pruebas de los modelos de blog: lectura de BlogDto y cuerpo de publicación.
import 'package:flutter_test/flutter_test.dart';

import 'package:plantamoss/models/blog.dart';

void main() {
  group('Blog.fromJson', () {
    test('lee todos los campos del BlogDto', () {
      final blog = Blog.fromJson({
        'idBlog': 7,
        'idUsuario': 3,
        'titulo': 'Cómo cuidar el nopal',
        'contenido': 'El nopal necesita sol y poco riego.',
        'contenido2': 'En lluvias, cuida el drenaje.',
        'contenido3': null,
        'urlImagen': 'https://ejemplo.com/a.jpg',
        'urlImagen2': '/img/agave-azul.jpeg',
        'urlImagen3': '',
        'urlImagen4': null,
        'urlImagen5': null,
        'fechaPublicacion': '2026-10-01T12:00:00',
        'autor': 'Rodrigo',
      });

      expect(blog.idBlog, 7);
      expect(blog.idUsuario, 3);
      expect(blog.titulo, 'Cómo cuidar el nopal');
      expect(blog.contenido2, 'En lluvias, cuida el drenaje.');
      expect(blog.contenido3, isNull);
      expect(blog.fechaPublicacion, isNotNull);
      expect(blog.autor, 'Rodrigo');
      // Las imágenes vacías no cuentan.
      expect(blog.imagenes, [
        'https://ejemplo.com/a.jpg',
        '/img/agave-azul.jpeg',
      ]);
      expect(blog.parrafos, hasLength(2));
    });

    test('tolera campos faltantes y usa Anónimo como autor', () {
      final blog = Blog.fromJson({
        'idBlog': 1,
        'titulo': 'T',
        'contenido': 'C',
      });

      expect(blog.idUsuario, isNull);
      expect(blog.urlImagen, isNull);
      expect(blog.fechaPublicacion, isNull);
      expect(blog.imagenes, isEmpty);
      expect(blog.autorMostrado, 'Anónimo');
      expect(fechaCorta(blog.fechaPublicacion), '');
    });

    test('el extracto corta a 120 caracteres', () {
      final largo = 'a' * 200;
      final blog = Blog.fromJson({
        'idBlog': 2,
        'titulo': 'T',
        'contenido': largo,
      });

      expect(blog.extracto.endsWith('...'), isTrue);
      expect(blog.extracto.length, 123);
    });
  });

  group('BlogEntrada.toJson', () {
    test('manda los mismos campos que la web y nulos para lo vacío', () {
      const entrada = BlogEntrada(
        titulo: '  Mi blog  ',
        contenido: ' Texto del primer párrafo. ',
        contenido2: '   ',
        contenido3: null,
        urlImagen: 'https://ejemplo.com/p.jpg',
        extras: ['https://ejemplo.com/2.jpg', 'https://ejemplo.com/3.jpg'],
      );

      final json = entrada.toJson();

      expect(json['titulo'], 'Mi blog');
      expect(json['contenido'], 'Texto del primer párrafo.');
      expect(json['contenido2'], isNull);
      expect(json['contenido3'], isNull);
      expect(json['urlImagen'], 'https://ejemplo.com/p.jpg');
      expect(json['urlImagen2'], 'https://ejemplo.com/2.jpg');
      expect(json['urlImagen3'], 'https://ejemplo.com/3.jpg');
      expect(json['urlImagen4'], isNull);
      expect(json['urlImagen5'], isNull);
    });
  });

  test('fechaCorta usa dia, mes abreviado y año', () {
    expect(fechaCorta(DateTime(2026, 10, 7, 9)), '7 oct 2026');
  });
}
