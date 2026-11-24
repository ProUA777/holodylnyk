import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../markdown_view.dart';
import '../models.dart';
import '../theme.dart';

/// Покрокова інструкція ремонту для однієї причини. Кроки можна відмічати пальцем.
class CauseScreen extends StatefulWidget {
  const CauseScreen({super.key, required this.repair, required this.cause, required this.params});
  final RepairResult repair;
  final Cause cause;
  final RepairParams params;

  @override
  State<CauseScreen> createState() => _CauseScreenState();
}

class _CauseScreenState extends State<CauseScreen> {
  String? _md;
  String? _error;
  final _done = <int>{};
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final api = AppScope.of(context).api;
    final t = L10n.of(context);
    setState(() {
      _md = null;
      _error = null;
    });
    try {
      final md = await api.detail(widget.repair, widget.cause, widget.params);
      if (mounted) setState(() => _md = md);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = t.error(e));
    } catch (_) {
      if (mounted) setState(() => _error = t.errGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text('🔧 ${widget.cause.title}', style: display(26)),
          const SizedBox(height: 6),
          Text(widget.repair.thing, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          if (_md != null)
            MarkdownView(
              markdown: _md!,
              done: _done,
              onToggleStep: (i) => setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i)),
            )
          else if (_error != null) ...[
            Text(_error!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(t.retry)),
          ] else ...[
            const SizedBox(height: 40),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Center(child: Text(t.guideLoading, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ],
      ),
    );
  }
}
