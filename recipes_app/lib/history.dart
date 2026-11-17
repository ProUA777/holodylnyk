import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanEntry {
  ScanEntry({required this.date, required this.ingredients, required this.useSoon, this.thumbPath});

  final DateTime date;
  final List<String> ingredients;
  final List<String> useSoon;
  final String? thumbPath; // копія першого фото в папці апки

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'ingredients': ingredients,
        'use_soon': useSoon,
        'thumb': thumbPath,
      };

  factory ScanEntry.fromJson(Map<String, dynamic> j) => ScanEntry(
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        ingredients: ((j['ingredients'] as List?) ?? const []).map((e) => e as String).toList(),
        useSoon: ((j['use_soon'] as List?) ?? const []).map((e) => e as String).toList(),
        thumbPath: j['thumb'] as String?,
      );
}

/// Останні сканування: можна знову відкрити ті самі продукти без нового фото.
class HistoryStore extends ChangeNotifier {
  static const _key = 'history_v1';
  static const _max = 8;
  final List<ScanEntry> _items = [];

  List<ScanEntry> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _items.addAll((jsonDecode(raw) as List).map((e) => ScanEntry.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  Future<void> add(List<String> ingredients, List<String> useSoon, {File? photo}) async {
    if (ingredients.isEmpty) return;
    String? thumb;
    if (photo != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final dest = File('${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
        thumb = (await photo.copy(dest.path)).path;
      } catch (_) {
        thumb = null; // історія працює й без мініатюри
      }
    }
    _items.insert(0, ScanEntry(date: DateTime.now(), ingredients: ingredients, useSoon: useSoon, thumbPath: thumb));
    while (_items.length > _max) {
      final old = _items.removeLast();
      if (old.thumbPath != null) {
        try {
          await File(old.thumbPath!).delete();
        } catch (_) {}
      }
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }
}
