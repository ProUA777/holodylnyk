import 'package:flutter/material.dart';

import '../widgets/report_sheet.dart';
import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../markdown_view.dart';
import '../theme.dart';

/// «Пояснити тему»: коротко, як працює, приклад, типові помилки, що запам'ятати.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topic, required this.subject});
  final String topic;
  final String subject;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
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
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    setState(() {
      _md = null;
      _error = null;
    });
    try {
      final md = await scope.api.topic(widget.topic, widget.subject, scope.prefs.value);
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
    return Scaffold(
      appBar: AppBar(actions: [if (_md != null) ReportButton(content: () => _md ?? '')]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text('🎓 ${widget.topic}', style: display(26)),
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
            Center(child: Text(t.topicLoading, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ],
      ),
    );
  }
}
