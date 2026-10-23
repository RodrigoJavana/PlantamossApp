"""Sirve la compilación web de la app (build/web_preview) y reenvía /api a la API en la nube.

Solo para revisar la app en el navegador contra api.plantamoss.online sin tocar el CORS
de producción: el navegador ve todo en el mismo origen (localhost:8101).
Uso: python tool/servidor_nube.py   (luego, en la app, servidor = http://localhost:8101/api)
"""
import http.server
import os
import urllib.error
import urllib.request

PUERTO = 8101
NUBE = 'https://api.plantamoss.online'
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build', 'web_preview')
CABECERAS_OMITIDAS = {'host', 'origin', 'referer', 'content-length', 'connection', 'accept-encoding'}


class Manejador(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=RAIZ, **kwargs)

    def _reenviar(self):
        largo = int(self.headers.get('Content-Length') or 0)
        cuerpo = self.rfile.read(largo) if largo else None
        peticion = urllib.request.Request(NUBE + self.path, data=cuerpo, method=self.command)
        for k, v in self.headers.items():
            if k.lower() not in CABECERAS_OMITIDAS:
                peticion.add_header(k, v)
        try:
            respuesta = urllib.request.urlopen(peticion, timeout=30)
        except urllib.error.HTTPError as e:
            respuesta = e
        datos = respuesta.read()
        self.send_response(respuesta.status if hasattr(respuesta, 'status') else respuesta.code)
        for k, v in respuesta.headers.items():
            if k.lower() not in ('transfer-encoding', 'connection', 'content-length', 'content-encoding'):
                self.send_header(k, v)
        self.send_header('Content-Length', str(len(datos)))
        self.end_headers()
        self.wfile.write(datos)

    def do_GET(self):
        if self.path.startswith('/api/'):
            return self._reenviar()
        return super().do_GET()

    def do_POST(self):
        self._reenviar()

    def do_PUT(self):
        self._reenviar()

    def do_DELETE(self):
        self._reenviar()


if __name__ == '__main__':
    print(f'App en http://localhost:{PUERTO} -> API {NUBE}')
    http.server.ThreadingHTTPServer(('127.0.0.1', PUERTO), Manejador).serve_forever()
