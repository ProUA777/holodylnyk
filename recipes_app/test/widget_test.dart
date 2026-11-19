import 'package:flutter/material.dart';
// Перевірка розбору відповіді бекенду (той самий формат, що віддає PhotoAI Engine).
import 'package:flutter_test/flutter_test.dart';
import 'package:shcho_pryhotuvaty/markdown_view.dart';
import 'package:shcho_pryhotuvaty/api.dart';
import 'package:shcho_pryhotuvaty/l10n.dart';
import 'package:shcho_pryhotuvaty/models.dart';
import 'package:shcho_pryhotuvaty/scale.dart';
import 'package:shcho_pryhotuvaty/screens/splash_screen.dart';
import 'package:shcho_pryhotuvaty/shopping.dart';
import 'package:shcho_pryhotuvaty/tastes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('RecipesResult parses engine response', () {
    final r = RecipesResult.fromJson({
      'food_detected': true,
      'ingredients': [
        {'name': 'яйця', 'amount': '~6 шт', 'category': 'dairy_eggs', 'confidence': 0.97},
      ],
      'recipes': [
        {
          'id': 1,
          'title': 'Омлет',
          'short_description': 'Швидко',
          'time_minutes': 10,
          'difficulty': 'easy',
          'servings': 2,
          'ingredients': [
            {'name': 'яйця', 'amount': '4 шт', 'available': true},
            {'name': 'зелень', 'amount': 'пучок', 'available': false},
          ],
          'steps': ['Збий яйця', 'Посмаж'],
          'tags': ['сніданок'],
          'calories_per_serving': 290,
          'tip': null,
        }
      ],
    });
    expect(r.ingredients.single.name, 'яйця');
    expect(r.recipes.single.missingCount, 1);
    final back = Recipe.fromJson(r.recipes.single.toJson());
    expect(back.steps.length, 2);
  });

  test('RecipeParams sends API names', () {
    final j = const RecipeParams(diet: Diet.noPork, maxTimeMinutes: 30).toJson();
    expect(j['diet'], 'no_pork');
    expect(j['max_time_minutes'], 30);
    expect(const RecipeParams().toJson().containsKey('max_time_minutes'), false);
  });

  test('cooking steps and timers come from the "Приготування" section', () {
    const md = '## Інгредієнти\n- яйця — 4 шт\n## Підготовка\n1. Наріж цибулю\n'
        '## Приготування\n1. Обсмаж **цибулю** 4–5 хв.\n2. Додай яйця.\n## Подача\nОдразу.';
    expect(cookingSteps(md), ['Обсмаж цибулю 4–5 хв.', 'Додай яйця.']);
    expect(minutesIn('Туши 8–10 хв'), 10);
    expect(minutesIn('Запікай 25 хвилин при 200 °C'), 25);
    expect(minutesIn('Посоли'), 0);
    final blocks = parseMarkdown(md);
    expect(blocks.whereType<MdStep>().length, 3);
  });

  test('details survive favorites round-trip', () {
    final r = Recipe.fromJson({
      'title': 'Суп', 'meal_type': 'soup', 'cuisine': 'українська', 'time_minutes': 40, 'difficulty': 'medium',
      'servings': 4, 'ingredients': [{'name': 'буряк', 'amount': '2 шт', 'available': true}],
      'steps': ['Звари'], 'details': '## Приготування\n1. Звари 40 хв',
    });
    final back = Recipe.fromJson(r.toJson());
    expect(back.details, r.details);
    expect(back.emoji, '🍲');
    expect(r.toDetailRequest(const RecipeParams())['cuisine'], 'українська');
  });

  test('Ukrainian and Polish plurals and errors', () {
    final uk = StringsUk(), pl = StringsPl();
    expect(uk.foundProducts(1), 'Знайшов 1 продукт');
    expect(uk.foundProducts(3), 'Знайшов 3 продукти');
    expect(uk.foundProducts(12), 'Знайшов 12 продуктів');
    expect(pl.foundProducts(1), 'Znalazłem 1 produkt');
    expect(pl.foundProducts(22), 'Znalazłem 22 produkty');
    expect(pl.foundProducts(5), 'Znalazłem 5 produktów');
    expect(pl.portions(2), 'porcje');
    expect(pl.error(ApiException('daily_limit')), pl.errDailyLimit);
    expect(uk.error(ApiException('nothing_recognized', serverMessage: 'Це кіт')), 'Це кіт');
    // усі типи страв і дієти мають підписи обома мовами
    for (final s in [uk, pl]) {
      expect(s.mealTypeLabels.keys.toSet(), mealTypeEmoji.keys.toSet());
      expect(s.dietLabels.keys.toSet(), Diet.values.toSet());
    }
  });

  test('shopping list merges the same product from different recipes', () {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    final store = ShoppingStore();
    Recipe recipe(String title, List<Map<String, dynamic>> ings) => Recipe.fromJson({
          'title': title, 'time_minutes': 10, 'difficulty': 'easy', 'servings': 2,
          'ingredients': ings, 'steps': ['x'],
        });
    final a = recipe('Омлет', [
      {'name': 'молоко', 'amount': '100 мл', 'available': false},
      {'name': 'яйця', 'amount': '3 шт', 'available': true},
    ]);
    final b = recipe('Млинці', [
      {'name': 'Молоко', 'amount': '500 мл', 'available': false},
      {'name': 'борошно', 'amount': '200 г', 'available': false},
    ]);
    expect(store.addFromRecipe(a), 1);
    expect(store.addFromRecipe(a), 0); // той самий рецепт удруге не дублюється
    expect(store.addFromRecipe(b), 2);
    expect(store.items.length, 2);
    final milk = store.items.firstWhere((i) => i.name == 'молоко');
    expect(milk.amountText, '100 мл + 500 мл');
    expect(milk.recipes, ['Омлет', 'Млинці']);
    store.toggle(milk);
    expect(store.leftCount, 1);
    expect(store.asText('Купити:'), 'Купити:\n• борошно — 200 г');
    store.clearDone();
    expect(store.items.length, 1);
  });

  test('servings scaling', () {
    expect(scaleAmount('200 г', 1.5), '300 г');
    expect(scaleAmount('47 г', 1.1), '50 г'); // грами округлюємо до 5
    expect(scaleAmount('47 шт', 1.1), '52 шт');
    expect(scaleAmount('½ шт', 2), '1 шт');
    expect(scaleAmount('2–3 зубчики', 2), '4–6 зубчики');
    expect(scaleAmount('1/2 склянки', 3), '1,5 склянки');
    expect(scaleAmount('щіпка', 3), 'щіпка');
    expect(scaleAmount('3 шт', 0.5), '1,5 шт');
    const md = '## Інгредієнти\n- яйця — 4 шт\n- борошно – 250 г 🛒\n## Приготування\n1. Смаж 5 хв';
    expect(scaleMarkdown(md, 2), '## Інгредієнти\n- яйця — 8 шт\n- борошно – 500 г 🛒\n## Приготування\n1. Смаж 5 хв');
  });

  test('freshness, macros, week plan and goal are parsed/sent', () {
    final r = RecipesResult.fromJson({
      'ingredients': [
        {'name': 'помідори', 'confidence': 0.9, 'freshness': 'use_soon', 'freshness_note': 'м\'якнуть'},
      ],
      'recipes': [
        {
          'title': 'Шакшука', 'time_minutes': 25, 'difficulty': 'easy', 'servings': 2,
          'ingredients': [{'name': 'помідори', 'amount': '3 шт', 'available': true}],
          'steps': ['x'], 'protein_g': 18, 'fat_g': 20, 'carbs_g': 14, 'uses_soon': ['помідори'],
        }
      ],
    });
    expect(r.ingredients.single.useSoon, true);
    final rec = r.recipes.single;
    expect([rec.proteinG, rec.fatG, rec.carbsG], [18, 20, 14]);
    expect(Recipe.fromJson(rec.toJson()).usesSoon, ['помідори']);

    final plan = WeekPlan.fromJson({
      'days': [
        {'day': 1, 'meals': [{'meal_type': 'soup', 'title': 'Борщ', 'calories_per_serving': 300,
          'ingredients': [{'name': 'буряк', 'amount': '2 шт', 'available': false}]}]}
      ],
      'shopping': [{'name': 'буряк', 'amount': '2 шт'}],
      'tip': 'Звари бульйон наперед',
    });
    expect(plan.days.single.meals.single.toRecipe(4).servings, 4);
    expect(plan.shopping.single.name, 'буряк');

    final j = const RecipeParams(goal: Goal.protein, liked: ['Борщ']).toJson();
    expect(j['goal'], 'protein');
    expect(j['liked'], ['Борщ']);
    expect(const RecipeParams().toJson().containsKey('liked'), false);
  });

  test('taste votes toggle and stay unique', () async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    final tastes = TasteStore();
    await tastes.vote('Борщ', true);
    expect(tastes.voteOf('борщ'), true);
    await tastes.vote('Борщ', false); // перемикання на 👎
    expect(tastes.liked, isEmpty);
    expect(tastes.disliked, ['Борщ']);
    await tastes.vote('Борщ', false); // повторний дотик знімає оцінку
    expect(tastes.voteOf('Борщ'), null);
  });

  testWidgets('заставка: Koreec → значок апки → сама зникає', (tester) async {
    await tester.pumpWidget(L10n(
      strings: supportedStrings['uk']!,
      child: const MaterialApp(home: AnimatedSplash(child: Text('ГОЛОВНА'))),
    ));
    await tester.pump(); // кадр, у якому стартує анімація
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('Що приготувати?'), findsOneWidget);
    expect(find.text('ВІД'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Що приготувати?'), findsNothing);
    expect(find.text('ГОЛОВНА'), findsOneWidget);
  });

  testWidgets('заставка: дотик — пропустити', (tester) async {
    await tester.pumpWidget(L10n(
      strings: supportedStrings['pl']!,
      child: const MaterialApp(home: AnimatedSplash(child: Text('HOME'))),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();
    expect(find.text('Co ugotować?'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });
}
