/// Моделі відповіді PhotoAI Engine для профілю «outfits».
library;

import 'package:flutter/painting.dart';

enum Occasion { any, casual, work, date, party, sport, formal, travel }

enum Weather { any, hot, warm, cool, cold, rain }

enum StyleFor { any, women, men }

/// Тип речі — порядок для групування в гардеробі
enum Kind { top, bottom, dress, outer, shoes, accessory, bag }

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

List<String> _strings(Object? v) => ((v as List?) ?? const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();

Color? colorFromHex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

class OutfitParams {
  const OutfitParams({
    this.language = 'uk',
    this.occasion = Occasion.any,
    this.weather = Weather.any,
    this.styleFor = StyleFor.any,
    this.outfitCount = 4,
  });

  final String language;
  final Occasion occasion;
  final Weather weather;
  final StyleFor styleFor;
  final int outfitCount;

  OutfitParams copyWith({String? language, Occasion? occasion, Weather? weather, StyleFor? styleFor}) => OutfitParams(
        language: language ?? this.language,
        occasion: occasion ?? this.occasion,
        weather: weather ?? this.weather,
        styleFor: styleFor ?? this.styleFor,
        outfitCount: outfitCount,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'occasion': occasion.name,
        'weather': weather.name,
        'style_for': styleFor.name,
        'outfit_count': outfitCount,
      };

  factory OutfitParams.fromJson(Map<String, dynamic> j) => OutfitParams(
        language: j['language'] as String? ?? 'uk',
        occasion: _enum(Occasion.values, j['occasion'], Occasion.any),
        weather: _enum(Weather.values, j['weather'], Weather.any),
        styleFor: _enum(StyleFor.values, j['style_for'], StyleFor.any),
      );
}

class Item {
  const Item({required this.name, this.kind = Kind.top, this.color = '', this.hex});

  final String name;
  final Kind kind;
  final String color;
  final String? hex;

  Color? get swatch => colorFromHex(hex);

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        name: (j['name'] as String? ?? '').trim(),
        kind: _enum(Kind.values, j['kind'], Kind.top),
        color: j['color'] as String? ?? '',
        hex: j['hex'] as String?,
      );

  Map<String, dynamic> toJson() => {'name': name, 'kind': kind.name, 'color': color, 'hex': hex};

  String get emoji => switch (kind) {
        Kind.top => '👕',
        Kind.bottom => '👖',
        Kind.dress => '👗',
        Kind.outer => '🧥',
        Kind.shoes => '👟',
        Kind.accessory => '🧣',
        Kind.bag => '👜',
      };
}

class Outfit {
  const Outfit({
    required this.title,
    this.occasion = Occasion.casual,
    this.items = const [],
    this.add = const [],
    this.why = '',
    this.tips = const [],
  });

  final String title;
  final Occasion occasion;
  final List<String> items;
  final List<String> add; // чого бракує — докупити або взяти своє
  final String why;
  final List<String> tips;

  /// Однаковий образ — та сама назва й ті самі речі
  String get key => '${title.toLowerCase()}|${(List.of(items)..sort()).join(',').toLowerCase()}';

  factory Outfit.fromJson(Map<String, dynamic> j) => Outfit(
        title: j['title'] as String? ?? '',
        occasion: _enum(Occasion.values, j['occasion'], Occasion.casual),
        items: _strings(j['items']),
        add: _strings(j['add']),
        why: j['why'] as String? ?? '',
        tips: _strings(j['tips']),
      );

  Map<String, dynamic> toJson() =>
      {'title': title, 'occasion': occasion.name, 'items': items, 'add': add, 'why': why, 'tips': tips};
}

class Verdict {
  const Verdict({required this.score, this.good = const [], this.change = const []});
  final int score;
  final List<String> good;
  final List<String> change;

  factory Verdict.fromJson(Map<String, dynamic> j) => Verdict(
        score: ((j['score'] as num?)?.toInt() ?? 5).clamp(1, 10),
        good: _strings(j['good']),
        change: _strings(j['change']),
      );
}

class OutfitResult {
  const OutfitResult({
    this.worn = false,
    this.items = const [],
    this.palette = const [],
    this.outfits = const [],
    this.verdict,
    this.shopping = const [],
  });

  final bool worn; // на фото людина в образі
  final List<Item> items;
  final List<Color> palette;
  final List<Outfit> outfits;
  final Verdict? verdict;
  final List<String> shopping;

  factory OutfitResult.fromJson(Map<String, dynamic> j) => OutfitResult(
        worn: j['photo_kind'] == 'worn',
        items: ((j['items'] as List?) ?? const [])
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .where((i) => i.name.isNotEmpty)
            .toList(),
        palette: _strings(j['palette']).map(colorFromHex).whereType<Color>().toList(),
        outfits: ((j['outfits'] as List?) ?? const [])
            .map((e) => Outfit.fromJson(e as Map<String, dynamic>))
            .where((o) => o.title.isNotEmpty && o.items.isNotEmpty)
            .toList(),
        verdict: j['verdict'] is Map<String, dynamic> ? Verdict.fromJson(j['verdict'] as Map<String, dynamic>) : null,
        shopping: _strings(j['shopping']),
      );
}

class StyleAnswer {
  const StyleAnswer({required this.answer, this.tips = const []});
  final String answer;
  final List<String> tips;

  factory StyleAnswer.fromJson(Map<String, dynamic> j) =>
      StyleAnswer(answer: j['answer'] as String? ?? '', tips: _strings(j['tips']));
}
