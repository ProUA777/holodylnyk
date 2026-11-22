import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/plant_report.dart';

/// Фото → (сервер) → звіт про рослину. Тут же: «це інша рослина», «запитати», «додати до моїх рослин».
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.images});
  final List<File> images;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  PlantResult? _plant;
  String? _error;
  bool _busy = true;
  bool _saved = false;
  int _step = 0;
  Timer? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_plant == null && _error == null && _ticker == null) _analyze();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _step = 0;
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _step++);
    });
  }

  Future<void> _run(Future<PlantResult> Function() call) async {
    final t = L10n.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    _startTicker();
    try {
      final r = await call();
      if (mounted) setState(() => _plant = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = t.error(e));
    } catch (_) {
      if (mounted) setState(() => _error = t.errGeneric);
    } finally {
      _ticker?.cancel();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _analyze() {
    final scope = AppScope.of(context);
    _run(() => scope.api.analyze(widget.images, scope.prefs.value));
  }

  /// Людина обрала інший вид — діагноз і догляд під нього, з тими самими ознаками з фото
  void _switchTo(Alternative a) {
    final scope = AppScope.of(context);
    final old = _plant!;
    _run(() async {
      final r = await scope.api.refine(a.name, scope.prefs.value, latin: a.latin, symptoms: old.symptoms);
      return PlantResult.fromJson({
        ...r.toJson(),
        'confidence': 1.0,
        'symptoms': old.symptoms,
        'alternatives': const [],
      });
    });
  }

  Future<void> _save() async {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    await scope.garden.add(_plant!, photo: widget.images.isEmpty ? null : widget.images.first);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.addedToGarden)));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final plant = _plant;
    return Scaffold(
      appBar: AppBar(title: plant == null || _busy ? null : Text(plant.name)),
      body: _busy
          ? _Loading(images: widget.images, step: _step)
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _analyze)
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
                    const SizedBox(height: 16),
                    Text(plant!.name, style: display(28)),
                    PlantReport(plant: plant, onPickAlternative: _switchTo),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => showAskSheet(context, plant),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(t.askTitle),
                    ),
                  ],
                ),
      bottomNavigationBar: plant == null || _busy || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: _saved ? () => Shell.openGarden(context) : _save,
                  icon: Icon(_saved ? Icons.arrow_forward : Icons.local_florist_outlined),
                  label: Text(_saved ? t.navGarden : t.addToGarden),
                ),
              ),
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
    final steps = t.loadingSteps;
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
                    ? const Icon(Icons.check_circle, color: AppColors.forest)
                    : i == step.clamp(0, steps.length - 1)
                        ? const CircularProgressIndicator(strokeWidth: 2.5)
                        : Icon(Icons.circle_outlined, color: extra.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(steps[i],
                    style: TextStyle(fontWeight: FontWeight.w700, color: i <= step ? null : extra.muted)),
              ),
            ]),
          ),
      ],
    );
  }
}

/// Лайм-лінія, що бігає по фото, поки AI дивиться
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
            color: AppColors.sprout,
            boxShadow: [BoxShadow(color: AppColors.sprout.withValues(alpha: 0.7), blurRadius: 16, spreadRadius: 2)],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🥀', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(t.retry)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(t.otherPhoto),
          ),
        ]),
      ),
    );
  }
}
