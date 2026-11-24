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
  }) : bought = bought ?? <String>{};

  final String id;
  RepairResult result;
  final DateTime added;
  final String? thumbPath;
  bool done;
  final Set<String> bought; // що з деталей/інструментів уже є

  Map<String, dynamic> toJson() => {
        'id': id,
        'result': result.toJson(),
        'added': added.toIso8601String(),
        'thumb': thumbPath,
        'done': done,
        'bought': bought.toList(),
      };

  factory MyRepair.fromJson(Map<String, dynamic> j) => MyRepair(
        id: j['id'] as String,
        result: RepairResult.fromJson(j['result'] as Map<String, dynamic>),
        added: DateTime.tryParse(j['added'] as String? ?? '') ?? DateTime.now(),
        thumbPath: j['thumb'] as String?,
        done: j['done'] as bool? ?? false,
        bought: ((j['bought'] as List?) ?? const []).map((e) => '$e').toSet(),
      );
}

class RepairsStore extends ChangeNotifier {
  static const _key = 'repairs_v1';
  final List<MyRepair> _items = [];

  List<MyRepair> get items => List.unmodifiable(_items);

  /// Спершу ті, що ще в роботі, далі — полагоджені
  List<MyRepair> get sorted => List.of(_items)..sort((a, b) => a.done == b.done ? b.added.compareTo(a.added) : (a.done ? 1 : -1));

  int get openCount => _items.where((r) => !r.done).length;

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

  Future<void> setDone(MyRepair r, bool done) async {
    r.done = done;
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
