/// Formateo compartido de precios. Extraído de producto_precios_screen.dart,
/// que interpolaba el valor crudo (`'\$${valor}'`, sin decimales fijos) —
/// centralizarlo permite probarlo y evita que cada pantalla lo repita
/// distinto.
String formatearPrecio(num valor) => '\$${valor.toStringAsFixed(2)}';
