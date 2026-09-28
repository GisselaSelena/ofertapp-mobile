import 'package:flutter_test/flutter_test.dart';
import 'package:ofertapp_mobile/utils/formatters.dart';

void main() {
  group('formatearPrecio', () {
    test('agrega dos decimales cuando faltan', () {
      expect(formatearPrecio(1.5), r'$1.50');
    });

    test('trunca/redondea a dos decimales cuando hay más', () {
      expect(formatearPrecio(1.999), r'$2.00');
    });

    test('formatea un entero', () {
      expect(formatearPrecio(5), r'$5.00');
    });

    test('formatea cero', () {
      expect(formatearPrecio(0), r'$0.00');
    });

    test('mantiene dos decimales exactos', () {
      expect(formatearPrecio(19.99), r'$19.99');
    });
  });
}
