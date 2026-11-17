// Підписи дієт, типів страв і складності — у l10n.dart (українська й польська).
enum Diet { any, vegetarian, vegan, noPork, glutenFree, lactoseFree }

const _dietApi = {
  Diet.any: 'any',
  Diet.vegetarian: 'vegetarian',
  Diet.vegan: 'vegan',
  Diet.noPork: 'no_pork',
  Diet.glutenFree: 'gluten_free',
  Diet.lactoseFree: 'lactose_free',
};

/// Ціль харчування: будь-що / легке (до ~450 ккал) / білкове (від ~25 г білка)
enum Goal { any, light, protein }

class RecipeParams {
  final String language;
  final Diet diet;
  final Goal goal;
  final List<String> liked; // страви з 👍 — AI пропонує схоже
  final List<String> disliked; // страви з 👎 — AI уникає
  final int? maxTimeMinutes;
  final int servings;
  final int recipeCount;
  final bool assumePantry;

  const RecipeParams({
    this.language = 'uk',
    this.diet = Diet.any,
    this.goal = Goal.any,
    this.liked = const [],
    this.disliked = const [],
    this.maxTimeMinutes,
    this.servings = 2,
    this.recipeCount = 6,
    this.assumePantry = true,
  });

  RecipeParams copyWith({
    String? language,
    Diet? diet,
    Goal? goal,
    List<String>? liked,
    List<String>? disliked,
    int? maxTimeMinutes,
    bool clearTime = false,
    int? servings,
  }) =>
      RecipeParams(
        language: language ?? this.language,
        diet: diet ?? this.diet,
        goal: goal ?? this.goal,
        liked: liked ?? this.liked,
        disliked: disliked ?? this.disliked,
        maxTimeMinutes: clearTime ? null : (maxTimeMinutes ?? this.maxTimeMinutes),
        servings: servings ?? this.servings,
        recipeCount: recipeCount,
        assumePantry: assumePantry,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'diet': _dietApi[diet],
        'goal': goal.name,
        if (liked.isNotEmpty) 'liked': liked.take(15).toList(),
        if (disliked.isNotEmpty) 'disliked': disliked.take(15).toList(),
        if (maxTimeMinutes != null) 'max_time_minutes': maxTimeMinutes,
        'servings': servings,
        'recipe_count': recipeCount,
        'assume_pantry': assumePantry,
      };
}

class Ingredient {
  final String name;
  final String? amount;
  final double confidence;
  final String freshness; // fresh | use_soon | spoiled
  final String? freshnessNote;

  Ingredient({required this.name, this.amount, this.confidence = 1, this.freshness = 'fresh', this.freshnessNote});

  bool get useSoon => freshness == 'use_soon';

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        name: j['name'] as String,
        amount: j['amount'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 1,
        freshness: (j['freshness'] as String?) ?? 'fresh',
        freshnessNote: j['freshness_note'] as String?,
      );
}

class RecipeIngredient {
  final String name;
  final String amount;
  final bool available;

  RecipeIngredient({required this.name, required this.amount, required this.available});

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        name: j['name'] as String,
        amount: (j['amount'] as String?) ?? '',
        available: (j['available'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'available': available};
}

const mealTypeEmoji = {
  'breakfast': '🍳',
  'soup': '🍲',
  'main': '🍛',
  'salad': '🥗',
  'baking': '🥐',
  'dessert': '🍰',
  'snack': '🥪',
  'drink': '🥤',
};

class Recipe {
  final String title;
  final String mealType;
  final String? cuisine;
  final String? method;
  final String shortDescription;
  final int timeMinutes;
  final String difficulty;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<String> tags;
  final int? caloriesPerServing;
  final int? proteinG;
  final int? fatG;
  final int? carbsG;
  final List<String> usesSoon; // продукти «скоро зіпсуються», які ця страва рятує
  final String? tip;

  /// Детальний рецепт у Markdown (приходить з /detail, зберігається в обраному)
  String? details;

  String get emoji => mealTypeEmoji[mealType] ?? '🍽';

  Recipe({
    required this.title,
    this.mealType = 'main',
    this.cuisine,
    this.method,
    required this.shortDescription,
    required this.timeMinutes,
    required this.difficulty,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.tags,
    this.caloriesPerServing,
    this.proteinG,
    this.fatG,
    this.carbsG,
    this.usesSoon = const [],
    this.tip,
    this.details,
  });

