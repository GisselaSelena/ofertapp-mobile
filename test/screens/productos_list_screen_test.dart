import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ofertapp_mobile/models/models.dart';
import 'package:ofertapp_mobile/screens/productos_list_screen.dart';
import 'package:ofertapp_mobile/services/api_client.dart';
import 'package:ofertapp_mobile/state/auth_state.dart';
import 'package:ofertapp_mobile/state/productos_state.dart';

/// Notifier falso: fija el estado en el constructor y anula cargar() (que
/// intentaría una llamada de red real) para que initState() no la pise.
class _FakeProductosNotifier extends ProductosNotifier {
  _FakeProductosNotifier(RemoteOpState<List<Producto>> inicial)
    : super(ApiClient(), AuthNotifier(ApiClient())) {
    state = inicial;
  }

  @override
  Future<void> cargar() async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier({required bool administrador}) : super(ApiClient()) {
    state = AuthState(
      token: 'token',
      usuario: Usuario(
        id: 'usuario-1',
        nombre: 'Usuario de prueba',
        email: 'test@example.com',
        rol: administrador ? 'administrador' : 'usuario',
      ),
    );
  }
}

class _Api409Client extends ApiClient {
  _Api409Client(this.mensaje);

  final String mensaje;

  @override
  Future<dynamic> delete(String path) async {
    throw ApiException(mensaje);
  }
}

Widget _pantallaConEstado(
  RemoteOpState<List<Producto>> estado, {
  bool administrador = false,
  ApiClient? apiClient,
}) {
  return ProviderScope(
    overrides: [
      productosProvider.overrideWith((ref) => _FakeProductosNotifier(estado)),
      authProvider.overrideWith(
        (ref) => _FakeAuthNotifier(administrador: administrador),
      ),
      if (apiClient != null) apiClientProvider.overrideWithValue(apiClient),
    ],
    child: const MaterialApp(home: ProductosListScreen()),
  );
}

void main() {
  group('ProductosListScreen', () {
    testWidgets('estado cargando -> muestra un indicador de progreso', (
      tester,
    ) async {
      await tester.pumpWidget(_pantallaConEstado(const RemoteLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('estado con datos -> muestra los productos en la grilla', (
      tester,
    ) async {
      final productos = [
        Producto(id: '1', nombre: 'Arroz Diana 1kg', categoria: 'abarrotes'),
        Producto(id: '2', nombre: 'Aceite La Favorita'),
      ];

      await tester.pumpWidget(_pantallaConEstado(RemoteSuccess(productos)));
      await tester.pumpAndSettle();

      expect(find.text('Arroz Diana 1kg'), findsOneWidget);
      expect(find.text('Aceite La Favorita'), findsOneWidget);
      expect(find.text('abarrotes'), findsOneWidget);
      expect(find.text('Aún no hay productos registrados'), findsNothing);
    });

    testWidgets('usuario normal no ve opciones de edición ni eliminación', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pantallaConEstado(RemoteSuccess([Producto(id: '1', nombre: 'Arroz')])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.text('Nuevo'), findsNothing);
    });

    testWidgets('administrador ve opciones de edición y eliminación', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pantallaConEstado(
          RemoteSuccess([Producto(id: '1', nombre: 'Arroz')]),
          administrador: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('409 de eliminación muestra el mensaje del servidor', (
      tester,
    ) async {
      const mensaje =
          'No se puede eliminar el producto 1: tiene precios asociados';
      await tester.pumpWidget(
        _pantallaConEstado(
          RemoteSuccess([Producto(id: '1', nombre: 'Arroz')]),
          administrador: true,
          apiClient: _Api409Client(mensaje),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(find.text(mensaje), findsOneWidget);
      expect(find.text('Arroz'), findsOneWidget);
      expect(find.text('Eliminar producto'), findsNothing);
    });

    testWidgets('busqueda espera 300ms y cancela el debounce anterior', (
      tester,
    ) async {
      final productos = [
        Producto(id: '1', nombre: 'Arroz Diana 1kg', categoria: 'abarrotes'),
        Producto(id: '2', nombre: 'Aceite La Favorita'),
      ];

      await tester.pumpWidget(_pantallaConEstado(RemoteSuccess(productos)));
      await tester.pumpAndSettle();

      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      controller.text = 'ar';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      controller.text = 'aceite';
      await tester.pump();
      expect(find.text('Arroz Diana 1kg'), findsOneWidget);
      expect(find.text('Aceite La Favorita'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 299));
      expect(find.text('Arroz Diana 1kg'), findsOneWidget);
      expect(find.text('Aceite La Favorita'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Arroz Diana 1kg'), findsNothing);
      expect(find.text('Aceite La Favorita'), findsOneWidget);
    });

    testWidgets('estado vacío -> muestra el mensaje de lista vacía', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pantallaConEstado(const RemoteSuccess(<Producto>[])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay productos registrados'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('estado con error -> muestra el mensaje de error real', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pantallaConEstado(const RemoteError('No se pudo cargar el listado')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error: No se pudo cargar el listado'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
