class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.rol = 'usuario',
  });

  bool get esAdministrador => rol == 'administrador';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: (json['rol'] as String?) ?? 'usuario',
    );
  }
}

class Producto {
  final String id;
  final String nombre;
  final String? categoria;

  Producto({required this.id, required this.nombre, this.categoria});

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String?,
    );
  }
}