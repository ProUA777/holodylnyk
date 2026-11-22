import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';

/// Картка образу: назва, речі (з кольоровими кружечками), чого бракує, чому працює, як носити, ♥.
class OutfitCard extends StatelessWidget {
  const OutfitCard({super.key, required this.outfit, this.known = const []});

  final Outfit outfit;

  /// Відомі речі (з фото або гардероба) — щоб показати їхній колір і тип
  final List<Item> known;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    Item? find(String name) {
      final n = name.toLowerCase();
      for (final i in known) {
        if (i.name.toLowerCase() == n) return i;
      }
      return null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(outfit.title, style: display(17))),
            ListenableBuilder(
              listenable: scope.looks,
              builder: (context, _) {
                final saved = scope.looks.isSaved(outfit);
                return IconButton(
                  tooltip: t.savedLook,
                  onPressed: () async {
                    await scope.looks.toggle(outfit);
                    if (!saved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.savedLook)));
                    }
                  },
                  icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? extra.coral : null),
                );
              },
            ),
          ]),
          Text(t.occasionLabels[outfit.occasion]!, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final name in outfit.items) _ItemChip(name: name, item: find(name)),
              for (final name in outfit.add)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: extra.coralBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: extra.coral.withValues(alpha: .5)),
                  ),
                  child: Text('+ ${t.addMissing}: $name',
                      style: TextStyle(color: extra.coral, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
            ]),
          ),
          if (outfit.why.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(outfit.why, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ),
          ],
          for (final tip in outfit.tips)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text('✨ $tip', style: theme.textTheme.bodySmall?.copyWith(color: extra.muted, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.name, this.item});
  final String name;
  final Item? item;

  @override
  Widget build(BuildContext context) {
    final extra = Extra.of(context);
    final swatch = item?.swatch;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (swatch != null)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: .15)),
            ),
          )
        else if (item != null)
          Padding(padding: const EdgeInsets.only(right: 4), child: Text(item!.emoji, style: const TextStyle(fontSize: 13))),
        Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
    );
  }
}

/// Кружечки палітри гардероба
class PaletteRow extends StatelessWidget {
  const PaletteRow({super.key, required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (final c in colors)
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: .12), width: 1.5),
            ),
          ),
      ]);
}

/// Шторка «Запитати стиліста»
Future<void> showAskSheet(BuildContext context, {List<String> items = const []}) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AskSheet(items: items),
    );

class _AskSheet extends StatefulWidget {
  const _AskSheet({required this.items});
  final List<String> items;

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  StyleAnswer? _answer;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _ctrl.text.trim();
    if (q.length < 2 || _busy) return;
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final a = await scope.api.ask(q, scope.prefs.value, items: widget.items);
      if (mounted) setState(() => _answer = a);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = t.error(e));
    } catch (_) {
      if (mounted) setState(() => _error = t.errGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(t.askTitle, style: display(20)),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              maxLength: 400,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: t.askHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _send,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.send),
              label: Text(t.ask),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700)),
            ],
            if (_answer != null) ...[
              const SizedBox(height: 16),
              Text(_answer!.answer, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
              for (final s in _answer!.tips)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('✨ $s', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}
