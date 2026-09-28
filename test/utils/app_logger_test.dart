import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:ofertapp_mobile/utils/app_logger.dart';

void main() {
  group('appLogger', () {
    test('tiene el nombre esperado', () {
      expect(appLogger.name, 'OfertApp');
    });

    test('configurarLogging() deja el nivel raíz en INFO y no lanza', () {
      configurarLogging();
      expect(Logger.root.level, Level.INFO);
    });

    test('emite un record real al loguear un warning', () {
      configurarLogging();
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);

      appLogger.warning('mensaje de prueba');

      expect(records, isNotEmpty);
      expect(records.last.message, 'mensaje de prueba');
      expect(records.last.level, Level.WARNING);
      sub.cancel();
    });

    test('un SEVERE intenta reportarse a Sentry sin lanzar (no-op seguro sin Sentry.init)',
        () async {
      configurarLogging();

      // Sentry no está inicializado en este entorno de test (no hay
      // SentryFlutter.init) -- debe ser un no-op seguro (NoOpHub), nunca
      // una excepción, aunque el registro tenga error/stackTrace real.
      expect(
        () => appLogger.severe('fallo grave de prueba', StateError('boom'), StackTrace.current),
        returnsNormally,
      );

      // Deja que corra el microtask del listener (Sentry.captureException
      // es async) antes de terminar el test.
      await Future<void>.delayed(Duration.zero);
    });
  });
}
