// Modelo del usuario (UserDto de la API).
class Usuario {
  final int id;
  final String name;
  final String email;
  final String role;
  final String estado;
  final bool emailVerificado;
  final String? createdAt;

  const Usuario({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.estado,
    required this.emailVerificado,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? 'user',
    estado: json['estado']?.toString() ?? 'activo',
    emailVerificado: json['emailVerificado'] == true,
    createdAt: json['createdAt']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'estado': estado,
    'emailVerificado': emailVerificado,
    'createdAt': createdAt,
  };

  /// Primer nombre para el saludo ("Rodrigo Javana" -> "Rodrigo").
  String get primerNombre {
    final partes = name.trim().split(RegExp(r'\s+'));
    return partes.isEmpty || partes.first.isEmpty ? 'Usuario' : partes.first;
  }

  /// Letra para el avatar.
  String get inicial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Nombre del rol en español.
  String get rolTexto {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'editor':
        return 'Editor';
      case 'noticias':
        return 'Noticias';
      default:
        return 'Usuario';
    }
  }
}
