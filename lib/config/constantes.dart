// Constantes generales de la app: servidor por defecto, claves de
// almacenamiento y etiquetas/íconos de clima y luz.
import 'package:flutter/material.dart';

/// Servidor por defecto: la API publicada en la nube (solo https).
const String kUrlNube = 'https://api.plantamoss.online/api';

/// Preset "Red local (desarrollo)": IP del PC donde corre la API en la Wi-Fi.
/// Solo para desarrollo, por eso va en http.
const String kEsquemaPorDefecto = 'http';
const String kIpPorDefecto = '10.16.0.72';
const String kPuertoPorDefecto = '5080';

/// Claves usadas en shared_preferences (solo datos NO sensibles).
class ClavesPrefs {
  ClavesPrefs._();
  static const esquema = 'pm_servidor_esquema';
  static const ip = 'pm_servidor_ip';
  static const puerto = 'pm_servidor_puerto';
  static const urlCompleta = 'pm_servidor_url';

  /// Claves de la versión anterior (sesión en texto plano). Solo para migrar.
  static const tokenViejo = 'pm_token';
  static const usuarioViejo = 'pm_user';
}

/// Una opción de filtro (valor que espera la API + texto + ícono).
class OpcionFiltro {
  final String valor;
  final String etiqueta;
  final IconData icono;
  const OpcionFiltro(this.valor, this.etiqueta, this.icono);
}

/// tipoClima: tropical | arido | templado | frio
const List<OpcionFiltro> kClimas = [
  OpcionFiltro('tropical', 'Tropical', Icons.forest_rounded),
  OpcionFiltro('arido', 'Árido', Icons.landscape_rounded),
  OpcionFiltro('templado', 'Templado', Icons.thermostat_rounded),
  OpcionFiltro('frio', 'Frío', Icons.ac_unit_rounded),
];

/// luzSol: sol_directo | sombra_parcial | sombra
const List<OpcionFiltro> kLuces = [
  OpcionFiltro('sol_directo', 'Sol directo', Icons.wb_sunny_rounded),
  OpcionFiltro('sombra_parcial', 'Sombra parcial', Icons.wb_cloudy_rounded),
  OpcionFiltro('sombra', 'Sombra', Icons.nights_stay_rounded),
];

OpcionFiltro? buscarClima(String? valor) {
  for (final c in kClimas) {
    if (c.valor == valor) return c;
  }
  return null;
}

OpcionFiltro? buscarLuz(String? valor) {
  for (final l in kLuces) {
    if (l.valor == valor) return l;
  }
  return null;
}

/// Código de ícono de OpenWeather (ej. "01d") -> ícono Material.
IconData iconoClimaOpenWeather(String? codigo) {
  switch ((codigo ?? '').padRight(3).substring(0, 2)) {
    case '01':
      return (codigo ?? '').endsWith('n')
          ? Icons.nightlight_round
          : Icons.wb_sunny_rounded;
    case '02':
      return (codigo ?? '').endsWith('n')
          ? Icons.nights_stay_rounded
          : Icons.wb_cloudy_rounded;
    case '03':
    case '04':
      return Icons.cloud_rounded;
    case '09':
    case '10':
      return Icons.water_drop_rounded;
    case '11':
      return Icons.thunderstorm_rounded;
    case '13':
      return Icons.ac_unit_rounded;
    case '50':
      return Icons.blur_on_rounded;
    default:
      return Icons.thermostat_rounded;
  }
}
