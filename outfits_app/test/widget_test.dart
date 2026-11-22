import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shcho_vdyahnuty/closet.dart';
import 'package:shcho_vdyahnuty/l10n.dart';
import 'package:shcho_vdyahnuty/models.dart';
import 'package:shcho_vdyahnuty/screens/splash_screen.dart';

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
