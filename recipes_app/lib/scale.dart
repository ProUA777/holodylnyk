/// Перерахунок кількостей під іншу кількість порцій: «200 г» × 1,5 → «300 г».
/// Той самий алгоритм, що й у прототипі (scaleAmount / scaleMarkdown у JS).
library;

const _frac = {'½': 0.5, '¼': 0.25, '¾': 0.75, '⅓': 1 / 3, '⅔': 2 / 3};
final _num = RegExp(r'(\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?|[½¼¾⅓⅔])');
final _heavy = RegExp(r'^(г|гр|грам\S*|g|gr|gram\S*|мл|ml|kg|кг)(\s|$|[.,;)])', caseSensitive: false);

double _parse(String s) {
  final f = _frac[s];
  if (f != null) return f;
  if (s.contains('/')) {
    final p = s.split('/').map((x) => double.tryParse(x.trim()) ?? 0).toList();
    return p[1] == 0 ? p[0] : p[0] / p[1];
  }
  return double.tryParse(s.replaceAll(',', '.')) ?? 0;
}

String _fmt(double v, String unit) {
  num r;
  if (_heavy.hasMatch(unit)) {
    r = v >= 50 ? (v / 5).round() * 5 : (v.round() < 1 ? 1 : v.round());
  } else if (v >= 10) {
    r = v.round();
  } else {
    final half = (v * 2).round() / 2;
    r = half < 0.5 ? 0.5 : half;
  }
  final s = r == r.roundToDouble() ? r.toInt().toString() : r.toString();
  return s.replaceAll('.', ',');
}

/// Масштабує всі числа в рядку кількості. f == 1 — без змін.
String scaleAmount(String text, double f) {
  if (f == 1 || text.isEmpty) return text;
  return text.replaceAllMapped(_num, (m) {
    final unit = text.substring(m.end).trim();
    return _fmt(_parse(m.group(0)!) * f, unit);
  });
}

/// У детальному рецепті масштабує кількості лише в першому розділі («Інгредієнти» / «Składniki»),
/// у рядках виду «- назва — кількість».
String scaleMarkdown(String md, double f) {
  if (f == 1) return md;
  var section = -1;
  final heading = RegExp(r'^#{1,4}\s');
  final bullet = RegExp(r'^\s*[-*•]\s');
  final split = RegExp(r'^(.*?\s[—–-]\s)(.*)$');
  return md.split('\n').map((line) {
    if (heading.hasMatch(line)) {
      section++;
      return line;
    }
    if (section != 0 || !bullet.hasMatch(line)) return line;
    final m = split.firstMatch(line);
    return m == null ? line : '${m.group(1)}${scaleAmount(m.group(2)!, f)}';
  }).join('\n');
}
