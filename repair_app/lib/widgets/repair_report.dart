import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../screens/cause_screen.dart';
import '../theme.dart';

/// Звіт про поломку: безпека, що зробити перед початком, причини, інструменти й деталі, ціна майстра.
class RepairReport extends StatelessWidget {
  const RepairReport({super.key, required this.repair, this.bought, this.onToggleBought});

  final RepairResult repair;

  /// Для збереженого ремонту — відмітки «вже є»
  final Set<String>? bought;
  final ValueChanged<String>? onToggleBought;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    final r = repair;
    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 10),
          child: Text(title, style: display(19)),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (r.brandModel != null && r.brandModel!.isNotEmpty)
        Text(r.brandModel!, style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      SafetyBanner(safety: r.safety, note: r.safetyNote),
      if (r.summary.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(r.summary, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
      ],
      if (r.signs.isNotEmpty) ...[
        const SizedBox(height: 10),
        for (final s in r.signs) Text('👀 $s', style: theme.textTheme.bodyMedium?.copyWith(color: extra.muted)),
      ],
      if (r.causes.isNotEmpty) ...[
        section(t.causesTitle),
        for (var i = 0; i < r.causes.length; i++)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: CauseCard(repair: r, cause: r.causes[i], top: i == 0)),
      ],
      if (r.parts.isNotEmpty) ...[
        section(t.toBuy),
        _PartsList(title: '🧰 ${t.toolsTitle}', parts: r.tools, bought: bought, onToggle: onToggleBought),
        _PartsList(title: '🔩 ${t.partsTitle}', parts: r.spares, bought: bought, onToggle: onToggleBought),
      ],
      if (r.proCost != null && r.proCost!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: extra.blueBg, borderRadius: BorderRadius.circular(16)),
          child: Text('👷 ${t.proCost}: ${r.proCost}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ]);
  }
}

class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key, required this.safety, required this.note});
  final Safety safety;
  final String note;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (emoji, bg, fg) = switch (safety) {
      Safety.diy => ('✅', dark ? AppColors.greenBgDark : AppColors.greenBg, AppColors.green),
      Safety.careful => ('⚠️', extra.amberBg, AppColors.amber),
      Safety.pro => ('⛔', extra.redBg, extra.red),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: fg, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$emoji ${t.safetyLabels[safety]}', style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 16)),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('${t.beforeStart}: $note', style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
        ],
      ]),
    );
  }
}

class CauseCard extends StatelessWidget {
  const CauseCard({super.key, required this.repair, required this.cause, this.top = false});
  final RepairResult repair;
  final Cause cause;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    final c = cause;
    return Card(
      shape: top
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.orange, width: 2))
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(c.title, style: display(16))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: top ? AppColors.orange : extra.leaf, borderRadius: BorderRadius.circular(999)),
              child: Text(t.likely(c.likelihood),
                  style: TextStyle(fontWeight: FontWeight.w900, color: top ? AppColors.ink : null)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('⏱ ${t.minutes(c.minutes)} · ${t.difficultyLabels[c.difficulty]}',
              style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700, fontSize: 13)),
          if (c.why.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(c.why, style: theme.textTheme.bodyMedium),
          ],
          if (c.check.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('🔎 ${t.howToCheck}: ${c.check}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
          if (c.fix.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(t.howToFix, style: const TextStyle(fontWeight: FontWeight.w800)),
            for (var i = 0; i < c.fix.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 22,
                    child: Text('${i + 1}.', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                  ),
                  Expanded(child: Text(c.fix[i], style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))),
                ]),
              ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CauseScreen(repair: repair, cause: c, params: AppScope.of(context).prefs.value),
              )),
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              label: Text(t.fullGuide, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PartsList extends StatelessWidget {
  const _PartsList({required this.title, required this.parts, this.bought, this.onToggle});
  final String title;
  final List<Part> parts;
  final Set<String>? bought;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    final extra = Extra.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        for (final p in parts)
          bought == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    const Text('•  '),
                    Expanded(child: Text(p.name)),
                    if (p.price != null) Text(p.price!, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
                  ]),
                )
              : CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: bought!.contains(p.name),
                  onChanged: (_) => onToggle?.call(p.name),
                  title: Text(p.name,
                      style: TextStyle(decoration: bought!.contains(p.name) ? TextDecoration.lineThrough : null)),
                  secondary: p.price == null ? null : Text(p.price!, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
                ),
      ]),
    );
  }
}

/// Шторка «Запитати майстра»
Future<void> showAskSheet(BuildContext context, RepairResult repair) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AskSheet(repair: repair),
    );

class _AskSheet extends StatefulWidget {
  const _AskSheet({required this.repair});
  final RepairResult repair;

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  RepairAnswer? _answer;
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
      final a = await scope.api.ask(widget.repair, q, scope.prefs.value);
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
            const SizedBox(height: 4),
            Text(widget.repair.thing, style: TextStyle(color: Extra.of(context).muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              maxLength: 400,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(hintText: t.askHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
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
              for (final s in _answer!.steps)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text('✓  $s', style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ]),
        ),
      ),
    );
  }
}
