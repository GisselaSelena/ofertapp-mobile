import 'package:sentry_flutter/sentry_flutter.dart';
import '../config.dart';
import 'sentry_scrubber.dart';

/// Inicializa Sentry y corre la app dentro de la zona que sentry_flutter
/// crea para capturar errores no atrapados (usa runZonedGuarded o
/// PlatformDispatcher.onError según la plataforma; ver SentryFlutter.init).
/// [appRunner] normalmente será `() => runApp(const MyApp())`.
Future<void> initSentryAndRun(AppRunner appRunner) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = Config.sentryDsn;
      options.beforeSend = scrubSentryEvent;
      // Cuota del plan gratuito: NO se activa tracing al 100%. 0.2 alcanza
      // para ver ejemplos de rendimiento sin agotar la cuota.
      options.tracesSampleRate = 0.2;
    },
    appRunner: appRunner,
  );
}

/// Identifica al usuario en Sentry usando SOLO su id interno (uuid) --
/// nunca el correo. Llamar tras un login/registro exitoso.
Future<void> identificarUsuarioEnSentry(String userId) async {
  await Sentry.configureScope((scope) {
    scope.setUser(SentryUser(id: userId));
  });
}

/// Llamar al cerrar sesión: saca al usuario del scope de Sentry para que
/// eventos posteriores (ej. en la pantalla de login) no queden asociados
/// a quien acaba de salir.
Future<void> olvidarUsuarioEnSentry() async {
  await Sentry.configureScope((scope) => scope.setUser(null));
}
