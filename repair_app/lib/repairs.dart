import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Збережений ремонт: що зламалось, що купити (відмітки), чи вже полагоджено.
class MyRepair {
  MyRepair({
    required this.id,
    required this.result,
    required this.added,
    this.thumbPath,
    this.done = false,
    Set<String>? bought,
    this.doneAt,
    Map<String, DateTime>? serviced,
    this.afterOk,
  })  : bought = bought ?? <String>{},
        serviced = serviced ?? <String, DateTime>{};

  final String id;
  RepairResult result;
  final DateTime added;
  final String? thumbPath;
  bool done;
  final Set<String> bought; // що з деталей/інструментів уже є
  DateTime? doneAt; // коли полагоджено — від цієї дати рахуємо обслуговування
  final Map<String, DateTime> serviced; // справа обслуговування → коли робили востаннє
  bool? afterOk; // результат перевірки фото «після»

  /// Коли наступного разу робити справу [m] (від останнього обслуговування або від ремонту)
  DateTime nextService(Maintenance m) =>
      (serviced[m.task] ?? doneAt ?? added).add(Duration(days: m.everyDays));

  /// Через скільки днів (≤0 — пора)
  int daysToService(Maintenance m, DateTime now) =>
      DateTime(nextService(m).year, nextService(m).month, nextService(m).day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'result': result.toJson(),
        'added': added.toIso8601String(),
        'thumb': thumbPath,
        'done': done,
        'bought': bought.toList(),
        'done_at': doneAt?.toIso8601String(),
        'serviced': serviced.map((k, v) => MapEntry(k, v.toIso8601String())),
        'after_ok': afterOk,
      };

  factory MyRepair.fromJson(Map<String, dynamic> j) => MyRepair(
        id: j['id'] as String,
        result: RepairResult.fromJson(j['result'] as Map<String, dynamic>),
        added: DateTime.tryParse(j['added'] as String? ?? '') ?? DateTime.now(),
        thumbPath: j['thumb'] as String?,
        done: j['done'] as bool? ?? false,
        bought: ((j['bought'] as List?) ?? const []).map((e) => '$e').toSet(),
        doneAt: DateTime.tryParse(j['done_at'] as String? ?? ''),
        serviced: ((j['serviced'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', DateTime.tryParse('$v') ?? DateTime.now())),
        afterOk: j['after_ok'] as bool?,
      );
}

class RepairsStore extends ChangeNotifier {
  static const _key = 'repairs_v1';
  final List<MyRepair> _items = [];

  List<MyRepair> get items => List.unmodifiable(_items);

  /// Спершу ті, що ще в роботі, далі — полагоджені
  List<MyRepair> get sorted => List.of(_items)..sort((a, b) => a.done == b.done ? b.added.compareTo(a.added) : (a.done ? 1 : -1));

  int get openCount => _items.where((r) => !r.done).length;

  /// Обслуговування, яке пора зробити (або за ≤3 дні) — для полагоджених речей
  List<(MyRepair, Maintenance, int)> dueService({DateTime? now}) {
    final at = now ?? DateTime.now();
    final out = <(MyRepair, Maintenance, int)>[];
    for (final r in _items.where((r) => r.done)) {
      for (final m in r.result.maintenance) {
        final d = r.daysToService(m, at);
        if (d <= 3) out.add((r, m, d));
      }
    }
    out.sort((a, b) => a.$3.compareTo(b.$3));
    return out;
  }

  Future<void> markServiced(MyRepair r, Maintenance m, {DateTime? now}) async {
    r.serviced[m.task] = now ?? DateTime.now();
    await _save();
  }

  Future<void> setAfter(MyRepair r, bool ok) async {
    r.afterOk = ok;
    if (ok) {
      r.done = true;
      r.doneAt ??= DateTime.now();
    }
    await _save();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _items.addAll((jsonDecode(raw) as List).map((e) => MyRepair.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  Future<MyRepair> add(RepairResult result, {File? photo, DateTime? now}) async {
    final at = now ?? DateTime.now();
    String? thumb;
    if (photo != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        thumb = (await photo.copy('${dir.path}/repair_${at.millisecondsSinceEpoch}.jpg')).path;
      } catch (_) {
        thumb = null;
      }
    }
    final r = MyRepair(id: '${at.microsecondsSinceEpoch}', result: result, added: at, thumbPath: thumb);
    _items.insert(0, r);
    await _save();
    return r;
  }

  Future<void> toggleBought(MyRepair r, String part) async {
    r.bought.contains(part) ? r.bought.remove(part) : r.bought.add(part);
    await _save();
  }

  Future<void> setDone(MyRepair r, bool done, {DateTime? now}) async {
    r.done = done;
    r.doneAt = done ? (now ?? DateTime.now()) : null;
    await _save();
  }

  Future<void> remove(MyRepair r) async {
    _items.removeWhere((x) => x.id == r.id);
    if (r.thumbPath != null) {
      try {
        await File(r.thumbPath!).delete();
      } catch (_) {}
    }
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }
}
