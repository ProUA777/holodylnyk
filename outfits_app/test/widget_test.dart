import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shcho_vdyahnuty/closet.dart';
import 'package:shcho_vdyahnuty/l10n.dart';
import 'package:shcho_vdyahnuty/models.dart';
import 'package:shcho_vdyahnuty/screens/splash_screen.dart';
import 'package:shcho_vdyahnuty/shops.dart';
import 'package:shcho_vdyahnuty/widgets/outfit_card.dart' show shareText;

// Відповідь сервера в тому ж форматі, що віддає PhotoAI Engine (профіль outfits)
final sample = {
  'clothes_detected': true,
  'photo_kind': 'worn',
  'items': [
    {'name': 'біла сорочка', 'kind': 'top', 'color': 'білий', 'hex': '#F5F5F2'},
    {'name': 'темні джинси', 'kind': 'bottom', 'color': 'синій', 'hex': '#1F2A44'},
    {'name': 'кеди', 'kind': 'shoes', 'hex': 'погано'},
  ],
  'palette': ['#F5F5F2', '#1F2A44', 'xx'],
  'outfits': [
    {
      'title': 'Класика',
      'occasion': 'work',
      'items': ['біла сорочка', 'темні джинси'],
      'add': ['лофери'],
      'why': 'Контраст.',
      'tips': ['Заправ сорочку'],
    },
    {'title': 'Без речей', 'items': []},
  ],
  'verdict': {'score': 12, 'good': ['колір'], 'change': ['взуття']},
  'shopping': ['сірий светр'],
};

void main() {
  test('worn counter, outfit of the day, share text, shops', () async {
    SharedPreferences.setMockInitialValues({});
    final looks = LooksStore();
    const o = Outfit(title: 'Офіс без нудьги', occasion: Occasion.work, items: ['джинси', 'сорочка'], add: ['лофери'], why: 'Чисто й просто');
    final d1 = DateTime(2026, 11, 20, 9), d2 = DateTime(2026, 11, 24, 9);
    await looks.toggleWorn(o, now: d1);
    await looks.toggleWorn(o, now: d2);
    expect(looks.wornCount(o), 2);
    expect(looks.wornToday(o, now: d2), isTrue);
    await looks.toggleWorn(o, now: DateTime(2026, 11, 24, 20)); // той самий день — скасування
    expect(looks.wornCount(o), 1);
    await looks.setToday(o, now: d2);
    expect(looks.todayOutfit(now: DateTime(2026, 11, 24, 22))!.title, o.title);
    expect(looks.todayOutfit(now: DateTime(2026, 11, 25, 7)), isNull); // новий день — новий образ
    expect(looks.recentlyWorn(now: DateTime(2026, 11, 25)), ['Офіс без нудьги']);
    expect(looks.recentlyWorn(now: DateTime(2026, 12, 5)), isEmpty);
    final again = LooksStore();
    await again.load();
    expect(again.wornCount(o), 1);
    expect(again.todayOutfit(now: d2)!.items, ['джинси', 'сорочка']);

    final uk = supportedStrings['uk']!, pl = supportedStrings['pl']!;
    final text = shareText(o, uk);
    expect(text, contains('• джинси'));
    expect(text, contains('+ лофери'));
    expect(text, endsWith('Підібрано в «Що вдягнути?»'));
    expect(uk.wornTimes(3), 'Одягали 3 рази');
    expect(pl.wornTimes(5), 'Noszona 5 razy');
    for (final k in ['ootdTitle', 'wornToday', 'share', 'whereBuy']) {
      expect(uk.m.containsKey(k) && pl.m.containsKey(k), isTrue, reason: k);
    }
    expect(shopsFor('pl').first.search('białe trampki').toString(), contains('zalando.pl'));
    expect(shopsFor('uk').last.search('біла сорочка').toString(), contains('q-'));
    expect(const OutfitParams().copyWith(outfitCount: 1).toJson()['outfit_count'], 1);
  });

  test('OutfitResult parses engine response', () {
    final r = OutfitResult.fromJson(sample);
    expect(r.worn, isTrue);
    expect(r.items.length, 3);
    expect(r.items.first.swatch, const Color(0xFFF5F5F2));
    expect(r.items.last.swatch, isNull);
    expect(r.items.last.emoji, '👟');
    expect(r.palette.length, 2);
    expect(r.outfits.single.title, 'Класика'); // образ без речей відкидаємо
    expect(r.outfits.single.occasion, Occasion.work);
    expect(r.verdict!.score, 10);
    final p = const OutfitParams().copyWith(occasion: Occasion.date, weather: Weather.rain);
    expect(OutfitParams.fromJson(p.toJson()).weather, Weather.rain);
  });

  test('wardrobe without duplicates, saved looks, plurals', () async {
    SharedPreferences.setMockInitialValues({});
    final w = WardrobeStore();
    final r = OutfitResult.fromJson(sample);
    expect(await w.addAll(r.items), 3);
    expect(await w.addAll(r.items), 0);
    expect(w.byKind.keys.first, Kind.top);
    final looks = LooksStore();
    await looks.toggle(r.outfits.first);
    expect(looks.isSaved(r.outfits.first), isTrue);
    final again = LooksStore();
    await again.load();
    expect(again.items.single.add, ['лофери']);
    await looks.toggle(r.outfits.first);
    expect(looks.items, isEmpty);

    final uk = supportedStrings['uk']!, pl = supportedStrings['pl']!;
    expect(uk.itemsN(1), '1 річ');
    expect(uk.itemsN(3), '3 речі');
    expect(uk.itemsN(11), '11 речей');
    expect(uk.addedN(0), uk.inWardrobe);
    expect(pl.itemsN(5), '5 rzeczy');
    expect(uk.occasionLabels[Occasion.date], 'Побачення');
  });

  testWidgets('splash: Koreec → app icon → disappears', (tester) async {
    await tester.pumpWidget(L10n(
      strings: supportedStrings['uk']!,
      child: const MaterialApp(home: AnimatedSplash(child: Text('ГОЛОВНА'))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('Що вдягнути?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Що вдягнути?'), findsNothing);
    expect(find.text('ГОЛОВНА'), findsOneWidget);
  });
}
