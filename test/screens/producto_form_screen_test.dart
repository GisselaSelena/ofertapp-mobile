import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ofertapp_mobile/screens/producto_form_screen.dart';
import 'package:ofertapp_mobile/services/api_client.dart';
import 'package:ofertapp_mobile/state/auth_state.dart';
import 'package:ofertapp_mobile/state/productos_state.dart';

/// Notifier falso para crearProductoProvider: cuenta cuántas veces se llamó
/// crear() (para probar que la validación de cliente bloquea el envío) y
/// simula la respuesta 422 real del backend (fieldErrors por campo) sin red.
class _FakeCrearProductoNotifier extends CrearProductoNotifier {
  _FakeCrearProductoNotifier() : super(ApiClient(), AuthNotifier(ApiClient()));

  int llamadas = 0;

  @override
  Future<void> crear({required String nombre, String? categoria}) async {
    llamadas++;
    state = const RemoteError(
      'Revisa los campos marcados',
      fieldErrors: {'nombre': 'Ya existe un producto con ese nombre'},
    );
  }
}

Widget _pantalla(CrearProductoNotifier fake) {
  return ProviderScope(
    overrides: [crearProductoProvider.overrideWith((ref) => fake)],
    child: const MaterialApp(home: ProductoFormScreen()),
  );
}

void main() {
  group('ProductoFormScreen', () {
    testWidgets('nombre vacío -> no llama a crear(), muestra el error de validación local',
        (tester) async {
      final fake = _FakeCrearProductoNotifier();
      await tester.pumpWidget(_pantalla(fake));

      await tester.tap(find.text('Guardar producto'));
      await tester.pumpAndSettle();

      expect(fake.llamadas, 0);
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
    });

    testWidgets('nombre con menos de 3 caracteres -> tampoco llama a crear()',
        (tester) async {
      final fake = _FakeCrearProductoNotifier();
      await tester.pumpWidget(_pantalla(fake));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'ab',
      );
      await tester.tap(find.text('Guardar producto'));
      await tester.pumpAndSettle();

      expect(fake.llamadas, 0);
      expect(find.text('Debe tener al menos 3 caracteres'), findsOneWidget);
    });

    testWidgets('nombre válido -> llama a crear() y muestra el error 422 del servidor en su campo',
        (tester) async {
      final fake = _FakeCrearProductoNotifier();
      await tester.pumpWidget(_pantalla(fake));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'Arroz Diana 1kg',
      );
      await tester.tap(find.text('Guardar producto'));
      await tester.pumpAndSettle();

      expect(fake.llamadas, 1);
      expect(find.text('Ya existe un producto con ese nombre'), findsOneWidget);
    });
  });
}
