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

/// Збережені образи (♥).
class LooksStore extends ChangeNotifier {
  static const _key = 'looks_v1';
  final List<Outfit> _items = [];

  List<Outfit> get items => List.unmodifiable(_items);

  bool isSaved(Outfit o) => _items.any((x) => x.key == o.key);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _items.addAll((jsonDecode(raw) as List).map((e) => Outfit.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
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
