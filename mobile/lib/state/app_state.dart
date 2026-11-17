import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';

class BuildRecord {
  final String id, title, emoji, diff;
  final String? cat;
  final int minutes;
  final DateTime date;

  const BuildRecord({
    required this.id,
    required this.title,
    required this.emoji,
    required this.diff,
    required this.minutes,
    required this.date,
    this.cat,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'emoji': emoji, 'diff': diff, 'min': minutes, 'cat': cat, 'date': date.millisecondsSinceEpoch};

  static BuildRecord? tryParse(dynamic j) {
    if (j is! Map) return null;
    try {
      return BuildRecord(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        emoji: (j['emoji'] ?? '🧱') as String,
        diff: (j['diff'] ?? 'medium') as String,
        minutes: (j['min'] as num?)?.toInt() ?? 0,
        cat: j['cat'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Everything the app remembers between launches, plus the current tab.
class AppState extends ChangeNotifier {
  static const supportedLangs = ['uk', 'pl', 'en'];

  final SharedPreferences _prefs;
  String _lang;
  ThemeMode _theme;
  bool _onboarded;
  late bool _stepHintSeen = _prefs.getBool('step_hint_seen') ?? false;
  late final Set<String> _favorites = (_prefs.getStringList('favorites') ?? const []).toSet();
  late final Map<String, int> _progress = _readProgress();

  Map<String, int> _readProgress() {
    try {
      final raw = jsonDecode(_prefs.getString('progress') ?? '{}') as Map;
      return raw.map((k, v) => MapEntry(k as String, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }
  final List<BuildRecord> _builds;
  final String deviceId;

  /// Bottom-navigation tab (0 scan, 1 ideas, 2 my builds). Not persisted.
  final ValueNotifier<int> tab = ValueNotifier(0);

  AppState._(this._prefs, this._lang, this._theme, this._onboarded, this._builds, this.deviceId);

  static Future<AppState> load() async {
    final p = await SharedPreferences.getInstance();
    final sys = PlatformDispatcher.instance.locale.languageCode;
    final lang = p.getString('lang') ?? (supportedLangs.contains(sys) ? sys : (sys == 'ru' || sys == 'be' ? 'uk' : 'en'));
    final theme = ThemeMode.values.firstWhere((m) => m.name == p.getString('theme'), orElse: () => ThemeMode.system);
    var builds = <BuildRecord>[];
    try {
      builds = [for (final e in jsonDecode(p.getString('builds') ?? '[]') as List) BuildRecord.tryParse(e)]
          .whereType<BuildRecord>()
          .toList();
    } catch (_) {}
    var id = p.getString('device_id');
    if (id == null) {
      final r = Random.secure();
      id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await p.setString('device_id', id);
    }
    return AppState._(p, supportedLangs.contains(lang) ? lang : 'en', theme, p.getBool('onboarded') ?? false, builds, id);
  }

  String get lang => _lang;
  ThemeMode get theme => _theme;
  bool get onboarded => _onboarded;

  /// The "tap right for next, left for back" tip on the 3D stage is shown until the first tap or swipe.
  bool get stepHintSeen => _stepHintSeen;

  void markStepHintSeen() {
    if (_stepHintSeen) return;
    _stepHintSeen = true;
    _prefs.setBool('step_hint_seen', true);
  }

  // ── favourites ──
  bool isFavorite(String id) => _favorites.contains(id);
  Set<String> get favorites => Set.unmodifiable(_favorites);

  void toggleFavorite(String id) {
    _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
    _prefs.setStringList('favorites', _favorites.toList());
    notifyListeners();
  }

  // ── where the child stopped in each model (0-based step) ──
  int progressOf(String id) => _progress[id] ?? 0;

  /// Models started but not finished, most recent first (insertion order is kept on save).
  List<String> get inProgress => _progress.keys.toList().reversed.toList();

  /// Saved silently while stepping; call [announceProgress] when leaving the model.
  void saveProgress(String id, int step) {
    _progress.remove(id); // re-insert so the most recent model comes last
    if (step > 0) _progress[id] = step;
    _prefs.setString('progress', jsonEncode(_progress));
  }

  void announceProgress() => scheduleMicrotask(notifyListeners);

  List<BuildRecord> get builds => List.unmodifiable(_builds);

  bool isBuilt(String id) => _builds.any((b) => b.id == id);
  int get stars => _builds.fold(0, (s, b) => s + difficultyStars(b.diff));
  int get minutes => _builds.fold(0, (s, b) => s + b.minutes);
  int countIn(String cat) => _builds.where((b) => b.cat == cat).length;

  void setLang(String l) {
    if (!supportedLangs.contains(l) || l == _lang) return;
    _lang = l;
    _prefs.setString('lang', l);
    notifyListeners();
  }

  void setTheme(ThemeMode m) {
    _theme = m;
    _prefs.setString('theme', m.name);
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    _prefs.setBool('onboarded', true);
    notifyListeners();
  }

  void showOnboardingAgain() {
    _onboarded = false;
    _prefs.setBool('onboarded', false);
    notifyListeners();
  }

  /// Returns true when this is a new build (not built before).
  bool addBuild(BuildRecord r) {
    _progress.remove(r.id);
    _prefs.setString('progress', jsonEncode(_progress));
    if (isBuilt(r.id)) return false;
    _builds.insert(0, r);
    _save();
    notifyListeners();
    return true;
  }

  void clearBuilds() {
    _builds.clear();
    _save();
    notifyListeners();
  }

  void _save() => _prefs.setString('builds', jsonEncode([for (final b in _builds) b.toJson()]));
}
