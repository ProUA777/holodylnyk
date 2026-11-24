/// Де купити річ, якої бракує в образі: посилання на пошук у магазинах країни (за мовою апки).
/// Лише відкриваємо сторінку пошуку — нічого не передаємо, крім назви речі.
library;

class Shop {
  const Shop(this.name, this.emoji, this._url);
  final String name;
  final String emoji;
  final String Function(String q) _url;

  Uri search(String query) => Uri.parse(_url(query));
}

String _enc(String q) => Uri.encodeQueryComponent(q.trim());
String _slug(String q) => Uri.encodeComponent(q.trim().replaceAll(RegExp(r'\s+'), '-'));

const _uk = [
  Shop('Rozetka', '🟢', _rozetka),
  Shop('Prom.ua', '🟣', _prom),
  Shop('OLX', '🔵', _olxUa),
];

const _pl = [
  Shop('Zalando', '🟠', _zalando),
  Shop('Allegro', '🟧', _allegro),
  Shop('Vinted', '🟢', _vinted),
  Shop('OLX', '🔵', _olxPl),
];

String _rozetka(String q) => 'https://rozetka.com.ua/ua/search/?text=${_enc(q)}';
String _prom(String q) => 'https://prom.ua/ua/search?search_term=${_enc(q)}';
String _olxUa(String q) => 'https://www.olx.ua/uk/list/q-${_slug(q)}/';
String _zalando(String q) => 'https://www.zalando.pl/katalog/?q=${_enc(q)}';
String _allegro(String q) => 'https://allegro.pl/listing?string=${_enc(q)}';
String _vinted(String q) => 'https://www.vinted.pl/catalog?search_text=${_enc(q)}';
String _olxPl(String q) => 'https://www.olx.pl/oferty/q-${_slug(q)}/';

List<Shop> shopsFor(String language) => language == 'pl' ? _pl : _uk;
