import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Розібрані завдання: щоб повернутися до пояснення перед контрольною. Лише на телефоні.
class Entry {
  Entry({required this.id, required this.date, required this.result, this.starred = false});
  final String id;
  final DateTime date;
  final HomeworkResult result;
  bool starred;

  String get title {
    final s = result.solutions;
    if (s.isEmpty) return '';
    return s.first.topic.isNotEmpty ? s.first.topic : s.first.task;
  }

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'result': result.toJson(), 'star': starred};

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        result: HomeworkResult.fromJson(j['result'] as Map<String, dynamic>),
        starred: j['star'] as bool? ?? false,
      );
}

class HistoryStore extends ChangeNotifier {
  static const _key = 'homework_v1';
  static const _max = 40; // зірочкою позначені не видаляються
  final List<Entry> _items = [];

  List<Entry> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _items.addAll((jsonDecode(raw) as List).map((e) => Entry.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  Future<Entry> add(HomeworkResult r, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final e = Entry(id: '${at.microsecondsSinceEpoch}', date: at, result: r);
    _items.insert(0, e);
    while (_items.length > _max) {
      final i = _items.lastIndexWhere((x) => !x.starred);
      if (i < 0) break;
      _items.removeAt(i);
    }
    await _save();
    return e;
  }

  Future<void> toggleStar(Entry e) async {
    e.starred = !e.starred;
    await _save();
  }

  Future<void> remove(Entry e) async {
    _items.removeWhere((x) => x.id == e.id);
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }
}
