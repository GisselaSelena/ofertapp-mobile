/// Validadores de formulario puros, reutilizados por login, registro y el
/// formulario de producto. Extraídos de los State privados que los tenían
/// duplicados, para poder probarlos sin montar ningún widget.
library;

String? validarEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
  if (!value.contains('@')) return 'Ingresa un correo válido';
  return null;
}

String? validarPassword(String? value) {
  if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
  if (value.length < 6) return 'Debe tener al menos 6 caracteres';
  return null;
}

String? validarNombre(String? value) {
  if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
  return null;
}

String? validarNombreProducto(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El nombre es obligatorio';
  }
  if (value.trim().length < 3) {
    return 'Debe tener al menos 3 caracteres';
  }
  return null;
}
