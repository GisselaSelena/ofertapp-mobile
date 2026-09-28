import 'package:sentry_flutter/sentry_flutter.dart';

/// Claves de mapa (headers, extra, tags, data de breadcrumbs) que nunca
/// deben viajar en texto plano a Sentry. Comparación case-insensitive,
/// por substring (cubre variantes como "auth_token", "user_password", etc).
const _clavesSensibles = [
  'password',
  'contraseña',
  'contrasena',
  'token',
  'authorization',
  'email',
  'correo',
];

/// Forma aproximada de un JWT: tres segmentos base64url separados por
/// puntos. Se busca dentro del string (no se ancla con ^$) porque un JWT
/// puede venir embebido en un valor más largo, ej. "Bearer eyJ...".
final RegExp _patronJwt =
    RegExp(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}');

const _marcadorRedactado = '[REDACTADO]';
const _marcadorJwtRedactado = '[JWT_REDACTADO]';

bool esClaveSensible(String clave) {
  final k = clave.toLowerCase();
  return _clavesSensibles.any(k.contains);
}

String redactarJwt(String valor) =>
    valor.replaceAll(_patronJwt, _marcadorJwtRedactado);

/// Limpia un mapa de headers/tags (valores String): redacta el valor
/// completo si la clave es sensible, y redacta cualquier JWT embebido en
/// el resto de los valores.
Map<String, String> limpiarMapaDeStrings(Map<String, String> original) {
  final limpio = <String, String>{};
  original.forEach((clave, valor) {
    limpio[clave] = esClaveSensible(clave) ? _marcadorRedactado : redactarJwt(valor);
  });
  return limpio;
}

/// Igual que [limpiarMapaDeStrings] pero para mapas dynamic (extra, data
/// de breadcrumbs): solo redacta JWT dentro de valores que sean String,
/// deja pasar otros tipos (números, bools) sin tocar salvo que la clave
/// sea sensible.
Map<String, dynamic> limpiarMapaDinamico(Map<String, dynamic> original) {
  final limpio = <String, dynamic>{};
  original.forEach((clave, valor) {
    if (esClaveSensible(clave)) {
      limpio[clave] = _marcadorRedactado;
    } else if (valor is String) {
      limpio[clave] = redactarJwt(valor);
    } else {
      limpio[clave] = valor;
    }
  });
  return limpio;
}

/// beforeSend de Sentry (SentryFlutterOptions.beforeSend). Se aplica a
/// TODO evento antes de salir del dispositivo:
/// - el header Authorization (y cualquier otro header sensible) se
///   redacta por completo.
/// - el correo del usuario nunca viaja (el id sí, ver sentry_setup.dart
///   al llamar Sentry.configureScope).
/// - cualquier JWT que aparezca embebido en extra/tags/breadcrumbs se
///   redacta, sin importar bajo qué clave venga.
///
/// Es una función pura (aparte del tipo SentryEvent, que sí es mutable
/// por diseño del SDK) para poder probarla sin inicializar Sentry.
SentryEvent? scrubSentryEvent(SentryEvent event, Hint hint) {
  final request = event.request;
  if (request != null) {
    request.headers = limpiarMapaDeStrings(request.headers);
  }

  final user = event.user;
  if (user?.email != null) {
    user!.email = null;
  }

  final tags = event.tags;
  if (tags != null) {
    event.tags = limpiarMapaDeStrings(tags);
  }

  final breadcrumbs = event.breadcrumbs;
  if (breadcrumbs != null) {
    for (final breadcrumb in breadcrumbs) {
      final data = breadcrumb.data;
      if (data != null) {
        breadcrumb.data = limpiarMapaDinamico(data);
      }
      final mensaje = breadcrumb.message;
      if (mensaje != null) {
        breadcrumb.message = redactarJwt(mensaje);
      }
    }
  }

  return event;
}
