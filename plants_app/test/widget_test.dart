import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shcho_z_roslynoyu/garden.dart';
import 'package:shcho_z_roslynoyu/l10n.dart';
import 'package:shcho_z_roslynoyu/models.dart';
import 'package:shcho_z_roslynoyu/screens/splash_screen.dart';
import 'package:shcho_z_roslynoyu/shops.dart';

// Відповідь сервера в тому ж форматі, що віддає PhotoAI Engine (профіль plants)
final sample = {
  'plant_detected': true,
  'name': 'монстера',
  'latin': 'Monstera deliciosa',
  'family': 'Ароїдні',
  'confidence': 0.55,
  'alternatives': [
    {'name': 'філодендрон', 'latin': 'Philodendron', 'confidence': 0.3},
  ],
  'health': 'needs_attention',
  'health_summary': 'Її переливають.',
  'problems': [
    {
      'title': 'Перелив',
      'cause': 'watering',
      'severity': 'high',
      'signs': 'жовті нижні листки',
      'why': 'Вода застоюється.',
      'fix_now': ['Не поливай 7–10 днів', 'Пересади в горщик з отвором'],
      'prevention': 'Поливай після просихання',
    },
  ],
  'care': {'light': 'яскраве розсіяне', 'watering': 'коли верх сухий', 'water_every_days': 7, 'humidity': '50–60 %'},
  'toxicity': {'pets': true, 'kids': true, 'note': 'Сік подразнює'},
  'todo_now': ['Не поливай тиждень', 'Пересади'],
  'fun_fact': 'Дірки в листі — від вітру.',
  'symptoms': ['жовтіють нижні листки'],
};

void main() {
  test('winter mode, watering log, treatment checks, remedies, shops', () async {
    SharedPreferences.setMockInitialValues({});
    final g = GardenStore();
    final res = PlantResult.fromJson({
      'name': 'фікус',
      'care': {'water_every_days': 7, 'winter_water_every_days': 14},
      'problems': [
        {'title': 'Перелив', 'remedies': ['перліт', ' '], 'fix_now': ['Не поливай']},
      ],
    });
    expect(res.problems.single.remedies, ['перліт']);
    expect(res.care.winterWaterEveryDays, 14);
    final p = await g.add(res, now: DateTime(2026, 6, 1));
    expect(p.everyDaysAt(DateTime(2026, 6, 1)), 7);
    expect(p.everyDaysAt(DateTime(2026, 12, 1)), 14); // зимовий режим за замовчуванням увімкнено
    await g.setEvery(p, 4);
    expect(p.everyDaysAt(DateTime(2027, 1, 10)), 8); // пропорційно до порад
    await g.setWinterMode(false);
    expect(p.everyDaysAt(DateTime(2026, 12, 1)), 4);
    await g.water(p, at: DateTime(2026, 6, 2));
    await g.water(p, at: DateTime(2026, 6, 6));
    expect(p.log.first, DateTime(2026, 6, 6));
    await g.addCheck(p, const Progress(trend: Trend.better, note: 'нових плям немає'), at: DateTime(2026, 6, 10));
    final g2 = GardenStore();
    await g2.load();
    expect(g2.winterMode, isFalse);
    expect(g2.items.single.log.length, 2);
    expect(g2.items.single.checks.single.trend, Trend.better);
    await g2.setWinterMode(true);

    final prog = PlantResult.fromJson({'name': 'x', 'progress': {'trend': 'worse', 'still': ['плями'], 'next_step': 'пересади'}});
    expect(prog.progress!.trend, Trend.worse);
    final params = const PlantParams().progress('фікус', ['Перелив'], 10).toJson();
    expect(params['progress_for'], 'фікус');
    expect(params['progress_days'], 10);
    expect(const PlantParams().toJson().containsKey('progress_for'), isFalse);

    expect(shopsFor('uk').first.search('перліт').toString(), contains('epicentrk.ua'));
    expect(shopsFor('pl').first.name, 'Allegro');
    final uk = supportedStrings['uk']!, pl = supportedStrings['pl']!;
    expect(uk.wateredTimes(2), 'За 30 днів: 2 поливи');
    expect(pl.wateredTimes(5), 'Przez 30 dni: 5 podlań');
    expect(uk.winterEvery(14), '❄️ Взимку: раз на 14 днів');
    expect(uk.trendLabels[Trend.better], 'Краще 🌱');
    for (final k in ['whereBuy', 'winterMode', 'progressTitle', 'trend_same']) {
      expect(uk.m.containsKey(k) && pl.m.containsKey(k), isTrue, reason: k);
    }
  });

  test('PlantResult parses engine response', () {
    final r = PlantResult.fromJson(sample);
    expect(r.name, 'монстера');
    expect(r.unsure, isTrue);
    expect(r.alternatives.single.name, 'філодендрон');
    expect(r.health, Health.needsAttention);
    expect(r.problems.single.severity, Severity.high);
    expect(r.problems.single.emoji, '💧');
    expect(r.care.waterEveryDays, 7);
    expect(r.toxicity.isToxic, isTrue);
    expect(r.symptoms, ['жовтіють нижні листки']);
    // збереження й відновлення без втрат
    final back = PlantResult.fromJson(r.toJson());
    expect(back.problems.single.fixNow.length, 2);
    expect(back.health, Health.needsAttention);
    expect(r.detailRequest(r.problems.first, const PlantParams(language: 'pl'))['problem'], 'Перелив');
  });

  test('watering schedule and plurals', () async {
    SharedPreferences.setMockInitialValues({});
    final g = GardenStore();
    final day0 = DateTime(2026, 5, 1, 10);
    final p = await g.add(PlantResult.fromJson(sample), now: day0);
    expect(p.daysToWater(day0), 7);
    expect(p.needsWater(DateTime(2026, 5, 8, 9)), isTrue);
    expect(g.thirstyCount(DateTime(2026, 5, 10)), 1);
    await g.water(p, at: DateTime(2026, 5, 10, 8));
    expect(p.daysToWater(DateTime(2026, 5, 10, 20)), 7);
    await g.setEvery(p, 3);
    expect(p.daysToWater(DateTime(2026, 5, 10)), 3);
    // переживає перезапуск
    final g2 = GardenStore();
    await g2.load();
    expect(g2.items.single.waterEveryDays, 3);

    final uk = supportedStrings['uk']!, pl = supportedStrings['pl']!;
    expect(uk.everyDays(1), 'щодня');
    expect(uk.everyDays(2), 'раз на 2 дні');
    expect(uk.everyDays(5), 'раз на 5 днів');
    expect(uk.waterIn(-1), contains('1 день'));
    expect(uk.thirsty(2), 'Сьогодні полити: 2 рослини');
    expect(pl.everyDays(12), 'co 12 dni');
    expect(pl.thirsty(5), 'Dziś podlać: 5 roślin');
  });

  testWidgets('splash: Koreec → app icon → disappears', (tester) async {
    await tester.pumpWidget(L10n(
      strings: supportedStrings['uk']!,
      child: const MaterialApp(home: AnimatedSplash(child: Text('ГОЛОВНА'))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('Що з рослиною?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Що з рослиною?'), findsNothing);
    expect(find.text('ГОЛОВНА'), findsOneWidget);
  });
}
