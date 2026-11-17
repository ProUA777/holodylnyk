import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'scale.dart';

class ShoppingItem {
  ShoppingItem({required this.name, List<String>? amounts, List<String>? recipes, this.done = false})
      : amounts = amounts ?? [],
        recipes = recipes ?? [];

  final String name;
  final List<String> amounts; // «200 г», «1 шт» — з різних рецептів
  final List<String> recipes; // для яких страв
  bool done;

  String get amountText => amounts.where((a) => a.trim().isNotEmpty).join(' + ');

  Map<String, dynamic> toJson() => {'name': name, 'amounts': amounts, 'recipes': recipes, 'done': done};

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        name: j['name'] as String,
        amounts: ((j['amounts'] as List?) ?? const []).map((e) => e as String).toList(),
        recipes: ((j['recipes'] as List?) ?? const []).map((e) => e as String).toList(),
        done: (j['done'] as bool?) ?? false,
      );
}

/// Один список покупок на всі рецепти. Однакові продукти зливаються в один пункт.
class ShoppingStore extends ChangeNotifier {
  static const _key = 'shopping_v1';
  final List<ShoppingItem> _items = [];

  List<ShoppingItem> get items => List.unmodifiable(_items);
  int get leftCount => _items.where((i) => !i.done).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _items
        ..clear()
        ..addAll((jsonDecode(raw) as List).map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  /// Додає все, чого бракує для рецепта (з урахуванням вибраних порцій).
  /// Повертає, скільки пунктів додано або оновлено.
  int addFromRecipe(Recipe r, {double factor = 1}) {
    var count = 0;
    for (final ing in r.missing) {
      final added = _merge(ing.name, scaleAmount(ing.amount, factor), r.title);
      if (added) count++;
    }
    if (count > 0) _changed();
    return count;
  }

  void addCustom(String name) {
    if (name.trim().isEmpty) return;
    _merge(name.trim(), '', null);
    _changed();
  }

  /// true — пункт новий або для нього додано новий рецепт
  bool _merge(String name, String amount, String? recipe) {
    final key = name.trim().toLowerCase();
    final i = _items.indexWhere((x) => x.name.toLowerCase() == key);
    if (i < 0) {
      _items.insert(0, ShoppingItem(name: name.trim(), amounts: [amount], recipes: [if (recipe != null) recipe]));
      return true;
    }
    final item = _items[i];
    if (recipe != null && item.recipes.contains(recipe)) return false; // той самий рецепт двічі не додаємо
    item.amounts.add(amount);
    if (recipe != null) item.recipes.add(recipe);
    item.done = false;
    return true;
  }

  void toggle(ShoppingItem item) {
    item.done = !item.done;
    _changed();
  }

  void remove(ShoppingItem item) {
    _items.remove(item);
    _changed();
  }

  void clearDone() {
    _items.removeWhere((i) => i.done);
    _changed();
  }

  String asText(String header) {
    final lines = _items.where((i) => !i.done).map((i) {
      final a = i.amountText;
      return a.isEmpty ? '• ${i.name}' : '• ${i.name} — $a';
    });
    return [header, ...lines].join('\n');
  }

  void _changed() {
    notifyListeners();
    SharedPreferences.getInstance().then(
      (p) => p.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList())),
    );
  }
}
