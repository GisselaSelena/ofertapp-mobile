import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ofertapp_mobile/services/api_client.dart';

/// Fake http.Client sin red: extiende BaseClient (los métodos del paquete
/// http se implementan en términos de send()), y
/// delega la respuesta a un handler configurable por test.
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;
  http.BaseRequest? ultimaRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    ultimaRequest = request;
    return _handler(request);
  }
}

http.StreamedResponse _respuesta(int status, String body) {
  // content-type explícito porque http.Response.body decodifica según ese
  // header (RFC 3629): sin él, cae a latin1 y rompe acentos/ñ. Un backend
  // FastAPI real siempre manda este header en sus respuestas JSON.
  return http.StreamedResponse(
    Stream.value(utf8.encode(body)),
    status,
    headers: const {'content-type': 'application/json'},
  );
}

void main() {
  group('ApiClient', () {
    test('200 -> decodifica y devuelve el JSON', () async {
      final fake = _FakeHttpClient(
        (req) async => _respuesta(200, '{"id": "abc", "nombre": "Arroz"}'),
      );
      final client = ApiClient(client: fake);

      final data = await client.get('/api/productos/abc');

      expect(data, {'id': 'abc', 'nombre': 'Arroz'});
    });

    test('PUT envía el cuerpo JSON y decodifica la respuesta', () async {
      final fake = _FakeHttpClient(
        (req) async => _respuesta(200, '{"id":"abc","nombre":"Arroz nuevo"}'),
      );
      final client = ApiClient(client: fake);

      final data = await client.put('/api/productos/abc', {
        'nombre': 'Arroz nuevo',
        'categoria': 'granos',
      });

      expect(fake.ultimaRequest!.method, 'PUT');
      expect(
        (fake.ultimaRequest! as http.Request).body,
        contains('Arroz nuevo'),
      );
      expect(data['nombre'], 'Arroz nuevo');
    });

    test('PUT 422 -> conserva los errores asociados a campo', () async {
      final fake = _FakeHttpClient(
        (req) async => _respuesta(
          422,
          '{"detail":[{"loc":["body","nombre"],"msg":"Nombre inválido"}]}',
        ),
      );
      final client = ApiClient(client: fake);

      await expectLater(
        client.put('/api/productos/abc', {'nombre': 'x'}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.fieldErrors['nombre'],
            'error de nombre',
            'Nombre inválido',
          ),
        ),
      );
    });

    test('DELETE acepta parámetros de consulta', () async {
      final fake = _FakeHttpClient((req) async => _respuesta(204, ''));
      final client = ApiClient(client: fake);

      await client.delete(
        '/api/productos/abc',
        queryParameters: const {'forzar': 'true'},
      );

      expect(fake.ultimaRequest!.url.queryParameters, {'forzar': 'true'});
    });

    test(
      '409 -> conserva el nombre y conteos estructurados del backend',
      () async {
        final fake = _FakeHttpClient(
          (req) async => _respuesta(
            409,
            '{"detail":{"mensaje":"Tiene datos asociados","nombre":"Arroz",'
            '"precios":2,"favoritos":3,"promociones":1}}',
          ),
        );
        final client = ApiClient(client: fake);

        try {
          await client.delete('/api/productos/abc');
          fail('debería haber lanzado ConflictException');
        } on ConflictException catch (e) {
          expect(e.message, 'Tiene datos asociados');
          expect(e.nombre, 'Arroz');
          expect(e.precios, 2);
          expect(e.favoritos, 3);
          expect(e.promociones, 1);
        }
      },
    );

    test('200 con cuerpo vacío -> devuelve null (ej. DELETE 204)', () async {
      final fake = _FakeHttpClient((req) async => _respuesta(204, ''));
      final client = ApiClient(client: fake);

      final data = await client.delete('/api/favoritos/x');

      expect(data, isNull);
    });

    test(
      'setToken agrega el header Authorization a la siguiente request',
      () async {
        final fake = _FakeHttpClient((req) async => _respuesta(200, '{}'));
        final client = ApiClient(client: fake)..setToken('mi-jwt');

        await client.get('/api/productos');

        expect(fake.ultimaRequest!.headers['Authorization'], 'Bearer mi-jwt');
      },
    );

    test('401 -> lanza AuthException', () async {
      final fake = _FakeHttpClient(
        (req) async => _respuesta(401, '{"detail":"no autorizado"}'),
      );
      final client = ApiClient(client: fake);

      expect(() => client.get('/api/productos'), throwsA(isA<AuthException>()));
    });

    test(
      '422 -> lanza ValidationException con los errores mapeados por campo',
      () async {
        final cuerpo422 = jsonEncode({
          'detail': [
            {
              'loc': ['body', 'nombre'],
              'msg': 'El nombre es obligatorio',
            },
            {
              'loc': ['body', 'valor'],
              'msg': 'Ingresa un número válido',
            },
          ],
        });
        final fake = _FakeHttpClient((req) async => _respuesta(422, cuerpo422));
        final client = ApiClient(client: fake);

        try {
          await client.post('/api/productos', {'nombre': ''});
          fail('debería haber lanzado ValidationException');
        } on ValidationException catch (e) {
          expect(e.fieldErrors['nombre'], 'El nombre es obligatorio');
          expect(e.fieldErrors['valor'], 'Ingresa un número válido');
        }
      },
    );

    test('timeout agotado -> lanza ApiException, sin esperar a que "responda" el servidor', () async {
      // El handler nunca completa (Completer sin resolver, no un Timer):
      // así no queda ningún Timer pendiente después del test.
      final fake = _FakeHttpClient(
        (req) => Completer<http.StreamedResponse>().future,
      );
      final client = ApiClient(
        client: fake,
        timeout: const Duration(milliseconds: 30),
      );

      await expectLater(
        client.get('/api/productos'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Tiempo de espera agotado. Verifica tu conexión.',
          ),
        ),
      );
    });
  });
}
