import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/report_sheet.dart';
import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/solution_card.dart';

/// Фото (або вписана умова) → розбір кожного завдання: підказки, кроки, відповідь, перевірка, схоже завдання.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.images, this.tasks = const [], this.studentWork = const [], this.saved});
  final List<File> images;

  /// Без фото: умови (і розв'язки учня для перевірки)
  final List<String> tasks;
  final List<String?> studentWork;

  /// Відкрити вже розібране з «Моїх завдань»
  final HomeworkResult? saved;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  HomeworkResult? _result;
  String? _error;
  bool _busy = true;
  int _step = 0;
  Timer? _ticker;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.saved != null) {
      _result = widget.saved;
      _busy = false;
    } else {
      _analyze();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<HomeworkResult> Function() call) async {
    final t = L10n.of(context);
    final history = AppScope.of(context).history;
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
      final r = await call();
      if (r.solutions.isEmpty) throw ApiException('nothing_recognized');
      await history.add(r);
      if (mounted) setState(() => _result = r);
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
    if (widget.images.isEmpty) {
      _run(() => scope.api.refine(widget.tasks, scope.prefs.value, studentWork: widget.studentWork));
    } else {
      _run(() => scope.api.analyze(widget.images, scope.prefs.value));
    }
  }

  /// Розпізнана умова з помилкою — виправити й розібрати ще раз (без нового фото)
  Future<void> _edit() async {
    final t = L10n.of(context);
    final r = _result!;
    final ctrls = [for (final s in r.solutions) TextEditingController(text: s.task)];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.editTask),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final c in ctrls) TextField(controller: c, minLines: 2, maxLines: 8, maxLength: 1500),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.solve)),
        ],
      ),
    );
    final tasks = [for (final c in ctrls) c.text.trim()].where((x) => x.length >= 2).toList();
    for (final c in ctrls) {
      c.dispose();
    }
    if (ok != true || tasks.isEmpty || !mounted) return;
    final scope = AppScope.of(context);
    _run(() => scope.api.refine(tasks, scope.prefs.value, subject: r.subject));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        title: r == null || _busy ? null : Text('${r.emoji} ${t.tasksN(r.solutions.length)}'),
        actions: [
          if (r != null && !_busy) ReportButton(content: () => jsonEncode(r.toJson())),
          if (r != null && !_busy) IconButton(tooltip: t.editTask, onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: _busy
          ? _Loading(images: widget.images, step: _step)
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _analyze)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    if (!r!.readable)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: extra.amberBg, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Expanded(child: Text('⚠️ ${t.unreadable}', style: const TextStyle(fontWeight: FontWeight.w700))),
                          TextButton(onPressed: _edit, child: Text(t.editTask)),
                        ]),
                      ),
                    for (final s in r.solutions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SolutionCard(solution: s, subject: r.subject),
                      ),
                  ],
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
                    ? const Icon(Icons.check_circle, color: AppColors.ocean)
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

/// Блакитна лінія, що бігає по фото, поки AI дивиться
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
            color: AppColors.sky,
            boxShadow: [BoxShadow(color: AppColors.sky.withValues(alpha: 0.7), blurRadius: 16, spreadRadius: 2)],
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
          const Text('📝', style: TextStyle(fontSize: 56)),
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
