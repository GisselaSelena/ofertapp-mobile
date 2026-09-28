class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.18.168:8000',
  );

  /// El DSN de Sentry no es secreto (viaja en el cliente por diseño: solo
  /// permite ENVIAR eventos, no leerlos). Igual se deja configurable por
  /// variable de entorno en vez de repetido en cada sitio que lo necesite.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://9b8a7d4326bac65e5dcaf84c641bc0b4@o4512165788057600.ingest.us.sentry.io/4512165799002112',
  );
}
