/// Де купити деталь: посилання на пошук у магазинах країни (за мовою апки).
/// Лише відкриваємо сторінку пошуку — нічого не купуємо і не передаємо, крім назви деталі.
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
  Shop('Епіцентр', '🟠', _epicentr),
  Shop('Prom.ua', '🟣', _prom),
  Shop('OLX', '🔵', _olxUa),
];

const _pl = [
  Shop('Allegro', '🟠', _allegro),
  Shop('OLX', '🔵', _olxPl),
  Shop('Castorama', '🔷', _castorama),
  Shop('Ceneo', '🟢', _ceneo),
];

String _rozetka(String q) => 'https://rozetka.com.ua/ua/search/?text=${_enc(q)}';
String _epicentr(String q) => 'https://epicentrk.ua/ua/search/?q=${_enc(q)}';
String _prom(String q) => 'https://prom.ua/ua/search?search_term=${_enc(q)}';
String _olxUa(String q) => 'https://www.olx.ua/uk/list/q-${_slug(q)}/';
String _allegro(String q) => 'https://allegro.pl/listing?string=${_enc(q)}';
String _olxPl(String q) => 'https://www.olx.pl/oferty/q-${_slug(q)}/';
String _castorama(String q) => 'https://www.castorama.pl/search?term=${_enc(q)}';
String _ceneo(String q) => 'https://www.ceneo.pl/;szukaj-${_slug(q)}';

List<Shop> shopsFor(String language) => language == 'pl' ? _pl : _uk;

/// Запит для пошуку: деталь + модель речі (для запчастин модель важлива, для інструментів — ні)
String shopQuery(String part, {String? brandModel, bool isTool = false}) =>
    [part, if (!isTool && brandModel != null && brandModel.trim().isNotEmpty) brandModel.trim()].join(' ');
