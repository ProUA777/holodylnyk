import 'dart:io';

import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import 'recipe_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.images, required this.params});

  /// порожньо — ручний режим: користувач сам вписує продукти
  final List<File> images;
  final RecipeParams params;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final List<String> _ingredients = [];
  final List<Recipe> _recipes = [];
  final _addCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingMore = false;
  bool _dirty = false; // список продуктів змінено → можна оновити рецепти
  bool _adding = false;
  String? _filter; // тип страви, null — усі
  ApiException? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.images.isNotEmpty) {
      _analyze();
    } else {
      _adding = true;
    }
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  EngineClient get _api => AppScope.of(context).api;

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.analyze(widget.images, widget.params);
      if (!mounted) return;
      setState(() {
        _filter = null;
        _ingredients
          ..clear()
          ..addAll(res.ingredients.map((i) => i.name));
        _recipes
          ..clear()
          ..addAll(res.recipes);
        _dirty = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refine({bool more = false}) async {
    if (_ingredients.isEmpty) return;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _adding = false;
      }
      _error = null;
    });
    try {
      final res = await _api.refine(
        _ingredients,
        widget.params,
        excludeTitles: more ? _recipes.map((r) => r.title).toList() : const [],
      );
      if (!mounted) return;
      final known = _recipes.map((r) => r.title.toLowerCase()).toSet();
      final fresh = res.recipes.where((r) => !known.contains(r.title.toLowerCase())).toList();
      setState(() {
        if (!more) {
          _recipes.clear();
          _filter = null;
        }
        _recipes.addAll(more ? fresh : res.recipes);
        _dirty = false;
      });
      if (more) {
        final t = L10n.of(context);
        _snack(fresh.isEmpty ? t.noMoreIdeas : t.added(fresh.length));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (more || _recipes.isNotEmpty) {
        _snack(L10n.of(context).error(e));
      } else {
        setState(() => _error = e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _submitAdd() {
    final v = _addCtrl.text.trim();
    _addCtrl.clear();
    if (v.isEmpty) {
      setState(() => _adding = false);
      return;
    }
    if (_ingredients.any((x) => x.toLowerCase() == v.toLowerCase())) return;
    setState(() {
      _ingredients.add(v);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(top: false, child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final t = L10n.of(context);
    final hasPhotos = widget.images.isNotEmpty;

    if (_loading && _recipes.isEmpty) {
      final first = hasPhotos && _ingredients.isEmpty;
      return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
        _ScanPreview(images: widget.images),
        const SizedBox(height: 22),
        Text(first ? t.scanTitle : t.pickTitle, style: display(20)),
        const SizedBox(height: 6),
        Text(
          first ? t.scanText : t.pickText,
          style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted),
        ),
      ]);
    }

    if (_error != null && _recipes.isEmpty) {
      final nothing = _error!.code == 'nothing_recognized' || _error!.code == 'bad_image';
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(24)),
            alignment: Alignment.center,
            child: Text(nothing ? '🔍' : '⚠️', style: const TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        Text(t.error(_error!), textAlign: TextAlign.center, style: display(20)),
        const SizedBox(height: 22),
        if (nothing)
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(t.otherPhoto),
          )
        else if (_error!.code != 'daily_limit')
          FilledButton.icon(
            onPressed: hasPhotos && _ingredients.isEmpty ? _analyze : () => _refine(),
            icon: const Icon(Icons.refresh),
            label: Text(t.tryAgain),
          ),
      ]);
    }

    final types = <String>{for (final r in _recipes) r.mealType}.toList();
    final shown = _recipes.where((r) => _filter == null || r.mealType == _filter).toList();
    final n = _ingredients.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Row(children: [
          if (hasPhotos) ...[
            _PhotoStack(images: widget.images),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hasPhotos ? t.foundProducts(n) : t.myProducts, style: display(22)),
              const SizedBox(height: 2),
              Text(
                hasPhotos ? t.removeHint : t.addAllYouHave,
                style: theme.textTheme.bodyMedium?.copyWith(color: extra.muted),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._ingredients.map((name) => InputChip(
                  label: Text(name),
                  onDeleted: () => setState(() {
                    _ingredients.remove(name);
                    _dirty = true;
                  }),
                  deleteButtonTooltipMessage: t.remove,
                )),
            ActionChip(
              avatar: Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
              label: Text(t.add, style: TextStyle(color: theme.colorScheme.primary)),
              onPressed: () => setState(() => _adding = true),
            ),
          ],
        ),
        if (_adding) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _addCtrl,
                autofocus: true,
                maxLength: 60,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitAdd(),
                decoration: InputDecoration(
                  hintText: t.productHint,
                  counterText: '',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(80, 52)),
                onPressed: _submitAdd,
                child: Text(t.add),
              ),
            ),
          ]),
        ],
        if (_dirty || (_recipes.isEmpty && _ingredients.isNotEmpty)) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading || _ingredients.isEmpty ? null : () => _refine(),
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            label: Text(_recipes.isEmpty ? t.pickRecipes : t.updateRecipes),
          ),
        ],
        if (_recipes.isEmpty && _ingredients.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Text(t.emptyManual,
                textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
          ),
        if (_recipes.isNotEmpty) ...[
          const SizedBox(height: 26),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(t.canCook, style: display(18))),
            Text(t.dishes(_recipes.length), style: theme.textTheme.bodySmall?.copyWith(color: extra.muted)),
          ]),
          const SizedBox(height: 12),
          if (types.length > 1) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [null, ...types]
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(m == null ? t.all : '${mealTypeEmoji[m] ?? ''} ${t.mealTypeLabels[m] ?? m}'),
                            side: BorderSide(
                              color: m == null || _filter == m ? theme.colorScheme.outline : mealColor(m),
                              width: 1.5,
                            ),
                            selected: _filter == m,
                            onSelected: (_) => setState(() => _filter = m),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...shown.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RecipeCard(
                  recipe: r,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RecipeScreen(recipe: r, params: widget.params),
                  )),
                ),
              )),
          if (_ingredients.isNotEmpty) ...[
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _loadingMore || _loading ? null : () => _refine(more: true),
              icon: _loadingMore
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_loadingMore ? t.searchingMore : t.moreRecipes),
            ),
          ],
        ],
      ],
    );
  }
}

