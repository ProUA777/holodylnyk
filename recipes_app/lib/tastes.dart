import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Смаки: 👍 / 👎 для страв. Зберігаються лише на телефоні; останні 15 кожного виду
/// відправляються з запитом, і AI пропонує схоже на вподобане та уникає невподобаного.
class TasteStore extends ChangeNotifier {
  static const _key = 'tastes_v1';
  static const _max = 15;
  final List<String> _liked = [];
  final List<String> _disliked = [];

  List<String> get liked => List.unmodifiable(_liked);
  List<String> get disliked => List.unmodifiable(_disliked);

  /// true — 👍, false — 👎, null — без оцінки
  bool? voteOf(String title) {
    final k = title.toLowerCase();
    if (_liked.any((x) => x.toLowerCase() == k)) return true;
    if (_disliked.any((x) => x.toLowerCase() == k)) return false;
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _liked.addAll(((j['liked'] as List?) ?? const []).map((e) => e as String));
      _disliked.addAll(((j['disliked'] as List?) ?? const []).map((e) => e as String));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  /// Повторний дотик на ту саму оцінку знімає її.
  Future<void> vote(String title, bool up) async {
    final current = voteOf(title);
    final k = title.toLowerCase();
    _liked.removeWhere((x) => x.toLowerCase() == k);
    _disliked.removeWhere((x) => x.toLowerCase() == k);
    if (current != up) {
      final list = up ? _liked : _disliked;
      list.insert(0, title);
      if (list.length > _max) list.removeLast();
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'liked': _liked, 'disliked': _disliked}));
  }
}
