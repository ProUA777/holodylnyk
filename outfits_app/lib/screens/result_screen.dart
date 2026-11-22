import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/outfit_card.dart';

/// Фото (або гардероб без фото) → образи. Тут же: оцінка образу, «ще образи», «додати речі до гардероба».
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.images});

  /// Порожній список — образи з речей, що вже є в гардеробі
  final List<File> images;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  OutfitResult? _result;
  final List<Outfit> _outfits = [];
  String? _error;
  bool _busy = true;
  bool _more = false;
  int _step = 0;
  Timer? _ticker;
  bool _started = false;

  bool get _fromWardrobe => widget.images.isEmpty;

  /// Речі, з яких складаються образи: з фото або з гардероба
  List<Item> get _known => _fromWardrobe ? AppScope.of(context).wardrobe.items : (_result?.items ?? const []);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _step = 0;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _step++);
    });
    try {
      final r = _fromWardrobe
          ? await scope.api.refine(scope.wardrobe.items, scope.prefs.value)
          : await scope.api.analyze(widget.images, scope.prefs.value);
      if (mounted) {
        setState(() {
          _result = r;
          _outfits
            ..clear()
            ..addAll(r.outfits);
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = t.error(e));
    } catch (_) {
      if (mounted) setState(() => _error = t.errGeneric);
    } finally {
      _ticker?.cancel();
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ще образи з тих самих речей — без нового фото, без повторів
  Future<void> _loadMore() async {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    setState(() => _more = true);
    try {
      final r = await scope.api.refine(_known, scope.prefs.value, excludeTitles: _outfits.map((o) => o.title).toList());
      if (mounted) setState(() => _outfits.addAll(r.outfits.where((o) => !_outfits.any((x) => x.key == o.key))));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.error(e))));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.errGeneric)));
    } finally {
      if (mounted) setState(() => _more = false);
    }
  }

  Future<void> _addToWardrobe() async {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final n = await scope.wardrobe.addAll(_result!.items);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.addedN(n))));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (r != null && !_busy)
            IconButton(
              tooltip: t.askTitle,
              onPressed: () => showAskSheet(context, items: _known.map((i) => i.name).toList()),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
        ],
      ),
      body: _busy
          ? _Loading(images: widget.images, step: _step)
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load, canRetake: !_fromWardrobe)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    if (widget.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.file(widget.images.first, fit: BoxFit.cover, cacheWidth: 1000),
                        ),
                      ),
                    if (r!.verdict != null) ...[
                      const SizedBox(height: 16),
                      _VerdictCard(verdict: r.verdict!),
                    ],
                    if (r.palette.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(t.paletteTitle, style: display(17)),
                      const SizedBox(height: 10),
                      PaletteRow(colors: r.palette),
                    ],
                    if (!_fromWardrobe && r.items.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text('${t.itemsTitle} · ${t.itemsN(r.items.length)}', style: display(17)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final i in r.items) Chip(avatar: Text(i.emoji), label: Text(i.name)),
                      ]),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addToWardrobe,
                        icon: const Icon(Icons.checkroom),
                        label: Text(t.addToWardrobe),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(t.looksTitle, style: display(22)),
                    const SizedBox(height: 12),
                    for (final o in _outfits)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: OutfitCard(outfit: o, known: _known)),
                    OutlinedButton.icon(
                      onPressed: _more ? null : _loadMore,
                      icon: _more
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Icon(Icons.auto_awesome),
                      label: Text(t.moreLooks),
                    ),
                    if (r.shopping.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: extra.sunBg, borderRadius: BorderRadius.circular(20)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('🛍️ ${t.shoppingTitle}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          for (final s in r.shopping)
                            Padding(padding: const EdgeInsets.only(top: 4), child: Text('•  $s')),
                        ]),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});
  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.mustard, borderRadius: BorderRadius.circular(22)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.ink),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(t.verdictTitle, style: display(18, color: AppColors.ink))),
            Text(t.score(verdict.score), style: display(30, color: AppColors.ink)),
          ]),
          if (verdict.good.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('👍 ${t.good}', style: const TextStyle(fontWeight: FontWeight.w800)),
            for (final s in verdict.good) Text('•  $s', style: const TextStyle(height: 1.4)),
          ],
          if (verdict.change.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('✏️ ${t.change}', style: const TextStyle(fontWeight: FontWeight.w800)),
            for (final s in verdict.change) Text('•  $s', style: const TextStyle(height: 1.4)),
          ],
        ]),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.images, required this.step});
  final List<File> images;
  final int step;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final steps = images.isEmpty ? t.loadingSteps.sublist(1) : t.loadingSteps;
    final extra = Extra.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (images.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(children: [
              AspectRatio(aspectRatio: 4 / 3, child: Image.file(images.first, fit: BoxFit.cover, cacheWidth: 1000)),
              const Positioned.fill(child: _ScanLine()),
            ]),
          ),
        const SizedBox(height: 24),
        Text(t.loadingTitle, style: display(22)),
        const SizedBox(height: 14),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 24,
                height: 24,
                child: i < step
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : i == step.clamp(0, steps.length - 1)
                        ? const CircularProgressIndicator(strokeWidth: 2.5)
                        : Icon(Icons.circle_outlined, color: extra.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(steps[i], style: TextStyle(fontWeight: FontWeight.w700, color: i <= step ? null : extra.muted)),
              ),
            ]),
          ),
      ],
    );
  }
}

/// Гірчична лінія, що бігає по фото, поки AI дивиться
class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Align(
        alignment: Alignment(0, -1 + 2 * Curves.easeInOut.transform(_c.value)),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.mustard,
            boxShadow: [BoxShadow(color: AppColors.mustard.withValues(alpha: 0.7), blurRadius: 16, spreadRadius: 2)],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry, required this.canRetake});
  final String message;
  final VoidCallback onRetry;
  final bool canRetake;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🧦', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(t.retry)),
          if (canRetake) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(t.otherPhoto),
            ),
          ],
        ]),
      ),
    );
  }
}
