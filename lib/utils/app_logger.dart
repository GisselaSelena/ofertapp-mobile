import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Logger central de la app. Nunca loguees el objeto de excepción crudo
/// (`e.toString()`) si puede contener datos sensibles -- usa e.runtimeType
/// y/o campos públicos conocidos y no sensibles. En particular: nunca
/// tokens, contraseñas ni correos.
final Logger appLogger = Logger('OfertApp');

/// Llamar una sola vez, en main(), antes de runApp(). Solo emite a consola
/// en modo debug -- en release no imprime nada (evita ruido/filtración en
/// builds de producción). Los registros SEVERE (o más graves) además se
/// reportan a Sentry -- si Sentry todavía no fue inicializado (ej. en
/// tests) esta llamada es un no-op seguro, no lanza.
void configurarLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      debugPrint('${record.level.name}: ${record.loggerName}: ${record.message}');
    }
    if (record.level >= Level.SEVERE) {
      unawaited(Sentry.captureException(
        record.error ?? record.message,
        stackTrace: record.stackTrace,
      ));
    }
  });
}
