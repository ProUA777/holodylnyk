import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shcho_zlamalos/l10n.dart';
import 'package:shcho_zlamalos/models.dart';
import 'package:shcho_zlamalos/repairs.dart';
import 'package:shcho_zlamalos/screens/splash_screen.dart';

// Відповідь сервера в тому ж форматі, що віддає PhotoAI Engine (профіль repair)
final sample = {
  'detected': true,
  'thing': 'змішувач для кухні',
  'category': 'plumbing',
  'confidence': 0.9,
  'summary': 'Зносився картридж.',
  'safety': 'diy',
  'safety_note': 'Перекрий воду.',
  'causes': [
    {'title': 'Зношений картридж', 'likelihood': 0.7, 'fix': ['Перекрий воду', 'Заміни картридж'], 'difficulty': 'easy', 'minutes': 25},
    {'title': '', 'likelihood': 0.1},
  ],
  'parts': [
    {'name': 'шестигранник 2,5 мм', 'is_tool': true},
    {'name': 'картридж 40 мм', 'is_tool': false, 'price': '250–450 грн'},
  ],
  'pro_cost': '400–700 грн',
  'signs': ['тече з-під ручки'],
};

void main() {
  test('RepairResult parses engine response', () {
    final r = RepairResult.fromJson(sample);
    expect(r.thing, 'змішувач для кухні');
    expect(r.emoji, '🚰');
    expect(r.safety, Safety.diy);
    expect(r.causes.single.difficulty, Difficulty.easy); // причина без назви відкинута
    expect(r.tools.single.name, 'шестигранник 2,5 мм');
    expect(r.spares.single.price, '250–450 грн');
    final back = RepairResult.fromJson(r.toJson());
    expect(back.causes.single.fix.length, 2);
    expect(back.signs, ['тече з-під ручки']);
    expect(RepairParams.fromJson(const RepairParams(skill: Skill.pro).toJson()).skill, Skill.pro);
  });

  test('repairs store: bought, done, order, plurals', () async {
    SharedPreferences.setMockInitialValues({});
    final s = RepairsStore();
    final a = await s.add(RepairResult.fromJson(sample), now: DateTime(2026, 1, 1));
    final b = await s.add(RepairResult.fromJson(sample), now: DateTime(2026, 1, 2));
    expect(s.openCount, 2);
    await s.setDone(b, true);
    expect(s.sorted.first.id, a.id); // незакінчені — першими
    await s.toggleBought(a, 'картридж 40 мм');
    final again = RepairsStore();
    await again.load();
    expect(again.items.firstWhere((x) => x.id == a.id).bought, {'картридж 40 мм'});
    expect(again.openCount, 1);

    final uk = supportedStrings['uk']!, pl = supportedStrings['pl']!;
    expect(uk.inWork(2), 'В роботі: 2 ремонти');
    expect(uk.minutes(25), '~25 хв');
    expect(uk.minutes(120), '~2 год');
    expect(pl.minutes(25), '~25 min');
    expect(pl.inWork(5), 'W trakcie: 5 napraw');
    expect(uk.safetyLabels[Safety.pro], 'Краще майстер');
  });

  testWidgets('splash: Koreec → app icon → disappears', (tester) async {
    await tester.pumpWidget(L10n(
      strings: supportedStrings['uk']!,
      child: const MaterialApp(home: AnimatedSplash(child: Text('ГОЛОВНА'))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('Що зламалось?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Що зламалось?'), findsNothing);
    expect(find.text('ГОЛОВНА'), findsOneWidget);
  });
}
