import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../data/catalog.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'shell.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  String _cat = 'all', _diff = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BrickModel> get _list {
    final q = _search.text.trim().toLowerCase();
    return catalog.models.where((m) {
      if (_cat == 'fav' && !app.isFavorite(m.id)) return false;
      if (_cat != 'all' && _cat != 'fav' && m.cat != _cat) return false;
      if (_diff != 'all' && m.diff != _diff) return false;
      if (q.isEmpty) return true;
      final hay = [...m.title.values, ...m.desc.values, ...?catalog.categories[m.cat]?.values].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final list = _list;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) => CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            sliver: SliverList.list(children: [
              const TopBar(),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: Text(t('catalogH'), style: display(30))),
                IconButton.filledTonal(
                  tooltip: t('random'),
                  style: IconButton.styleFrom(backgroundColor: p.card),
                  onPressed: list.isEmpty
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          openModel(context, list[Random().nextInt(list.length)]);
                        },
                  icon: const Text('🎲', style: TextStyle(fontSize: 20)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${count(catalog.models.length, 'models')} · ${t('catalogP')}', style: body(14.5, color: p.muted)),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: body(16, weight: 700),
                decoration: InputDecoration(
                  hintText: t('search'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_search.clear)),
                  filled: true,
                  fillColor: p.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line, width: 2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line, width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Brand.blue, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              _Chips(
                values: ['all', 'fav', ...catalog.categories.keys],
                selected: _cat,
                label: (k) => k == 'all' ? t('all') : k == 'fav' ? '❤ ${t('favorites')}' : pick(catalog.categories[k]!, app.lang),
                onSelect: (k) => setState(() => _cat = k),
              ),
              const SizedBox(height: 8),
              _Chips(
                values: const ['all', 'easy', 'medium', 'hard', 'expert'],
                selected: _diff,
                small: true,
                label: (k) => k == 'all' ? t('anyDiff') : t(k),
                onSelect: (k) => setState(() => _diff = k),
              ),
              if (_cat != 'all' || _diff != 'all' || _search.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(count(list.length, 'models'), style: body(13, weight: 800, color: p.muted)),
              ],
            ]),
          ),
          if (list.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SurfaceCard(
                  child: Padding(padding: const EdgeInsets.all(12), child: Text(_cat == 'fav' && app.favorites.isEmpty ? t('noFav') : t('noFound'), textAlign: TextAlign.center, style: body(15, color: p.muted))),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              // Built lazily: only the cards on screen are laid out and painted.
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 232,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) => IdeaCard.model(list[i], onTap: () => openModel(context, list[i])),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  final List<String> values;
  final String selected;
  final String Function(String) label;
  final ValueChanged<String> onSelect;
  final bool small;

  const _Chips({required this.values, required this.selected, required this.label, required this.onSelect, this.small = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SizedBox(
      height: small ? 36 : 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final v = values[i], on = v == selected;
          return Semantics(
            selected: on,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => onSelect(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: small ? 12 : 14),
                decoration: BoxDecoration(
                  color: on ? p.ink : p.card,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: on ? p.ink : p.line, width: 2),
                ),
                child: Text(label(v), style: body(small ? 13 : 14, weight: 800, color: on ? p.plate : p.muted)),
              ),
            ),
          );
        },
      ),
    );
  }
}
