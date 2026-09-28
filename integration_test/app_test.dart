// Integration test de extremo a extremo del recorrido crítico de OfertApp:
// login -> listado de productos -> tocar un producto -> comparación de
// precios con al menos un precio visible.
//
// Corre la app REAL (MyApp) con su router REAL (go_router, definido en
// app_router.dart) y sus pantallas/providers reales sin modificar -- lo
// único falso es el transporte HTTP: se inyecta un ApiClient real
// (lib/services/api_client.dart, sin tocarlo) construido con un
// http.Client falso, reutilizando exactamente el mismo mecanismo de
// override de providers de Riverpod que ya usan los widget tests de este
// repo (test/screens/*_test.dart): apiClientProvider.overrideWithValue(...).
//
// No requiere backend real ni conexión a internet: el fake responde en
// memoria a las tres rutas que este recorrido efectivamente llama.
//
// Cómo correrla: ver el mensaje final de la sesión que la agregó.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'package:ofertapp_mobile/main.dart';
import 'package:ofertapp_mobile/services/api_client.dart';
import 'package:ofertapp_mobile/state/auth_state.dart';

const _productoId = 'producto-arroz-1';

/// http.Client falso: extiende BaseClient (todos los métodos get/post del
/// paquete http se resuelven a través de send()) y responde en memoria a
/// las rutas reales del backend que este recorrido dispara. Cualquier otra
/// ruta devuelve 404, para que un endpoint no simulado falle de forma
/// obvia en vez de colgar la prueba.
class _FakeBackendClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final method = request.method;
    final path = request.url.path;

    if (method == 'POST' && path == '/api/auth/login') {
      return _json(200, {
        'access_token': 'jwt-de-prueba',
        'usuario': {
          'id': 'uuid-usuaria-prueba',
          'nombre': 'Usuaria de Prueba',
          'email': 'usuaria@ofertapp.test',
          'rol': 'usuario',
        },
      });
    }

    if (method == 'GET' && path == '/api/productos') {
      return _json(200, [
        {'id': _productoId, 'nombre': 'Arroz Diana 1kg', 'categoria': 'abarrotes'},
      ]);
    }

    if (method == 'GET' && path == '/api/productos/$_productoId/precios') {
      return _json(200, {
        'source': 'test',
        'count': 1,
        'precios': [
          {
            'id': 'precio-1',
            'valor': 1.65,
            'vigente_desde': '2026-09-01T00:00:00',
            'establecimiento': {
              'id': 'establecimiento-1',
              'nombre': 'Tía',
              'direccion': 'Av. de Prueba 123',
            },
            'fuente': {'usuario_id': 'admin-1', 'nombre': 'Admin'},
            'tiene_ubicacion': false,
            'tiene_foto_evidencia': false,
          },
        ],
      });
    }

    if (method == 'GET' && path == '/api/productos/$_productoId/resumen-ia') {
      // Simula que la IA no está disponible: la card correspondiente
      // simplemente no debe aparecer (comportamiento real de la pantalla).
      return _json(200, {'resumen': null, 'disponible': false});
    }

    return _json(404, {'detail': 'ruta no simulada en el fake: $method $path'});
  }

  http.StreamedResponse _json(int status, Object body) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      status,
      headers: const {'content-type': 'application/json'},
    );
  }
}

/// Pump acotado en vez de pumpAndSettle(): mientras se carga login/listado/
/// precios, la app muestra un CircularProgressIndicator indeterminado, que
/// nunca "asienta" (su animación reprograma frames para siempre) y hace
/// que pumpAndSettle() cuelgue hasta su timeout. Se pumpea en pasos cortos
/// hasta ver la condición esperada, con un límite de intentos.
Future<void> _pumpHasta(
  WidgetTester tester,
  bool Function() condicion, {
  int maxIntentos = 50,
}) async {
  for (var intento = 0; intento < maxIntentos && !condicion(); intento++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'recorrido crítico: login -> listado -> tocar producto -> precios visibles',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Único punto de inyección: el resto de la app (router,
            // pantallas, notifiers) corre sin modificar. Todo lo que
            // depende de apiClientProvider (authProvider, productosProvider,
            // las pantallas que leen ref.read(apiClientProvider) directo)
            // queda automáticamente usando el cliente falso.
            apiClientProvider.overrideWithValue(
              ApiClient(client: _FakeBackendClient()),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();

      // --- Pantalla de login (ruta inicial real del router: /login) ---
      expect(find.widgetWithText(TextFormField, 'Correo'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo'),
        'usuaria@ofertapp.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'clave12345',
      );
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      // --- Esperar el listado real (login + navegación real por
      // go_router + ProductosNotifier.cargar() contra el fake) ---
      await _pumpHasta(tester, () => find.text('Arroz Diana 1kg').evaluate().isNotEmpty);
      expect(find.text('Arroz Diana 1kg'), findsOneWidget,
          reason: 'debería haber llegado al listado de productos con el producto de prueba');

      // --- Tocar el producto: navegación real a /productos/:id/precios ---
      await tester.tap(find.text('Arroz Diana 1kg'));
      await tester.pump();

      // --- Esperar la pantalla de comparación de precios con datos reales ---
      await _pumpHasta(tester, () => find.text('Comparar precios').evaluate().isNotEmpty);
      expect(find.text('Comparar precios'), findsOneWidget);

      await _pumpHasta(tester, () => find.text('Tía').evaluate().isNotEmpty);

      // Al menos una fila de precio visible, con el establecimiento y el
      // precio formateado reales que devolvió el fake.
      expect(find.text('Tía'), findsOneWidget);
      expect(find.textContaining(r'$1.65'), findsOneWidget);
    },
  );
}
