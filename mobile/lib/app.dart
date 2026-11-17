import 'data/catalog.dart';
import 'state/app_state.dart';

/// App-wide singletons, initialised once in main() before runApp.
late final Catalog catalog;
late final AppState app;

class AppConfig {
  /// Backend base URL. Release builds pass it with --dart-define=API_BASE=https://api.example.com
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8000');
  static const appKey = String.fromEnvironment('APP_KEY', defaultValue: 'dev-key-bricks');
  static const profileId = 'brick_builder';
  static const version = '1.1.0';
  static const credits = '© by Greater Koreec Project Group';
}
