// Validaciones de entradas de la app (formularios y búsqueda).
// Devuelven null si el valor es válido, o el texto del error.

/// Longitudes máximas (iguales o menores a las de la API).
class Limites {
  Limites._();
  static const email = 254;
  static const password = 128;
  static const host = 253;
  static const puerto = 5;
  static const url = 2048;
  static const busqueda = 80;
}

class Validadores {
  Validadores._();

  static final _reEmail = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.[A-Za-z]{2,}$",
  );
  static final _reIpv4 = RegExp(
    r'^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$',
  );
  static final _reHost = RegExp(
    r'^(?=.{1,253}$)([A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$',
  );

  static String? email(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Escribe tu correo.';
    if (t.length > Limites.email || !_reEmail.hasMatch(t)) {
      return 'Correo inválido.';
    }
    return null;
  }

  static String? password(String? v) {
    final t = v ?? '';
    if (t.trim().isEmpty) return 'Escribe tu contraseña.';
    if (t.length > Limites.password) {
      return 'Máximo ${Limites.password} caracteres.';
    }
    return null;
  }

  /// IPv4 o nombre de host (sin esquema ni puerto).
  static String? host(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Escribe la IP o el host.';
    final pareceIp = RegExp(r'^[\d.]+$').hasMatch(t);
    if (pareceIp ? !_reIpv4.hasMatch(t) : !_reHost.hasMatch(t)) {
      return 'IP o host inválido.';
    }
    return null;
  }

  static String? puerto(String? v) {
    final t = (v ?? '').trim();
    final p = int.tryParse(t);
    if (p == null || p < 1 || p > 65535 || !RegExp(r'^\d+$').hasMatch(t)) {
      return 'Puerto inválido (1-65535).';
    }
    return null;
  }

  /// URL completa opcional. Si se llena debe ser https con host válido.
  static String? urlHttps(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (t.length > Limites.url) return 'URL demasiado larga.';
    final uri = Uri.tryParse(t);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Debe ser una URL https válida.';
    }
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      return 'Quita parámetros o usuario de la URL.';
    }
    if (host(uri.host) != null) return 'Host inválido.';
    return null;
  }

  /// URL http o https (como exige el formulario de blogs de la web).
  static bool esUrlHttp(String? v) => RegExp(
    r'^https?://\S+$',
    caseSensitive: false,
  ).hasMatch((v ?? '').trim());

  /// Texto de búsqueda saneado: sin caracteres de control, espacios
  /// colapsados y longitud máxima.
  static String sanearBusqueda(String? v) {
    var t = (v ?? '').replaceAll(RegExp(r'[\x00-\x1F\x7F<>]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > Limites.busqueda) {
      t = t.substring(0, Limites.busqueda).trim();
    }
    return t;
  }
}
