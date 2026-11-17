import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import 'recipe_screen.dart';
import 'results_screen.dart' show EmojiTile, Fact;

/// Меню на тиждень з наявних продуктів: дні → страви, зведений список покупок.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.ingredients, required this.useSoon, required this.params});
  final List<String> ingredients;
  final List<String> useSoon;
  final RecipeParams params;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int _mealsPerDay = 2;
  WeekPlan? _plan;
  bool _loading = false;
  ApiException? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await AppScope.of(context).api.plan(
            widget.ingredients,
            widget.params,
            useSoon: widget.useSoon,
            mealsPerDay: _mealsPerDay,
          );
      if (mounted) setState(() => _plan = plan);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addShopping(Strings t) {
    final n = AppScope.of(context).shopping.addLines(_plan!.shopping, t.weekMenu);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.addedToShopping(n))));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(t.weekMenu, style: display(28)),
          const SizedBox(height: 14),
          if (plan == null) ...[
            Text(t.mealsPerDay, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: t.mealsOptions.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _mealsPerDay == e.key,
                        onSelected: _loading ? null : (_) => setState(() => _mealsPerDay = e.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 18),
            if (_loading)
              Row(children: [
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 14),
                Expanded(child: Text(t.planLoading, style: theme.textTheme.bodyMedium?.copyWith(color: extra.muted))),
              ])
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(t.error(_error!), style: TextStyle(color: extra.tomato, fontWeight: FontWeight.w700)),
                ),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(_error == null ? t.makePlan : t.tryAgain),
              ),
            ],
          ] else ...[
            for (final day in plan.days) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Text(t.day(day.day), style: display(18)),
              ),
              for (final meal in day.meals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MealTile(
                    meal: meal,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RecipeScreen(recipe: meal.toRecipe(widget.params.servings), params: widget.params),
                    )),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lime, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(t.toBuyWeek, style: display(18)),
                const SizedBox(height: 8),
                if (plan.shopping.isEmpty)
                  Text(t.nothingToBuy, style: TextStyle(color: extra.mint, fontWeight: FontWeight.w700))
                else ...[
                  for (final l in plan.shopping)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(l.amount.isEmpty ? '• ${l.name}' : '• ${l.name} — ${l.amount}'),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _addShopping(t),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(t.addAllToShopping(plan.shopping.length)),
                  ),
                ],
              ]),
            ),
            if (plan.tip != null && plan.tip!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: extra.saffronBg, borderRadius: BorderRadius.circular(18)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡'),
                  const SizedBox(width: 10),
                  Expanded(child: Text(plan.tip!)),
                ]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal, required this.onTap});
  final PlanMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final missing = meal.ingredients.where((i) => !i.available).length;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            EmojiTile(emoji: mealTypeEmoji[meal.mealType] ?? '🍽', color: mealColor(meal.mealType), size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.mealTypeLabels[meal.mealType] ?? meal.mealType,
                    style: theme.textTheme.bodySmall?.copyWith(color: extra.muted)),
                Text(meal.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Fact(icon: Icons.schedule, text: t.minutes(meal.timeMinutes)),
                  if (meal.kcal != null) Fact(icon: Icons.local_fire_department_outlined, text: '${meal.kcal} kcal'),
                  if (missing > 0)
                    Fact(icon: Icons.shopping_cart_outlined, text: t.toBuy(missing), fg: extra.tomato, bg: extra.tomatoBg),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}
