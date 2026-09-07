import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_state.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/productos_list_screen.dart';
import '../screens/producto_form_screen.dart';
import '../screens/producto_precios_screen.dart';
import '../screens/favoritos_screen.dart';
import '../screens/perfil_screen.dart';

/// Puente entre Riverpod y go_router: go_router necesita un
/// Listenable para saber cuándo re-evaluar el `redirect`. Riverpod no
/// es un Listenable por sí mismo, así que este notifier escucha el
/// authProvider y notifica al router cada vez que cambia la sesión.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final estaAutenticado = ref.read(isAuthenticatedProvider);
      final vaALogin = state.matchedLocation == '/login';
      final vaARegistro = state.matchedLocation == '/register';
      final esRutaPublica = vaALogin || vaARegistro;

      // No autenticado intentando entrar a una ruta protegida:
      // se preserva el destino original en el query param `from`,
      // para volver ahí automáticamente después del login.
      if (!estaAutenticado && !esRutaPublica) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      // Ya autenticado pero intentando ver login/registro de nuevo:
      // lo mandamos directo al listado.
      if (estaAutenticado && esRutaPublica) {
        return '/productos';
      }

      return null; // sin redirección
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return LoginScreen(destinoPendiente: from);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/productos',
        builder: (context, state) => const ProductosListScreen(),
        routes: [
          // RUTA ANIDADA: /productos/nuevo es hija de /productos.
          GoRoute(
            path: 'nuevo',
            builder: (context, state) => const ProductoFormScreen(),
          ),
        ],
      ),
      GoRoute(
        // Parámetro por la propia ruta (no por objetos transportados
        // entre pantallas): con solo el `id` de la URL, esta pantalla
        // puede reconstruirse por completo pidiendo sus datos al backend.
        path: '/productos/:id/precios',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductoPreciosScreen(productoId: id);
        },
      ),
      GoRoute(
        path: '/favoritos',
        builder: (context, state) => const FavoritosScreen(),
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const PerfilScreen(),
      ),
    ],
  );
});
