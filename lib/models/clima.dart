// Clima actual de una ciudad (ClimaDto de /externo/clima).
class ClimaActual {
  final bool ok;
  final double? temp;
  final double? sensacion;
  final int? humedad;
  final double? viento;
  final String? descripcion;

  /// Código de OpenWeather (ej. "01d").
  final String? icono;

  const ClimaActual({
    required this.ok,
    this.temp,
    this.sensacion,
    this.humedad,
    this.viento,
    this.descripcion,
    this.icono,
  });

  factory ClimaActual.fromJson(Map<String, dynamic> json) => ClimaActual(
    ok: json['ok'] == true,
    temp: (json['temp'] as num?)?.toDouble(),
    sensacion: (json['sensacion'] as num?)?.toDouble(),
    humedad: (json['humedad'] as num?)?.toInt(),
    viento: (json['viento'] as num?)?.toDouble(),
    descripcion: json['descripcion']?.toString(),
    icono: json['icono']?.toString(),
  );
}