/// Картка страви: емодзі типу, назва, опис, час, складність, «все є / докупити».
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap});
  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final t = L10n.of(context);
    final missing = recipe.missingCount;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EmojiTile(emoji: recipe.emoji, color: mealColor(recipe.mealType)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 3),
                Text(recipe.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: extra.muted)),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Fact(icon: Icons.schedule, text: t.minutes(recipe.timeMinutes)),
                  Fact(text: t.difficultyLabels[recipe.difficulty] ?? recipe.difficulty),
                  if (recipe.cuisine != null) Fact(text: recipe.cuisine!),
                  missing == 0
                      ? Fact(icon: Icons.check, text: t.allAtHome, fg: extra.mint, bg: extra.mintBg)
                      : Fact(icon: Icons.shopping_cart_outlined, text: t.toBuy(missing), fg: extra.tomato, bg: extra.tomatoBg),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Мініатюри кількох фото віялом.
class _PhotoStack extends StatelessWidget {
  const _PhotoStack({required this.images});
  final List<File> images;

  @override
  Widget build(BuildContext context) {
    final shown = images.take(3).toList();
    return SizedBox(
      width: 72 + (shown.length - 1) * 14,
      height: 76,
      child: Stack(children: [
        for (var i = shown.length - 1; i >= 0; i--)
          Positioned(
            left: i * 14.0,
            top: 2,
            child: Transform.rotate(
              angle: (i - (shown.length - 1) / 2) * 0.08,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(shown[i], width: 68, height: 68, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Яскрава «наліпка» з емодзі в кольорі типу страви, трохи повернута.
class EmojiTile extends StatelessWidget {
  const EmojiTile({super.key, required this.emoji, this.color, this.size = 58});
  final String emoji;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -0.07,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color ?? AppColors.lime, borderRadius: BorderRadius.circular(size * 0.31)),
          child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
        ),
      );
}

class Fact extends StatelessWidget {
  const Fact({super.key, this.icon, required this.text, this.fg, this.bg});
  final IconData? icon;
  final String text;
  final Color? fg, bg;

  @override
  Widget build(BuildContext context) {
    final color = fg ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg ?? Extra.of(context).leaf, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

/// Фото зі «скануючою» лінією, поки AI роздивляється продукти.
class _ScanPreview extends StatefulWidget {
  const _ScanPreview({required this.images});
  final List<File> images;

  @override
  State<_ScanPreview> createState() => _ScanPreviewState();
}

class _ScanPreviewState extends State<_ScanPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    const beam = AppColors.lime; // колір скануючої лінії
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: LayoutBuilder(builder: (context, box) {
          return Stack(fit: StackFit.expand, children: [
            widget.images.isNotEmpty
                ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final img in widget.images) Expanded(child: Image.file(img, fit: BoxFit.cover)),
                  ])
                : Container(
                    color: Extra.of(context).leaf,
                    child: Icon(Icons.soup_kitchen_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                  ),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = reduce ? 0.45 : Curves.easeInOut.transform(_c.value);
                return Positioned(
                  left: 0,
                  right: 0,
                  top: -90 + (box.maxHeight + 90) * t,
                  height: 90,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [beam.withValues(alpha: 0), beam.withValues(alpha: 0.7)],
                      ),
                      border: const Border(bottom: BorderSide(color: beam, width: 3)),
                    ),
                  ),
                );
              },
            ),
          ]);
        }),
      ),
    );
  }
}
