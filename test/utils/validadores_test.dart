import 'package:flutter_test/flutter_test.dart';
import 'package:ofertapp_mobile/utils/validadores.dart';

void main() {
  group('validarEmail', () {
    test('rechaza null', () {
      expect(validarEmail(null), 'El correo es obligatorio');
    });

    test('rechaza vacío', () {
      expect(validarEmail(''), 'El correo es obligatorio');
    });

    test('rechaza solo espacios', () {
      expect(validarEmail('   '), 'El correo es obligatorio');
    });

    test('rechaza sin arroba', () {
      expect(validarEmail('sin-arroba.com'), 'Ingresa un correo válido');
    });

    test('acepta un correo válido', () {
      expect(validarEmail('user@example.com'), isNull);
    });
  });

  group('validarPassword', () {
    test('rechaza null', () {
      expect(validarPassword(null), 'La contraseña es obligatoria');
    });

    test('rechaza vacía', () {
      expect(validarPassword(''), 'La contraseña es obligatoria');
    });

    test('rechaza menor a 6 caracteres', () {
      expect(validarPassword('abc12'), 'Debe tener al menos 6 caracteres');
    });

    test('acepta exactamente 6 caracteres', () {
      expect(validarPassword('abc123'), isNull);
    });

    test('acepta más de 6 caracteres', () {
      expect(validarPassword('clave-larga-123'), isNull);
    });
  });

  group('validarNombre', () {
    test('rechaza null', () {
      expect(validarNombre(null), 'El nombre es obligatorio');
    });

    test('rechaza vacío o solo espacios', () {
      expect(validarNombre('   '), 'El nombre es obligatorio');
    });

    test('acepta cualquier nombre no vacío', () {
      expect(validarNombre('A'), isNull);
    });
  });

  group('validarNombreProducto', () {
    test('rechaza vacío', () {
      expect(validarNombreProducto(''), 'El nombre es obligatorio');
    });

    test('rechaza menor a 3 caracteres (tras trim)', () {
      expect(validarNombreProducto(' ab '), 'Debe tener al menos 3 caracteres');
    });

    test('acepta exactamente 3 caracteres', () {
      expect(validarNombreProducto('Sal'), isNull);
    });

    test('acepta un nombre largo', () {
      expect(validarNombreProducto('Arroz Diana 1kg'), isNull);
    });
  });
}
