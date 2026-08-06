/// Environment configuration, single source of truth for all
/// build-time / runtime settings.
///
/// Values come from `--dart-define` flags at build time and fall back
/// to the production defaults so a plain `flutter run` always works:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://staging.example.com
/// ```
class EnvConfig {
  EnvConfig._();

  static const String _defaultBaseUrl =
      'https://darak-invest-backend-j6hy.onrender.com';

  /// Backend base URL. Override with `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  /// Request timeout for all HTTP calls.
  static const Duration apiTimeout = Duration(seconds: 45);

  /// Whether to prepend the bundled demo property to the catalogue.
  ///
  /// Disabled in production by default; keep `true` for local demos.
  static const bool showDemoProperty = bool.fromEnvironment(
    'SHOW_DEMO_PROPERTY',
    defaultValue: false,
  );

  static bool get isProduction => apiBaseUrl == _defaultBaseUrl;
}
