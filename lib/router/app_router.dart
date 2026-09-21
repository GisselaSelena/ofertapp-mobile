import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_state.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/productos_list_screen.dart';
import '../screens/producto_form_screen.dart';
import '../screens/producto_precios_screen.dart';
import '../screens/reportar_precio_screen.dart';
import '../screens/favoritos_screen.dart';
import '../screens/perfil_screen.dart';

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

      if (!estaAutenticado && !esRutaPublica) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (estaAutenticado && esRutaPublica) {
        return '/productos';
      }
      return null;
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
          GoRoute(
            path: 'nuevo',
            builder: (context, state) => const ProductoFormScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/productos/:id/precios',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductoPreciosScreen(productoId: id);
        },
        routes: [
          GoRoute(
            path: 'reportar',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ReportarPrecioScreen(productoId: id);
            },
          ),
        ],
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