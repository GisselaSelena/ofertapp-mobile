import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:ofertapp_mobile/utils/sentry_scrubber.dart';

const _jwtDeEjemplo =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImFiYyJ9.k3JJ9kL2rV7q8x0YmZ3p';

void main() {
  group('esClaveSensible', () {
    test('reconoce authorization, token, password, email y variantes en español', () {
      expect(esClaveSensible('Authorization'), isTrue);
      expect(esClaveSensible('authorization'), isTrue);
      expect(esClaveSensible('X-Auth-Token'), isTrue);
      expect(esClaveSensible('password'), isTrue);
      expect(esClaveSensible('user_password'), isTrue);
      expect(esClaveSensible('contraseña'), isTrue);
      expect(esClaveSensible('email'), isTrue);
      expect(esClaveSensible('correo_usuario'), isTrue);
    });

    test('no marca claves normales como sensibles', () {
      expect(esClaveSensible('Content-Type'), isFalse);
      expect(esClaveSensible('producto_id'), isFalse);
      expect(esClaveSensible('valor'), isFalse);
    });
  });

  group('redactarJwt', () {
    test('redacta un JWT embebido en un string más largo', () {
      final resultado = redactarJwt('Bearer $_jwtDeEjemplo');
      expect(resultado, 'Bearer [JWT_REDACTADO]');
      expect(resultado.contains('eyJ'), isFalse);
    });

    test('no toca un string sin forma de JWT', () {
      expect(redactarJwt('Arroz Diana 1kg'), 'Arroz Diana 1kg');
    });
  });

  group('limpiarMapaDeStrings', () {
    test('redacta el header Authorization completo', () {
      final limpio = limpiarMapaDeStrings({
        'Authorization': 'Bearer $_jwtDeEjemplo',
        'Content-Type': 'application/json',
      });
      expect(limpio['Authorization'], '[REDACTADO]');
      expect(limpio['Content-Type'], 'application/json');
    });
  });

  group('limpiarMapaDinamico', () {
    test('redacta claves sensibles y deja pasar valores no sensibles', () {
      final limpio = limpiarMapaDinamico({
        'password': 'clave12345',
        'producto_id': 'abc',
        'cantidad': 3,
        'activo': true,
      });
      expect(limpio['password'], '[REDACTADO]');
      expect(limpio['producto_id'], 'abc');
      expect(limpio['cantidad'], 3);
      expect(limpio['activo'], true);
    });

    test('redacta un JWT embebido aunque la clave no sea "sensible" por nombre', () {
      final limpio = limpiarMapaDinamico({'detalle': 'token=$_jwtDeEjemplo'});
      expect(limpio['detalle'], 'token=[JWT_REDACTADO]');
    });
  });

  group('scrubSentryEvent', () {
    test('limpia headers, email y tags/breadcrumbs sensibles sin descartar el evento', () {
      final event = SentryEvent(
        user: SentryUser(id: 'uuid-real-del-usuario', email: 'persona@correo.com'),
        request: SentryRequest(
          url: 'https://api.ofertapp.test/api/productos',
          headers: {
            'Authorization': 'Bearer $_jwtDeEjemplo',
            'Content-Type': 'application/json',
          },
        ),
        tags: {'contraseña_temporal': 'abc123', 'pantalla': 'login'},
        breadcrumbs: [
          Breadcrumb(
            category: 'http',
            data: {'token': _jwtDeEjemplo, 'status_code': 401},
          ),
        ],
      );

      final resultado = scrubSentryEvent(event, Hint());

      expect(resultado, isNotNull, reason: 'nunca debe descartar el evento completo');

      // Authorization redactado, el resto del header intacto.
      expect(resultado!.request!.headers['Authorization'], '[REDACTADO]');
      expect(resultado.request!.headers['Content-Type'], 'application/json');

      // El correo nunca viaja; el id interno SÍ se conserva (es lo que se
      // debe usar para identificar al usuario, según la guía).
      expect(resultado.user!.email, isNull);
      expect(resultado.user!.id, 'uuid-real-del-usuario');

      // Tags: la clave sensible se redacta, la que no, se conserva.
      expect(resultado.tags!['contraseña_temporal'], '[REDACTADO]');
      expect(resultado.tags!['pantalla'], 'login');

      // Breadcrumb: el JWT se redacta, el status_code (no sensible) queda.
      final data = resultado.breadcrumbs!.single.data!;
      expect(data['token'], '[REDACTADO]'); // clave "token" es sensible por nombre
      expect(data['status_code'], 401);
    });

    test('no falla si el evento no tiene request/user/tags/breadcrumbs', () {
      final event = SentryEvent();
      expect(scrubSentryEvent(event, Hint()), isNotNull);
    });
  });
}
