import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../screens/topic_screen.dart';
import '../theme.dart';

/// Розбір одного завдання. Головне — не видати відповідь одразу:
/// ідея → підказки по одній → кроки → відповідь. У режимі перевірки — спершу оцінка й помилки.
class SolutionCard extends StatefulWidget {
  const SolutionCard({super.key, required this.solution, required this.subject});
  final Solution solution;
  final String subject;

  @override
  State<SolutionCard> createState() => _SolutionCardState();
}

class _SolutionCardState extends State<SolutionCard> {
  int _hints = 0; // скільки підказок відкрито
  bool _steps = false;
  bool _answer = false;
  bool _similar = false;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    final s = widget.solution;
    final dark = theme.brightness == Brightness.dark;

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        );
    Widget mono(String text) => Text(text, style: TextStyle(fontFamily: 'monospace', fontSize: 16, height: 1.5, color: theme.colorScheme.onSurface));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // умова — як у зошиті
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (s.number != null) Text(s.number!, style: display(13, color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              SelectableText(s.task, style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (s.topic.isNotEmpty) ...[
            const SizedBox(height: 10),
            ActionChip(
              avatar: const Icon(Icons.school_outlined, size: 18),
              label: Text('${t.topicBtn}: ${s.topic}'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TopicScreen(topic: s.topic, subject: widget.subject),
              )),
            ),
          ],

          // режим перевірки: оцінка до будь-яких підказок
          if (s.checked) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: s.studentCorrect! ? (dark ? AppColors.greenBgDark : AppColors.greenBg) : extra.redBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.studentCorrect! ? t.correct : t.incorrect,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.studentCorrect! ? AppColors.green : extra.red)),
                if (s.praise != null && s.praise!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('${t.praise}: ${s.praise}'),
                ],
                if (s.mistakes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(t.mistakes, style: const TextStyle(fontWeight: FontWeight.w800)),
                  for (final m in s.mistakes)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• ${m.where}: ${m.what}', style: const TextStyle(height: 1.35)),
                    ),
                ],
              ]),
            ),
          ],

          if (s.idea.isNotEmpty) ...[label(t.idea), Text(s.idea, style: theme.textTheme.bodyLarge)],

          // підказки — по одній
          if (s.hints.isNotEmpty) ...[
            label(t.hintsTitle),
            for (var i = 0; i < _hints && i < s.hints.length; i++)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: dark ? AppColors.pinkBgDark : AppColors.pinkBg, borderRadius: BorderRadius.circular(12)),
                child: Text('${t.hintN(i + 1, s.hints.length)}: ${s.hints[i]}', style: const TextStyle(height: 1.35)),
              ),
            if (_hints < s.hints.length)
              OutlinedButton.icon(
                onPressed: () => setState(() => _hints++),
                icon: const Icon(Icons.tips_and_updates_outlined),
                label: Text(_hints == 0 ? t.hintsTitle : t.nextHint),
              ),
          ],

          // кроки
          if (s.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (!_steps)
              OutlinedButton.icon(
                onPressed: () => setState(() => _steps = true),
                icon: const Icon(Icons.format_list_numbered),
                label: Text(t.showSteps),
              )
            else
              for (var i = 0; i < s.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.sky, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: display(12, color: AppColors.ink)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.steps[i].text, style: const TextStyle(height: 1.35)),
                        if (s.steps[i].formula != null && s.steps[i].formula!.trim().isNotEmpty) mono(s.steps[i].formula!),
                      ]),
                    ),
                  ]),
                ),
          ],

          // відповідь — жовтим маркером, лише на прохання
          if (s.answer.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (!_answer)
              FilledButton.tonalIcon(
                onPressed: () => setState(() => _answer = true),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(t.showAnswer),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: extra.amberBg, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.answer, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  SelectableText(s.answer, style: display(18)),
                  if (s.check.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('🔎 ${t.howToCheck}: ${s.check}', style: const TextStyle(height: 1.35)),
                  ],
                ]),
              ),
          ],

          // тренування
          if (s.similar != null && s.similar!.isNotEmpty) ...[
            label(t.similar),
            Text(s.similar!, style: const TextStyle(fontSize: 16, height: 1.4)),
            if (s.similarAnswer != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _similar = !_similar),
                  child: Text(_similar ? '${t.answer}: ${s.similarAnswer}' : t.showSimilarAnswer,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => showAskSheet(context, s.task),
              icon: const Icon(Icons.help_outline, size: 20),
              label: Text(t.askStep, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Шторка «Не розумію крок»
Future<void> showAskSheet(BuildContext context, String task) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AskSheet(task: task),
    );

class _AskSheet extends StatefulWidget {
  const _AskSheet({required this.task});
  final String task;

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  StepAnswer? _answer;
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
      final a = await scope.api.ask(widget.task, q, scope.prefs.value);
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
            Text(t.askStep, style: display(20)),
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
              if (_answer!.example != null && _answer!.example!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_answer!.example!, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}
