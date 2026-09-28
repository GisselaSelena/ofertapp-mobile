import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Logger central de la app. Nunca loguees el objeto de excepción crudo
/// (`e.toString()`) si puede contener datos sensibles -- usa e.runtimeType
/// y/o campos públicos conocidos y no sensibles. En particular: nunca
/// tokens, contraseñas ni correos.
final Logger appLogger = Logger('OfertApp');

/// Llamar una sola vez, en main(), antes de runApp(). Solo emite a consola
/// en modo debug -- en release no imprime nada (evita ruido/filtración en
/// builds de producción).
void configurarLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      debugPrint('${record.level.name}: ${record.loggerName}: ${record.message}');
    }
  });
}
