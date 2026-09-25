import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import 'auth_state.dart';

/// Tipo cerrado (sealed class): representa los estados posibles de una
/// operación remota, mutuamente excluyentes. En cualquier momento la
/// operación está en EXACTAMENTE uno de estos cuatro casos, nunca en
/// una combinación de ellos.
sealed class RemoteOpState<T> {
  const RemoteOpState();
}

class RemoteIdle<T> extends RemoteOpState<T> {
  const RemoteIdle();
}

class RemoteLoading<T> extends RemoteOpState<T> {
  const RemoteLoading();
}

class RemoteSuccess<T> extends RemoteOpState<T> {
  final T data;
  const RemoteSuccess(this.data);
}

class RemoteError<T> extends RemoteOpState<T> {
  final String message;
  final Map<String, String>? fieldErrors; // presente si fue un 422
  const RemoteError(this.message, {this.fieldErrors});
}

/// Notifier para el LISTADO de productos (GET /api/productos).
class ProductosNotifier extends StateNotifier<RemoteOpState<List<Producto>>> {
  final ApiClient _apiClient;
  final AuthNotifier _authNotifier;

  ProductosNotifier(this._apiClient, this._authNotifier)
      : super(const RemoteIdle());

  Future<void> cargar() async {
    state = const RemoteLoading();
    try {
      final data = await _apiClient.get('/api/productos');
      final productos = (data as List)
          .map((p) => Producto.fromJson(p))
          .toList();
      state = RemoteSuccess(productos);
    } on AuthException {
      _authNotifier.sessionExpired();
      state = const RemoteError('Sesión expirada');
    } on ForbiddenException catch (e) {
      state = RemoteError(e.message);
    } catch (e) {
      state = RemoteError(mensajeDeError(e));
    }
  }
}

final productosProvider =
    StateNotifierProvider<ProductosNotifier, RemoteOpState<List<Producto>>>(
        (ref) {
  return ProductosNotifier(
    ref.watch(apiClientProvider),
    ref.watch(authProvider.notifier),
  );
});

/// Notifier para la CREACIÓN de un producto (POST /api/productos).
/// Separado del listado porque es una operación distinta con su propio
/// ciclo de vida (idle -> loading -> success/error).
class CrearProductoNotifier extends StateNotifier<RemoteOpState<Producto>> {
  final ApiClient _apiClient;
  final AuthNotifier _authNotifier;

  CrearProductoNotifier(this._apiClient, this._authNotifier)
      : super(const RemoteIdle());

  Future<void> crear({required String nombre, String? categoria}) async {
    state = const RemoteLoading();
    try {
      final data = await _apiClient.post('/api/productos', {
        'nombre': nombre,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      });
      state = RemoteSuccess(Producto.fromJson(data));
    } on AuthException {
      _authNotifier.sessionExpired();
      state = const RemoteError('Sesión expirada');
    } on ForbiddenException catch (e) {
      state = RemoteError(e.message);
    } on ValidationException catch (e) {
      state = RemoteError('Revisa los campos marcados',
          fieldErrors: e.fieldErrors);
    } catch (e) {
      state = RemoteError(mensajeDeError(e));
    }
  }

  void reset() => state = const RemoteIdle();
}

final crearProductoProvider =
    StateNotifierProvider<CrearProductoNotifier, RemoteOpState<Producto>>(
        (ref) {
  return CrearProductoNotifier(
    ref.watch(apiClientProvider),
    ref.watch(authProvider.notifier),
  );
});
