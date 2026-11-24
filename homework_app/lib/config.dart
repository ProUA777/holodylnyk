/// Адреса бекенду і ключ передаються при збірці:
/// flutter run --dart-define=API_URL=http://10.0.2.2:8000 --dart-define=API_KEY=secret1
class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
  static const apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
  static const profileId = 'homework';
  static const credit = '© by Greater Koreec Project Group';
  static const version = '1.0.0';
  static const logo = 'assets/brand/koreec.png';
}
