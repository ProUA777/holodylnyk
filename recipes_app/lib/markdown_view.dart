import 'package:flutter/material.dart';

import 'theme.dart';

/// Мінімальний Markdown для рецептів: заголовки, списки, нумеровані кроки, **жирний**.
/// Без зовнішніх пакетів — формат рецептів контролює наш бекенд.
sealed class MdBlock {}

class MdHeading extends MdBlock {
  MdHeading(this.text);
  final String text;
}

class MdBullet extends MdBlock {
  MdBullet(this.text);
  final String text;
}

class MdStep extends MdBlock {
  MdStep(this.index, this.text);
  final int index; // наскрізний номер кроку в усьому тексті
  final String text;
}

class MdParagraph extends MdBlock {
  MdParagraph(this.text);
  final String text;
}

final _heading = RegExp(r'^#{1,4}\s+(.*)$');
final _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
final _step = RegExp(r'^\s*\d+[.)]\s+(.*)$');

List<MdBlock> parseMarkdown(String md) {
  final out = <MdBlock>[];
  var steps = 0;
  for (final raw in md.split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) continue;
    RegExpMatch? m;
    if ((m = _heading.firstMatch(line)) != null) {
      out.add(MdHeading(m!.group(1)!));
    } else if ((m = _bullet.firstMatch(line)) != null) {
      out.add(MdBullet(m!.group(1)!));
    } else if ((m = _step.firstMatch(line)) != null) {
      out.add(MdStep(steps++, m!.group(1)!));
    } else {
      out.add(MdParagraph(line.trim()));
    }
  }
  return out;
}

/// Кроки з розділу «Приготування» — для режиму «Готую».
List<String> cookingSteps(String md) {
  final blocks = parseMarkdown(md);
  final result = <String>[];
  var inCooking = false;
  for (final b in blocks) {
    if (b is MdHeading) {
      final t = b.text.toLowerCase();
      inCooking = (t.contains('приготування') && !t.contains('підготов')) || t.contains('przyrządzanie') || t == 'cooking';
    } else if (b is MdStep && inCooking) {
      result.add(_plain(b.text));
    }
  }
  if (result.isEmpty) {
    result.addAll(blocks.whereType<MdStep>().map((s) => _plain(s.text)));
  }
  return result;
}

String _plain(String s) => s.replaceAll('**', '');

/// «5–7 хв», «10 хвилин», «3-4 хв» → хвилини для таймера (беремо більше значення).
int minutesIn(String text) {
  final m = RegExp(r'(\d+)(?:\s*[–-]\s*(\d+))?\s*(хв|хвилин|min)', caseSensitive: false).firstMatch(text);
  if (m == null) return 0;
  return int.parse(m.group(2) ?? m.group(1)!);
}

class MarkdownView extends StatelessWidget {
  const MarkdownView({super.key, required this.markdown, required this.done, required this.onToggleStep});

  final String markdown;
  final Set<int> done;
  final ValueChanged<int> onToggleStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final primary = theme.colorScheme.primary;
    final body = theme.textTheme.bodyLarge!;
    final children = <Widget>[];
    for (final b in parseMarkdown(markdown)) {
      switch (b) {
        case MdHeading(:final text):
          children.add(Padding(
            padding: const EdgeInsets.only(top: 26, bottom: 8),
            child: Text(text, style: display(18)),
          ));
        case MdBullet(:final text):
          children.add(Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outline))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 4, right: 12),
                child: Transform.rotate(
                  angle: 0.785,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
              Expanded(child: Text.rich(_rich(text, body))),
            ]),
          ));
        case MdStep(:final index, :final text):
          final isDone = done.contains(index);
          children.add(InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onToggleStep(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: isDone ? AppColors.lime : extra.leaf,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 18, color: AppColors.ink)
                      : Text('${index + 1}', style: display(14, color: primary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text.rich(_rich(
                      text,
                      body.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? extra.muted : null,
                      ),
                    )),
                  ),
                ),
              ]),
            ),
          ));
        case MdParagraph(:final text):
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text.rich(_rich(text, body)),
          ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  /// **жирний** усередині рядка
  static TextSpan _rich(String text, TextStyle style) {
    final parts = text.split('**');
    return TextSpan(
      style: style,
      children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(text: parts[i], style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null),
      ],
    );
  }
}
