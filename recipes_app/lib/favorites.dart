import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Збережені рецепти — локально на телефоні, разом з детальним текстом (працюють офлайн).
class FavoritesStore extends ChangeNotifier {
  static const _key = 'favorites_v1';
  final List<Recipe> _items = [];

  List<Recipe> get items => List.unmodifiable(_items);

  bool contains(Recipe r) => _items.any((x) => x.title == r.title);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _items
        ..clear()
        ..addAll(list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key); // пошкоджені дані не повинні ламати апку
    }
  }

  Future<void> toggle(Recipe r) async {
    if (contains(r)) {
      _items.removeWhere((x) => x.title == r.title);
    } else {
      _items.insert(0, r);
    }
    notifyListeners();
    await _save();
  }

  /// Детальний текст догенерувався після збереження — дописуємо його.
  Future<void> updateDetails(Recipe r) async {
    final i = _items.indexWhere((x) => x.title == r.title);
    if (i < 0) return;
    _items[i].details = r.details;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }
}
