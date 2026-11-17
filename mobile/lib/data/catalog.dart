import 'dart:convert';

import 'package:flutter/services.dart';

/// One standard part placed on the stud grid.
/// x, y — position in studs; z — height in brick units (plate = 0.4);
/// w, d — size in studs; c — colour code ("R") or hex ("#C91A09"); h — 1 or 0.4.
class Brick {
  final int x, y, w, d;
  final double z, h;
  final String c;

  const Brick(this.x, this.y, this.z, this.w, this.d, this.c, this.h);

  bool get isPlate => h < 1;

  /// Parses `[x, y, z, w, d, colour, h]`; returns null for anything malformed.
  static Brick? tryParse(dynamic v) {
    if (v is! List || v.length < 6) return null;
    num? n(int i) => v[i] is num ? v[i] as num : null;
    final x = n(0), y = n(1), z = n(2), w = n(3), d = n(4);
    if (x == null || y == null || z == null || w == null || d == null) return null;
    if ([x, y, z, w, d].any((e) => !e.isFinite || e.abs() > 24)) return null;
    if (w < 1 || d < 1 || w > 10 || d > 10) return null;
    final h = (v.length > 6 && v[6] is num && (v[6] as num) < 1) ? 0.4 : 1.0;
    return Brick(x.round(), y.round(), z.toDouble(), w.round(), d.round(), v[5].toString(), h);
  }
}

class BuildStep {
  final String label;
  final String? text; // AI steps carry their own sentence
  final List<Brick> bricks;
  const BuildStep({required this.label, this.text, required this.bricks});
}

typedef L10n = Map<String, String>;

String pick(L10n m, String lang) => m[lang] ?? m['en'] ?? (m.values.isEmpty ? '' : m.values.first);

L10n _l10n(dynamic v) => (v as Map).map((k, e) => MapEntry(k as String, e.toString()));

class BrickModel {
  final String id, cat, emoji, diff;
  final int minutes, parts;
  final L10n title, desc;
  final List<BuildStep> steps;

  const BrickModel({
    required this.id,
    required this.cat,
    required this.emoji,
    required this.diff,
    required this.minutes,
    required this.parts,
    required this.title,
    required this.desc,
    required this.steps,
  });

  factory BrickModel.fromJson(Map<String, dynamic> j) => BrickModel(
        id: j['id'] as String,
        cat: j['cat'] as String,
        emoji: j['emoji'] as String,
        diff: j['diff'] as String,
        minutes: (j['min'] as num).toInt(),
        parts: (j['n'] as num).toInt(),
        title: _l10n(j['t']),
        desc: _l10n(j['d']),
        steps: [
          for (final s in j['s'] as List)
            BuildStep(
              label: (s as Map)['l'] as String,
              bricks: [for (final b in s['b'] as List) Brick.tryParse(b)].whereType<Brick>().toList(),
            ),
        ],
      );

  int get stars => difficultyStars(diff);
}

int difficultyStars(String diff) => switch (diff) { 'easy' => 1, 'hard' => 3, 'expert' => 4, _ => 2 };

class Pile {
  final String id;
  final L10n name;
  final int total;
  final List<(String, int)> colors;
  final Map<String, List<String>> notable;
  final List<String> ideas;

  const Pile({required this.id, required this.name, required this.total, required this.colors, required this.notable, required this.ideas});

  factory Pile.fromJson(Map<String, dynamic> j) => Pile(
        id: j['id'] as String,
        name: _l10n(j['n']),
        total: (j['total'] as num).toInt(),
        colors: [for (final c in j['colors'] as List) ((c as List)[0] as String, (c[1] as num).toInt())],
        notable: (j['notable'] as Map).map((k, v) => MapEntry(k as String, [for (final e in v as List) e.toString()])),
        ideas: [for (final e in j['ideas'] as List) e as String],
      );
}

class Catalog {
  final Map<String, Color> colors;
  final Map<String, L10n> colorNames, categories, stepLabels;
  final List<BrickModel> models;
  final Map<String, BrickModel> byId;
  final List<Pile> piles;

  Catalog._(this.colors, this.colorNames, this.categories, this.stepLabels, this.models, this.piles)
      : byId = {for (final m in models) m.id: m};

  static Future<Catalog> load() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/catalog.json')) as Map<String, dynamic>;
    return Catalog.fromJson(raw);
  }

  factory Catalog.fromJson(Map<String, dynamic> j) => Catalog._(
        (j['colors'] as Map).map((k, v) => MapEntry(k as String, parseHex(v as String))),
        (j['colorNames'] as Map).map((k, v) => MapEntry(k as String, _l10n(v))),
        (j['categories'] as Map).map((k, v) => MapEntry(k as String, _l10n(v))),
        (j['steps'] as Map).map((k, v) => MapEntry(k as String, _l10n(v))),
        [for (final m in j['models'] as List) BrickModel.fromJson(m as Map<String, dynamic>)],
        [for (final p in j['piles'] as List) Pile.fromJson(p as Map<String, dynamic>)],
      );

  /// Colour code ("R") or hex ("#C91A09") → Color.
  Color colorOf(String c) => colors[c] ?? parseHex(c);

  String colorName(String c, String lang, {bool plate = false}) {
    final m = colorNames[c];
    if (m == null) return '';
    var n = pick(m, lang);
    // Polish adjectives agree with "płytka" (feminine) for plates.
    if (lang == 'pl' && plate) n = n.replaceAll(RegExp(r'[yi]$'), 'a');
    return n;
  }
}

Color parseHex(String? hex, [Color fallback = const Color(0xFFA3A8AD)]) {
  final h = (hex ?? '').replaceAll('#', '');
  if (h.length != 6) return fallback;
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}
