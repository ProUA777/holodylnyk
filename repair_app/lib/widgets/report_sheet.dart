import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../theme.dart';

/// «Поскаржитися на відповідь»: Google Play вимагає, щоб у застосунках з AI-контентом
/// людина могла позначити шкідливу чи неправильну відповідь. Фото не надсилаються — лише текст відповіді.
class ReportButton extends StatelessWidget {
  const ReportButton({super.key, required this.content});

  /// Текст відповіді AI, на яку скаржаться
  final String Function() content;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: reportTexts(L10n.of(context).code)['title'],
        icon: const Icon(Icons.flag_outlined),
        onPressed: () => showReportSheet(context, content()),
      );
}

const _uk = {
  'title': 'Поскаржитися на відповідь',
  'hint': 'Побачили помилку чи небезпечну пораду? Напишіть — ми виправимо. Фото не надсилаються.',
  'wrong': 'Неправильно',
  'harmful': 'Небезпечно',
  'offensive': 'Образливо',
  'other': 'Інше',
  'comment': 'Що не так? (необов’язково)',
  'send': 'Надіслати',
  'thanks': 'Дякуємо! Скаргу надіслано.',
  'error': 'Не вдалося надіслати. Спробуйте пізніше.',
};

const _pl = {
  'title': 'Zgłoś odpowiedź',
  'hint': 'Widzisz błąd lub niebezpieczną radę? Napisz — poprawimy. Zdjęcia nie są wysyłane.',
  'wrong': 'Nieprawidłowa',
  'harmful': 'Niebezpieczna',
  'offensive': 'Obraźliwa',
  'other': 'Inne',
  'comment': 'Co jest nie tak? (opcjonalnie)',
  'send': 'Wyślij',
  'thanks': 'Dziękujemy! Zgłoszenie wysłane.',
  'error': 'Nie udało się wysłać. Spróbuj później.',
};

Map<String, String> reportTexts(String code) => code == 'pl' ? _pl : _uk;

Future<void> showReportSheet(BuildContext context, String content) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(content: content),
    );

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.content});
  final String content;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _ctrl = TextEditingController();
  String _reason = 'wrong';
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final scope = AppScope.of(context);
    final code = L10n.of(context).code;
    final tx = reportTexts(code);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await scope.api.report(content: widget.content, reason: _reason, comment: _ctrl.text, language: code);
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(tx['thanks']!)));
    } on ApiException {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(tx['error']!)));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(tx['error']!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = reportTexts(L10n.of(context).code);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('🚩 ${tx['title']}', style: display(20)),
            const SizedBox(height: 6),
            Text(tx['hint']!, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in const ['wrong', 'harmful', 'offensive', 'other'])
                ChoiceChip(label: Text(tx[r]!), selected: _reason == r, onSelected: (_) => setState(() => _reason = r)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: tx['comment'],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _send,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.send),
              label: Text(tx['send']!),
            ),
          ]),
        ),
      ),
    );
  }
}
