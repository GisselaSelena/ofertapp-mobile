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

Widget _pantallaConEstado(RemoteOpState<List<Producto>> estado) {
  return ProviderScope(
    overrides: [
      productosProvider.overrideWith((ref) => _FakeProductosNotifier(estado)),
    ],
    child: const MaterialApp(home: ProductosListScreen()),
  );
}

void main() {
  group('ProductosListScreen', () {
    testWidgets('estado cargando -> muestra un indicador de progreso', (tester) async {
      await tester.pumpWidget(_pantallaConEstado(const RemoteLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('estado con datos -> muestra los productos en la grilla', (tester) async {
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

    testWidgets('estado vacío -> muestra el mensaje de lista vacía', (tester) async {
      await tester.pumpWidget(_pantallaConEstado(const RemoteSuccess(<Producto>[])));
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay productos registrados'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('estado con error -> muestra el mensaje de error real', (tester) async {
      await tester.pumpWidget(
        _pantallaConEstado(const RemoteError('No se pudo cargar el listado')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error: No se pudo cargar el listado'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