  int get missingCount => ingredients.where((i) => !i.available).length;
  List<RecipeIngredient> get missing => ingredients.where((i) => !i.available).toList();

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        title: j['title'] as String,
        mealType: (j['meal_type'] as String?) ?? 'main',
        cuisine: j['cuisine'] as String?,
        method: j['method'] as String?,
        shortDescription: (j['short_description'] as String?) ?? '',
        timeMinutes: (j['time_minutes'] as num).toInt(),
        difficulty: (j['difficulty'] as String?) ?? 'easy',
        servings: (j['servings'] as num?)?.toInt() ?? 2,
        ingredients: (j['ingredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (j['steps'] as List).map((e) => e as String).toList(),
        tags: ((j['tags'] as List?) ?? const []).map((e) => e as String).toList(),
        caloriesPerServing: (j['calories_per_serving'] as num?)?.toInt(),
        proteinG: (j['protein_g'] as num?)?.toInt(),
        fatG: (j['fat_g'] as num?)?.toInt(),
        carbsG: (j['carbs_g'] as num?)?.toInt(),
        usesSoon: ((j['uses_soon'] as List?) ?? const []).map((e) => e as String).toList(),
        tip: j['tip'] as String?,
        details: j['details'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'meal_type': mealType,
        'cuisine': cuisine,
        'method': method,
        'short_description': shortDescription,
        'time_minutes': timeMinutes,
        'difficulty': difficulty,
        'servings': servings,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps,
        'tags': tags,
        'calories_per_serving': caloriesPerServing,
        'protein_g': proteinG,
        'fat_g': fatG,
        'carbs_g': carbsG,
        'uses_soon': usesSoon,
        'tip': tip,
        'details': details,
      };

  /// Те, що бекенд /detail очікує про страву
  Map<String, dynamic> toDetailRequest(RecipeParams params) => {
        'title': title,
        'cuisine': cuisine,
        'time_minutes': timeMinutes,
        'servings': servings,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'params': params.toJson(),
      };
}

class RecipesResult {
  final List<Ingredient> ingredients;
  final List<Recipe> recipes;

  RecipesResult({required this.ingredients, required this.recipes});

  factory RecipesResult.fromJson(Map<String, dynamic> j) => RecipesResult(
        ingredients: ((j['ingredients'] as List?) ?? const [])
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        recipes: ((j['recipes'] as List?) ?? const [])
            .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}


// ---------- Меню на тиждень ----------

class PlanMeal {
  final String mealType;
  final String title;
  final String? cuisine;
  final String shortDescription;
  final int timeMinutes;
  final int? kcal;
  final List<RecipeIngredient> ingredients;

  PlanMeal({
    required this.mealType,
    required this.title,
    this.cuisine,
    this.shortDescription = '',
    this.timeMinutes = 30,
    this.kcal,
    this.ingredients = const [],
  });

  factory PlanMeal.fromJson(Map<String, dynamic> j) => PlanMeal(
        mealType: (j['meal_type'] as String?) ?? 'main',
        title: j['title'] as String,
        cuisine: j['cuisine'] as String?,
        shortDescription: (j['short_description'] as String?) ?? '',
        timeMinutes: (j['time_minutes'] as num?)?.toInt() ?? 30,
        kcal: (j['calories_per_serving'] as num?)?.toInt(),
        ingredients: ((j['ingredients'] as List?) ?? const [])
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Страва з меню відкривається як звичайний рецепт — детальні кроки підтягуються з /detail.
  Recipe toRecipe(int servings) => Recipe(
        title: title,
        mealType: mealType,
        cuisine: cuisine,
        shortDescription: shortDescription,
        timeMinutes: timeMinutes,
        difficulty: 'easy',
        servings: servings,
        ingredients: ingredients,
        steps: const [],
        tags: const [],
        caloriesPerServing: kcal,
      );
}

class PlanDay {
  final int day;
  final List<PlanMeal> meals;
  PlanDay({required this.day, required this.meals});

  factory PlanDay.fromJson(Map<String, dynamic> j) => PlanDay(
        day: (j['day'] as num).toInt(),
        meals: (j['meals'] as List).map((e) => PlanMeal.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class WeekPlan {
  final List<PlanDay> days;
  final List<({String name, String amount})> shopping;
  final String? tip;
  WeekPlan({required this.days, required this.shopping, this.tip});

  factory WeekPlan.fromJson(Map<String, dynamic> j) => WeekPlan(
        days: (j['days'] as List).map((e) => PlanDay.fromJson(e as Map<String, dynamic>)).toList(),
        shopping: ((j['shopping'] as List?) ?? const [])
            .map((e) => (name: (e as Map)['name'] as String, amount: (e['amount'] as String?) ?? ''))
            .toList(),
        tip: j['tip'] as String?,
      );
}
