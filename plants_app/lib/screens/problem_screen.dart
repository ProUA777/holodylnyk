import 'package:flutter/material.dart';

import '../widgets/report_sheet.dart';
import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../markdown_view.dart';
import '../models.dart';
import '../theme.dart';

/// Покроковий план лікування однієї проблеми. Кроки можна відмічати пальцем.
class ProblemScreen extends StatefulWidget {
  const ProblemScreen({super.key, required this.plant, required this.problem, required this.params});
  final PlantResult plant;
  final Problem problem;
  final PlantParams params;

  @override
  State<ProblemScreen> createState() => _ProblemScreenState();
}

class _ProblemScreenState extends State<ProblemScreen> {
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
      final md = await api.detail(widget.plant, widget.problem, widget.params);
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
      appBar: AppBar(actions: [if (_md != null) ReportButton(content: () => _md ?? '')]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text('${widget.problem.emoji} ${widget.problem.title}', style: display(26)),
          const SizedBox(height: 6),
          Text(widget.plant.name, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
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
            Center(child: Text(t.planLoading, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ],
      ),
    );
  }
}
