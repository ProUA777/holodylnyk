/// Де купити засіб, ґрунт чи горщик: посилання на пошук у магазинах країни (за мовою апки).
/// Лише відкриваємо сторінку пошуку — нічого не передаємо, крім назви товару.
library;

class Shop {
  const Shop(this.name, this.emoji, this._url);
  final String name;
  final String emoji;
  final String Function(String q) _url;

  Uri search(String query) => Uri.parse(_url(query));
}

String _enc(String q) => Uri.encodeQueryComponent(q.trim());

const _uk = [
  Shop('Епіцентр', '🟠', _epicentr),
  Shop('Rozetka', '🟢', _rozetka),
  Shop('Prom.ua', '🟣', _prom),
];

const _pl = [
  Shop('Allegro', '🟠', _allegro),
  Shop('Castorama', '🔷', _castorama),
  Shop('Leroy Merlin', '🟢', _leroy),
];

String _epicentr(String q) => 'https://epicentrk.ua/ua/search/?q=${_enc(q)}';
String _rozetka(String q) => 'https://rozetka.com.ua/ua/search/?text=${_enc(q)}';
String _prom(String q) => 'https://prom.ua/ua/search?search_term=${_enc(q)}';
String _allegro(String q) => 'https://allegro.pl/listing?string=${_enc(q)}';
String _castorama(String q) => 'https://www.castorama.pl/search?term=${_enc(q)}';
String _leroy(String q) => 'https://www.leroymerlin.pl/szukaj.html?q=${_enc(q)}';

List<Shop> shopsFor(String language) => language == 'pl' ? _pl : _uk;
