import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../markdown_view.dart';
import '../models.dart';
import '../scale.dart';
import '../theme.dart';
import 'cook_screen.dart';
import 'results_screen.dart' show EmojiTile;

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipe, this.params});
  final Recipe recipe;

  /// null — беремо поточні налаштування (напр. коли відкрили зі «Збережених»)
  final RecipeParams? params;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final Set<int> _done = {};
  late int _servings = widget.recipe.servings; // можна змінити кнопками −/+
  double get _factor => _servings / r.servings;
  bool _loading = false;
  ApiException? _error;
  bool _started = false;

  Recipe get r => widget.recipe;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (r.details == null) _loadDetails();
  }

  Future<void> _loadDetails() async {
    final scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final text = await scope.api.detail(r, widget.params ?? scope.prefs.value);
      if (!mounted) return;
      setState(() => r.details = text);
      await scope.favorites.updateDetails(r); // якщо вже в збережених — дописуємо текст
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Усе, чого бракує, — у загальний список покупок (вкладка «Покупки»).
  void _addToShopping() {
    final t = L10n.of(context);
    final n = AppScope.of(context).shopping.addFromRecipe(r, factor: _factor);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.addedToShopping(n))));
  }

  /// Рецепт текстом для Viber / Telegram / WhatsApp
  String _shareText(Strings t) {
    final b = StringBuffer()
      ..writeln('🍽 ${r.title}')
      ..writeln(r.shortDescription)
      ..writeln('🕒 ${t.minutes(r.timeMinutes)} · ${t.portionsShort(_servings)}')
      ..writeln();
    if (r.details != null) {
      for (final line in scaleMarkdown(r.details!, _factor).split('\n')) {
        final h = RegExp(r'^#{1,4}\s+(.*)').firstMatch(line);
        b.writeln(h != null ? '\n${h.group(1)!.toUpperCase()}' : line.replaceAll('**', '').replaceFirst(RegExp(r'^\s*[-*]\s'), '• '));
      }
    } else {
      b.writeln(t.ingredientsH.toUpperCase());
      for (final i in r.ingredients) {
        b.writeln('• ${i.name} — ${scaleAmount(i.amount, _factor)}');
      }
      b
        ..writeln()
        ..writeln(t.cookingH.toUpperCase());
      for (var k = 0; k < r.steps.length; k++) {
        b.writeln('${k + 1}. ${r.steps[k]}');
      }
    }
    b
      ..writeln()
      ..writeln('— ${t.sharedFrom}');
    return b.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  void _startCooking() {
    final steps = r.details != null ? cookingSteps(r.details!) : r.steps;
    if (steps.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CookScreen(title: r.title, steps: steps),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final favorites = AppScope.of(context).favorites;
    final t = L10n.of(context);

    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          tooltip: t.share,
          icon: const Icon(Icons.ios_share),
          onPressed: _loading ? null : () => Share.share(_shareText(t), subject: r.title),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            decoration: BoxDecoration(color: mealTint(context, r.mealType), borderRadius: BorderRadius.circular(32)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EmojiTile(emoji: r.emoji, color: mealColor(r.mealType), size: 76),
          const SizedBox(height: 14),
          Text(r.title, style: display(28)),
          const SizedBox(height: 6),
          Text(r.shortDescription, style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _InfoChip(icon: Icons.schedule, text: t.minutes(r.timeMinutes)),
            _ServingsChip(
              text: t.portionsShort(_servings),
              onMinus: _servings > 1 ? () => setState(() => _servings--) : null,
              onPlus: _servings < 24 ? () => setState(() => _servings++) : null,
            ),
            _InfoChip(text: t.difficultyLabels[r.difficulty] ?? r.difficulty),
            if (r.cuisine != null) _InfoChip(icon: Icons.public, text: r.cuisine!),
            if (r.method != null) _InfoChip(icon: Icons.local_fire_department_outlined, text: r.method!),
            if (r.caloriesPerServing != null) _InfoChip(text: t.kcal(r.caloriesPerServing!)),
          ]),
          if (r.proteinG != null && r.fatG != null && r.carbsG != null) ...[
            const SizedBox(height: 10),
            Text('${t.macros(r.proteinG!, r.fatG!, r.carbsG!)} ${t.perServing}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
          if (r.usesSoon.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.saffron, borderRadius: BorderRadius.circular(99)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.hourglass_bottom, size: 16, color: AppColors.ink),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(t.saves(r.usesSoon.join(', ')),
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ],
            ]),
          ),
          _VoteRow(title: r.title),
          if (r.missingCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _addToShopping,
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(t.addToShopping(r.missingCount)),
              ),
            ),
          if (r.details != null)
            MarkdownView(
              markdown: scaleMarkdown(r.details!, _factor),
              done: _done,
              onToggleStep: (i) => setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i)),
            )
          else if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Row(children: [
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(t.writingDetails,
                      style: theme.textTheme.bodyMedium?.copyWith(color: extra.muted)),
                ),
              ]),
            )
          else ...[
            // Детальний рецепт недоступний — показуємо короткий з картки
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: extra.saffronBg, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(t.error(_error!)),
                  if (_error!.code != 'daily_limit') ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loadDetails,
                      icon: const Icon(Icons.refresh),
                      label: Text(t.loadDetails),
                    ),
                  ],
                ]),
              ),
            MarkdownView(
              markdown: '## ${t.ingredientsH}\n'
                  '${r.ingredients.map((i) => '- ${i.name} — ${scaleAmount(i.amount, _factor)}${i.available ? '' : ' 🛒'}').join('\n')}\n'
                  '## ${t.cookingH}\n'
                  '${List.generate(r.steps.length, (i) => '${i + 1}. ${r.steps[i]}').join('\n')}',
              done: _done,
              onToggleStep: (i) => setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i)),
            ),
            if (r.tip != null && r.tip!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 18),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: extra.saffronBg, borderRadius: BorderRadius.circular(18)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡'),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.tip!)),
                ]),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            ListenableBuilder(
              listenable: favorites,
              builder: (context, _) {
                final saved = favorites.contains(r);
                return SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton.outlined(
                    tooltip: saved ? t.unsave : t.save,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_outline, color: saved ? extra.tomato : null),
                    onPressed: () async {
                      await favorites.toggle(r);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(saved ? t.removedFromSaved : t.saved)),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _loading ? null : _startCooking,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(t.startCooking),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({this.icon, required this.text});
  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 5)],
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// «2 порц.» з кнопками −/+: кількості в рецепті й у покупках перераховуються.
class _ServingsChip extends StatelessWidget {
  const _ServingsChip({required this.text, this.onMinus, this.onPlus});
  final String text;
  final VoidCallback? onMinus, onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget btn(IconData icon, VoidCallback? onTap) => InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: onTap == null ? theme.disabledColor : theme.colorScheme.onSurface),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.lime, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove, onMinus),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        btn(Icons.add, onPlus),
      ]),
    );
  }
}

/// «Сподобалось?» 👍 / 👎 — наступні підбори враховують смак.
class _VoteRow extends StatelessWidget {
  const _VoteRow({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final tastes = AppScope.of(context).tastes;
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return ListenableBuilder(
      listenable: tastes,
      builder: (context, _) {
        final vote = tastes.voteOf(title);
        Widget btn(bool up) {
          final on = vote == up;
          return IconButton(
            tooltip: up ? '👍' : '👎',
            isSelected: on,
            style: IconButton.styleFrom(
              backgroundColor: on ? (up ? extra.mintBg : extra.tomatoBg) : null,
            ),
            icon: Icon(
              up ? (on ? Icons.thumb_up : Icons.thumb_up_outlined) : (on ? Icons.thumb_down : Icons.thumb_down_outlined),
              color: on ? (up ? extra.mint : extra.tomato) : null,
            ),
            onPressed: () async {
              await tastes.vote(title, up);
              if (!context.mounted || tastes.voteOf(title) == null) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(up ? t.likedThanks : t.dislikedThanks)),
              );
            },
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Text(t.likeQuestion, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            btn(true),
            btn(false),
          ]),
        );
      },
    );
  }
}
