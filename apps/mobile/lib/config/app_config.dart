class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'TRIKAAL_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
