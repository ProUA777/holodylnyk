import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shcho_zlamalos/l10n.dart';
import 'package:shcho_zlamalos/models.dart';
import 'package:shcho_zlamalos/repairs.dart';
import 'package:shcho_zlamalos/shops.dart';
import 'package:shcho_zlamalos/markdown_view.dart' show minutesIn;
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
  'maintenance': [
    {'task': 'почистити аератор', 'every_days': 90},
    {'task': '', 'every_days': 30},
  ],
};

void main() {
  test('maintenance schedule, after-check, shops, strings', () async {
    SharedPreferences.setMockInitialValues({});
    final s = RepairsStore();
    final r = await s.add(RepairResult.fromJson(sample), now: DateTime(2026, 1, 1));
    final m = r.result.maintenance.single; // порожня справа відкинута
    expect(s.dueService(now: DateTime(2026, 12, 1)), isEmpty); // ще не полагоджено
    await s.setDone(r, true, now: DateTime(2026, 2, 1));
    expect(r.daysToService(m, DateTime(2026, 2, 1)), 90);
    expect(s.dueService(now: DateTime(2026, 3, 1)), isEmpty);
    expect(s.dueService(now: DateTime(2026, 5, 2)).single.$3, 0);
    await s.markServiced(r, m, now: DateTime(2026, 5, 2));
    expect(s.dueService(now: DateTime(2026, 5, 3)), isEmpty);
    final again = RepairsStore();
    await again.load();
    expect(again.items.single.serviced[m.task], DateTime(2026, 5, 2));
    expect(again.items.single.doneAt, DateTime(2026, 2, 1));

    final after = RepairResult.fromJson({'thing': 'x', 'after': {'ok': false, 'issues': ['підтікає'], 'advice': 'дотягни гайку'}});
    expect(after.after!.issues, ['підтікає']);
    final open2 = await s.add(RepairResult.fromJson(sample));
    await s.setAfter(open2, true);
    expect(open2.done, isTrue);
    expect(const RepairParams().verify('змішувач', null).toJson()['verify_thing'], 'змішувач');
    expect(const RepairParams().toJson().containsKey('verify_thing'), isFalse);

    expect(shopsFor('pl').first.name, 'Allegro');
    expect(shopsFor('uk').first.search('картридж 40 мм').toString(), contains('rozetka.com.ua'));
    expect(shopsFor('uk').last.search('картридж 40 мм').toString(), contains('olx.ua'));
    expect(shopQuery('картридж', brandModel: 'Grohe', isTool: false), 'картридж Grohe');
    expect(shopQuery('ключ', brandModel: 'Grohe', isTool: true), 'ключ');
    expect(minutesIn('Залиш на 2 години'), 120);
    expect(minutesIn('Почекай 10 хв'), 10);

    final uk = supportedStrings['uk']!, pl = supportedStrings['pl']!;
    expect(uk.everyDays(90), 'раз на 3 місяці');
    expect(uk.everyDays(14), 'раз на 14 днів');
    expect(uk.dueIn(0), 'сьогодні');
    expect(pl.everyDays(180), 'co 6 miesięcy');
    for (final k in ['fixMode', 'whereBuy', 'afterCheck', 'maintTitle', 'cmdNext', 'voiceOff']) {
      expect(uk.m.containsKey(k) && pl.m.containsKey(k), isTrue, reason: k);
    }
    expect(pl.cmdNext, contains('dalej'));
  });

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
