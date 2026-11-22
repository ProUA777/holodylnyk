import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../screens/problem_screen.dart';
import '../theme.dart';

/// Звіт про рослину: стан, що зробити зараз, проблеми, догляд, отруйність, цікавий факт.
/// Однаковий на екрані результату й у «Моїх рослинах».
class PlantReport extends StatelessWidget {
  const PlantReport({super.key, required this.plant, this.onPickAlternative});

  final PlantResult plant;

  /// Людина каже «це інша рослина» — перерахувати без фото
  final ValueChanged<Alternative>? onPickAlternative;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    final p = plant;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 10),
          child: Text(title, style: display(19)),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (p.latin != null || p.family != null)
        Text([p.latin, p.family].whereType<String>().join(' · '),
            style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted, fontStyle: FontStyle.italic)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        HealthBadge(health: p.health),
        _Pill(text: '🎯 ${t.confidence(p.confidence)}', color: extra.leaf),
      ]),
      if (p.healthSummary.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(p.healthSummary, style: theme.textTheme.bodyLarge),
      ],
      if (p.alternatives.isNotEmpty && (p.unsure || onPickAlternative != null)) ...[
        const SizedBox(height: 16),
        Text(t.maybeItIs, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.alternatives
              .map((a) => ActionChip(
                    avatar: const Icon(Icons.swap_horiz, size: 18),
                    label: Text(a.name),
                    onPressed: onPickAlternative == null ? null : () => onPickAlternative!(a),
                  ))
              .toList(),
        ),
      ],
      if (p.todoNow.isNotEmpty) ...[
        section(t.todoTitle),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          decoration: BoxDecoration(color: AppColors.sprout, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            for (var i = 0; i < p.todoNow.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: display(12, color: AppColors.sprout)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p.todoNow[i],
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15, height: 1.35)),
                  ),
                ]),
              ),
          ]),
        ),
      ],
      section(t.problemsTitle),
      if (p.problems.isEmpty)
        Text('🌿 ${t.noProblems}', style: theme.textTheme.bodyLarge)
      else
        for (final pr in p.problems) Padding(padding: const EdgeInsets.only(bottom: 10), child: ProblemCard(plant: p, problem: pr)),
      section(t.careTitle),
      CareGrid(care: p.care),
      const SizedBox(height: 14),
      _ToxicityNote(toxicity: p.toxicity),
      if (p.funFact != null && p.funFact!.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: extra.sunBg, borderRadius: BorderRadius.circular(18)),
          child: Text('💡 ${t.funFact}: ${p.funFact}', style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ),
      ],
    ]);
  }
}

class HealthBadge extends StatelessWidget {
  const HealthBadge({super.key, required this.health});
  final Health health;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final (emoji, bg) = switch (health) {
      Health.healthy => ('💚', extra.leaf),
      Health.needsAttention => ('⚠️', extra.sunBg),
      Health.sick => ('🚑', extra.clayBg),
    };
    return _Pill(text: '$emoji ${t.healthLabels[health]}', color: bg);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );
}

/// Картка проблеми: що видно, чому, що зробити зараз, і кнопка на повний план лікування.
class ProblemCard extends StatelessWidget {
  const ProblemCard({super.key, required this.plant, required this.problem});
  final PlantResult plant;
  final Problem problem;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    final pr = problem;
    final sevColor = switch (pr.severity) {
      Severity.high => extra.clay,
      Severity.medium => AppColors.sun,
      Severity.low => extra.muted,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(pr.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Text(pr.title, style: display(16))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: sevColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(t.severityLabels[pr.severity]!, style: TextStyle(color: sevColor, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
          if (pr.signs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('👀 ${pr.signs}', style: theme.textTheme.bodyMedium),
          ],
          if (pr.why.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(pr.why, style: theme.textTheme.bodyMedium?.copyWith(color: extra.muted)),
          ],
          if (pr.fixNow.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(t.howToFix, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            for (final s in pr.fixNow)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                  Expanded(child: Text(s, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))),
                ]),
              ),
          ],
          if (pr.prevention != null && pr.prevention!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('🛡️ ${t.prevention}: ${pr.prevention}', style: theme.textTheme.bodySmall?.copyWith(color: extra.muted)),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProblemScreen(plant: plant, problem: pr, params: AppScope.of(context).prefs.value),
              )),
              icon: const Icon(Icons.healing_outlined, size: 20),
              label: Text(t.fullPlan, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Догляд плитками: світло, полив, вологість, температура, ґрунт, підживлення, пересадка, обрізка.
class CareGrid extends StatelessWidget {
  const CareGrid({super.key, required this.care, this.everyDaysOverride});
  final Care care;
  final int? everyDaysOverride;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final every = everyDaysOverride ?? care.waterEveryDays;
    final items = <(String, String, String, Color)>[
      ('☀️', t.careLight, care.light, extra.sunBg),
      ('💧', t.careWatering, [t.everyDays(every), care.watering].where((s) => s.isNotEmpty).join('. '), extra.waterBg),
      ('💨', t.careHumidity, care.humidity, extra.leaf),
      ('🌡️', t.careTemperature, care.temperature, extra.clayBg),
      ('🪴', t.careSoil, care.soil, extra.leaf),
      ('🧪', t.careFertilizer, care.fertilizer, extra.leaf),
      ('🔁', t.careRepotting, care.repotting, extra.leaf),
      if (care.pruning != null && care.pruning!.isNotEmpty) ('✂️', t.carePruning, care.pruning!, extra.leaf),
    ].where((e) => e.$3.trim().isNotEmpty).toList();
    return Column(
      children: [
        for (final (emoji, title, text, bg) in items)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(text, style: const TextStyle(height: 1.35)),
                ]),
              ),
            ]),
          ),
      ],
    );
  }
}

class _ToxicityNote extends StatelessWidget {
  const _ToxicityNote({required this.toxicity});
  final Toxicity toxicity;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    if (toxicity.pets == null && toxicity.kids == null) return const SizedBox.shrink();
    final toxic = toxicity.isToxic;
    final who = [if (toxicity.pets == true) t.toxicPets, if (toxicity.kids == true) t.toxicKids].join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: toxic ? extra.clayBg : extra.leaf,
        borderRadius: BorderRadius.circular(18),
        border: toxic ? Border.all(color: extra.clay, width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(toxic ? '☠️ ${t.toxicTitle} $who' : '✅ ${t.safeTitle}',
            style: TextStyle(fontWeight: FontWeight.w800, color: toxic ? extra.clay : null)),
        if (toxicity.note != null && toxicity.note!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(toxicity.note!),
        ],
      ]),
    );
  }
}

/// Шторка «Запитати про цю рослину»: питання → коротка відповідь і кроки.
Future<void> showAskSheet(BuildContext context, PlantResult plant) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _AskSheet(plant: plant),
  );
}

class _AskSheet extends StatefulWidget {
  const _AskSheet({required this.plant});
  final PlantResult plant;

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  PlantAnswer? _answer;
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
      final a = await scope.api.ask(widget.plant.name, q, scope.prefs.value,
          latin: widget.plant.latin, problems: widget.plant.problems.map((p) => p.title).toList());
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
            Text(widget.plant.name, style: TextStyle(color: Extra.of(context).muted, fontWeight: FontWeight.w700)),
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
              for (final s in _answer!.steps)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('✓  $s', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}
