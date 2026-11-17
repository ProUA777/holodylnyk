/// Адреса бекенду і ключ передаються при збірці:
/// flutter run --dart-define=API_URL=http://10.0.2.2:8000 --dart-define=API_KEY=secret1
/// (10.0.2.2 — це localhost твого ПК з Android-емулятора)
class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
  static const apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
  static const profileId = 'recipes';
  static const credit = '© by Greater Koreec Project Group';
  static const version = '1.4.0';
  static const logo = 'assets/brand/koreec.png';
}
