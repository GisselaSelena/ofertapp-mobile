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
  });
}
