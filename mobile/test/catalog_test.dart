import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_build/data/api.dart';
import 'package:what_to_build/data/catalog.dart';

void main() {
  late Catalog cat;

  setUpAll(() {
    final raw = jsonDecode(File('assets/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    cat = Catalog.fromJson(raw);
  });

  test('catalog has 100+ models in 11 categories', () {
    expect(cat.models.length, greaterThanOrEqualTo(100));
    expect(cat.categories.length, 11);
    expect(cat.models.where((m) => m.diff == 'expert').length, greaterThanOrEqualTo(15));
    expect(cat.byId.length, cat.models.length, reason: 'ids must be unique');
  });

  test('every model is complete and translated', () {
    for (final m in cat.models) {
      expect(m.steps, isNotEmpty, reason: m.id);
      expect(cat.categories.containsKey(m.cat), isTrue, reason: m.id);
      for (final l in const ['uk', 'pl', 'en']) {
        expect(m.title[l], isNotEmpty, reason: '${m.id} title $l');
        expect(m.desc[l], isNotEmpty, reason: '${m.id} desc $l');
      }
      var parts = 0;
      for (final s in m.steps) {
        expect(s.bricks, isNotEmpty, reason: '${m.id}/${s.label}');
        expect(cat.stepLabels.containsKey(s.label), isTrue, reason: '${m.id}/${s.label}');
        for (final b in s.bricks) {
          expect(cat.colors.containsKey(b.c), isTrue, reason: '${m.id} colour ${b.c}');
        }
        parts += s.bricks.length;
      }
      expect(m.parts, parts, reason: m.id);
    }
  });

  test('example piles point at existing models', () {
    expect(cat.piles.length, greaterThanOrEqualTo(3));
    for (final p in cat.piles) {
      for (final id in p.ideas) {
        expect(cat.byId.containsKey(id), isTrue, reason: '${p.id} → $id');
      }
      for (final (c, _) in p.colors) {
        expect(cat.colors.containsKey(c), isTrue, reason: '${p.id} colour $c');
      }
    }
  });

  test('Polish colour names agree with "płytka"', () {
    expect(cat.colorName('R', 'pl'), 'czerwony');
    expect(cat.colorName('R', 'pl', plate: true), 'czerwona');
    expect(cat.colorName('B', 'pl', plate: true), 'niebieska');
  });

  test('Brick.tryParse rejects junk and keeps plates', () {
    expect(Brick.tryParse('x'), isNull);
    expect(Brick.tryParse([0, 0, 0, 0, 1, 'R']), isNull);
    expect(Brick.tryParse([0, 0, 0, 1, 1, 'R', 1, 99]), isNotNull);
    expect(Brick.tryParse([0, 0, 100, 1, 1, 'R']), isNull);
    final plate = Brick.tryParse([1, 2, 0.4, 2, 4, '#FF0000', 0.4])!;
    expect(plate.isPlate, isTrue);
    expect(plate.w, 2);
  });

  test('AI answers with text steps and 3D steps both parse', () {
    final r = ScanResult.fromJson({
      'readable': true,
      'pieces': {
        'total_estimate': 40,
        'colors': [
          {'name': 'red', 'hex': '#D7261E', 'count': 20},
          'blue',
        ],
        'notable': ['wheels'],
      },
      'ideas': [
        {'title': 'Car', 'emoji': '🚗', 'difficulty': 'easy', 'minutes': 5, 'steps': ['Lay the base', 'Add wheels']},
        {
          'title': 'Tower',
          'difficulty': 'impossible',
          'steps': [
            {'text': 'Base', 'bricks': [[0, 0, 0, 2, 2, '#FFFFFF', 1], 'junk']},
          ],
        },
      ],
    }, 7);
    expect(r.readable, isTrue);
    expect(r.total, 40);
    expect(r.colors.length, 2);
    expect(r.remaining, 7);
    expect(r.ideas.length, 2);
    expect(r.ideas[0].has3d, isFalse);
    expect(r.ideas[0].steps.length, 2);
    expect(r.ideas[1].has3d, isTrue);
    expect(r.ideas[1].diff, 'medium');
    expect(r.ideas[1].steps.first.bricks.length, 1);
  });

  test('unreadable photo keeps the retake hint', () {
    final r = ScanResult.fromJson({'readable': false, 'retake_hint': 'More light'}, 3);
    expect(r.readable, isFalse);
    expect(r.retakeHint, 'More light');
    expect(r.ideas, isEmpty);
  });

  test('scan result keeps photo type, depicted model and catalog matches', () {
    final r = ScanResult.fromJson({
      'readable': true,
      'source': 'instructions',
      'depicted': ' a golden dragon ',
      'pieces': {'colors': [{'name': 'gold', 'hex': '#D9A93A', 'count': 30}]},
      'matches': [
        {'id': 'dragon', 'why': 'same theme'},
        {'why': 'no id'},
        'junk',
      ],
      'ideas': [],
    }, 4);
    expect(r.source, 'instructions');
    expect(r.depicted, 'a golden dragon');
    expect(r.matches.length, 1);
    expect(r.matches.first.$1, 'dragon');
    expect(ScanResult.fromJson({'source': 'weird'}, 0).source, 'pile');
  });
}
