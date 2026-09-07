import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Guarda lo que el usuario ha escrito en el formulario de "nuevo
/// producto" mientras la app sigue abierta. Al ser un provider (estado
/// de aplicación, no local al widget), el contenido sobrevive aunque el
/// usuario navegue a otra pantalla y regrese, porque la pantalla del
/// formulario se reconstruye leyendo este estado en vez de partir de
/// campos vacíos.
class ProductoFormDraft {
  final String nombre;
  final String categoria;

  const ProductoFormDraft({this.nombre = '', this.categoria = ''});

  ProductoFormDraft copyWith({String? nombre, String? categoria}) {
    return ProductoFormDraft(
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
    );
  }
}

class ProductoFormDraftNotifier extends StateNotifier<ProductoFormDraft> {
  ProductoFormDraftNotifier() : super(const ProductoFormDraft());

  void actualizarNombre(String value) {
    state = state.copyWith(nombre: value);
  }

  void actualizarCategoria(String value) {
    state = state.copyWith(categoria: value);
  }

  void limpiar() {
    state = const ProductoFormDraft();
  }
}

final productoFormDraftProvider =
    StateNotifierProvider<ProductoFormDraftNotifier, ProductoFormDraft>(
        (ref) => ProductoFormDraftNotifier());
