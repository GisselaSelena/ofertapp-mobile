import 'package:flutter_test/flutter_test.dart';
import 'package:ofertapp_mobile/services/api_client.dart';

void main() {
  group('mensajeDeError', () {
    test('AuthException -> mensaje de sesión expirada', () {
      expect(
        mensajeDeError(AuthException('Sesión expirada o no autenticado')),
        'Tu sesión expiró. Inicia sesión de nuevo.',
      );
    });

    test('ForbiddenException -> usa el mensaje real de la excepción', () {
      expect(
        mensajeDeError(ForbiddenException('Esta acción requiere rol de administrador')),
        'Esta acción requiere rol de administrador',
      );
    });

    test('ValidationException -> mensaje genérico de validación', () {
      expect(
        mensajeDeError(ValidationException({'nombre': 'Campo inválido'})),
        'Revisa los datos ingresados.',
      );
    });

    test('ApiException -> usa el mensaje real de la excepción', () {
      expect(
        mensajeDeError(ApiException('Error inesperado (código 409)')),
        'Error inesperado (código 409)',
      );
    });

    test('cualquier otra excepción (ej. de red) -> mensaje de sin conexión', () {
      expect(
        mensajeDeError(Exception('SocketException: fallo de red')),
        'Sin conexión a internet. Intenta de nuevo.',
      );
    });

    test('un Object cualquiera, no una Exception -> también cae a sin conexión', () {
      expect(mensajeDeError('cualquier cosa'), 'Sin conexión a internet. Intenta de nuevo.');
    });
  });
}
