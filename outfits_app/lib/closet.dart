import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Мій гардероб: речі з усіх фото, без дублікатів. Усе живе лише на телефоні.
class WardrobeStore extends ChangeNotifier {
  static const _key = 'wardrobe_v1';
  final List<Item> _items = [];

  List<Item> get items => List.unmodifiable(_items);

  /// Згруповано за типом: верх, низ, сукні, верхній одяг, взуття, аксесуари, сумки
  Map<Kind, List<Item>> get byKind {
    final out = <Kind, List<Item>>{};
    for (final k in Kind.values) {
      final list = _items.where((i) => i.kind == k).toList();
      if (list.isNotEmpty) out[k] = list;
    }
    return out;
  }

  bool has(String name) => _items.any((i) => i.name.toLowerCase() == name.trim().toLowerCase());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _items.addAll((jsonDecode(raw) as List).map((e) => Item.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  /// Повертає, скільки нових речей додано
  Future<int> addAll(Iterable<Item> items) async {
    var n = 0;
    for (final i in items) {
      if (i.name.trim().isEmpty || has(i.name)) continue;
      _items.add(i);
      n++;
    }
    if (n > 0) await _save();
    return n;
  }

  Future<void> remove(Item item) async {
    _items.removeWhere((i) => i.name == item.name);
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }
}

/// Збережені образи (♥), лічильник «одягав(ла)» і образ дня.
class LooksStore extends ChangeNotifier {
  static const _key = 'looks_v1';
  static const _wornKey = 'worn_v1';
  static const _todayKey = 'ootd_v1';
  final List<Outfit> _items = [];
  final Map<String, List<DateTime>> _worn = {}; // ключ образу → коли одягав(ла), новіші першими
  Outfit? _today;
  DateTime? _todayDate;

  List<Outfit> get items => List.unmodifiable(_items);

  bool isSaved(Outfit o) => _items.any((x) => x.key == o.key);

  int wornCount(Outfit o) => _worn[o.key]?.length ?? 0;
  DateTime? lastWorn(Outfit o) {
    final l = _worn[o.key];
    return l == null || l.isEmpty ? null : l.first;
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool wornToday(Outfit o, {DateTime? now}) {
    final last = lastWorn(o);
    return last != null && _sameDay(last, now ?? DateTime.now());
  }

  /// Образ дня — лише якщо його склали сьогодні
  Outfit? todayOutfit({DateTime? now}) =>
      _today != null && _todayDate != null && _sameDay(_todayDate!, now ?? DateTime.now()) ? _today : null;

  /// Назви образів, які вдягали останні [days] днів — щоб образ дня не повторювався
  List<String> recentlyWorn({int days = 7, DateTime? now}) {
    final at = now ?? DateTime.now();
    final out = <String>[];
    for (final o in [..._items, if (_today != null) _today!]) {
      final last = lastWorn(o);
      if (last != null && at.difference(last).inDays < days && !out.contains(o.title)) out.add(o.title);
    }
    return out;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final w = prefs.getString(_wornKey);
      if (w != null) {
        (jsonDecode(w) as Map<String, dynamic>).forEach((k, v) {
          _worn[k] = (v as List).map((e) => DateTime.tryParse('$e')).whereType<DateTime>().toList();
        });
      }
      final d = prefs.getString(_todayKey);
      if (d != null) {
        final j = jsonDecode(d) as Map<String, dynamic>;
        _today = Outfit.fromJson(j['outfit'] as Map<String, dynamic>);
        _todayDate = DateTime.tryParse(j['date'] as String? ?? '');
      }
    } catch (_) {
      await prefs.remove(_wornKey);
      await prefs.remove(_todayKey);
    }
    final raw = prefs.getString(_key);
    if (raw == null) {
      notifyListeners();
      return;
    }
    try {
      _items.addAll((jsonDecode(raw) as List).map((e) => Outfit.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  /// «Одягав(ла) сьогодні» — повторне натискання того ж дня скасовує
  Future<void> toggleWorn(Outfit o, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final list = _worn.putIfAbsent(o.key, () => []);
    if (list.isNotEmpty && _sameDay(list.first, at)) {
      list.removeAt(0);
    } else {
      list.insert(0, at);
      if (list.length > 100) list.removeRange(100, list.length);
    }
    if (list.isEmpty) _worn.remove(o.key);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wornKey, jsonEncode(_worn.map((k, v) => MapEntry(k, v.map((d) => d.toIso8601String()).toList()))));
  }

  Future<void> setToday(Outfit o, {DateTime? now}) async {
    _today = o;
    _todayDate = now ?? DateTime.now();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayKey, jsonEncode({'date': _todayDate!.toIso8601String(), 'outfit': o.toJson()}));
  }

  Future<void> toggle(Outfit o) async {
    if (isSaved(o)) {
      _items.removeWhere((x) => x.key == o.key);
    } else {
      _items.insert(0, o);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }
}
