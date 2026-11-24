import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Збережена рослина: картка догляду + журнал поливу. Усе живе лише на телефоні.
class MyPlant {
  MyPlant({
    required this.id,
    required this.nickname,
    required this.result,
    required this.added,
    this.thumbPath,
    this.lastWatered,
    int? waterEveryDays,
    List<DateTime>? log,
    List<PlantCheck>? checks,
  })  : waterEveryDays = waterEveryDays ?? result.care.waterEveryDays,
        log = log ?? <DateTime>[],
        checks = checks ?? <PlantCheck>[];

  /// Зимовий режим (листопад–лютий): поливаємо рідше. Вмикається в «Моїх рослинах», діє на всі.
  static bool winterMode = true;
  static bool isWinter(DateTime now) => now.month >= 11 || now.month <= 2;

  final String id;
  String nickname; // «Монстера у вітальні»
  PlantResult result;
  final DateTime added;
  final String? thumbPath;
  DateTime? lastWatered;
  int waterEveryDays; // можна підлаштувати під свою квартиру (літній інтервал)
  final List<DateTime> log; // журнал поливу, новіші першими
  final List<PlantCheck> checks; // перевірки лікування, новіші першими

  /// Інтервал поливу з урахуванням зими: пропорційно до порад AI, або ×1.75, якщо AI не дав зимового
  int everyDaysAt(DateTime now) {
    if (!winterMode || !isWinter(now)) return waterEveryDays;
    final c = result.care;
    final k = c.winterWaterEveryDays != null ? c.winterWaterEveryDays! / c.waterEveryDays : 1.75;
    return (waterEveryDays * k).round().clamp(waterEveryDays, 90);
  }

  /// Коли поливати наступного разу (без часу — лише дата)
  DateTime nextWater(DateTime now) {
    final from = lastWatered ?? added;
    final d = DateTime(from.year, from.month, from.day).add(Duration(days: everyDaysAt(now)));
    return d;
  }

  /// Скільки днів до поливу: 0 — сьогодні, від'ємне — прострочено
  int daysToWater(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return nextWater(now).difference(today).inDays;
  }

  bool needsWater(DateTime now) => daysToWater(now) <= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'result': result.toJson(),
        'added': added.toIso8601String(),
        'thumb': thumbPath,
        'last_watered': lastWatered?.toIso8601String(),
        'every': waterEveryDays,
        'log': log.map((d) => d.toIso8601String()).toList(),
        'checks': checks.map((c) => c.toJson()).toList(),
      };

  factory MyPlant.fromJson(Map<String, dynamic> j) => MyPlant(
        id: j['id'] as String,
        nickname: j['nickname'] as String? ?? '',
        result: PlantResult.fromJson(j['result'] as Map<String, dynamic>),
        added: DateTime.tryParse(j['added'] as String? ?? '') ?? DateTime.now(),
        thumbPath: j['thumb'] as String?,
        lastWatered: DateTime.tryParse(j['last_watered'] as String? ?? ''),
        waterEveryDays: (j['every'] as num?)?.toInt(),
        log: ((j['log'] as List?) ?? const []).map((e) => DateTime.tryParse('$e')).whereType<DateTime>().toList(),
        checks: ((j['checks'] as List?) ?? const []).map((e) => PlantCheck.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Одна перевірка лікування по фото
class PlantCheck {
  const PlantCheck({required this.at, required this.trend, this.note = ''});
  final DateTime at;
  final Trend trend;
  final String note;

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'trend': trend.name, 'note': note};

  factory PlantCheck.fromJson(Map<String, dynamic> j) => PlantCheck(
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        trend: Trend.values.firstWhere((v) => v.name == j['trend'], orElse: () => Trend.same),
        note: j['note'] as String? ?? '',
      );
}

class GardenStore extends ChangeNotifier {
  static const _key = 'garden_v1';
  static const _winterKey = 'winter_mode';

  bool get winterMode => MyPlant.winterMode;

  Future<void> setWinterMode(bool on) async {
    MyPlant.winterMode = on;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_winterKey, on);
  }
  final List<MyPlant> _items = [];

  List<MyPlant> get items => List.unmodifiable(_items);

  /// Спершу ті, кого треба полити, далі — за датою наступного поливу
  List<MyPlant> sorted(DateTime now) =>
      List.of(_items)..sort((a, b) => a.daysToWater(now).compareTo(b.daysToWater(now)));

  int thirstyCount(DateTime now) => _items.where((p) => p.needsWater(now)).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    MyPlant.winterMode = prefs.getBool(_winterKey) ?? true;
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _items.addAll((jsonDecode(raw) as List).map((e) => MyPlant.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  Future<MyPlant> add(PlantResult result, {File? photo, String? nickname, DateTime? now}) async {
    final at = now ?? DateTime.now();
    String? thumb;
    if (photo != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        thumb = (await photo.copy('${dir.path}/plant_${at.millisecondsSinceEpoch}.jpg')).path;
      } catch (_) {
        thumb = null; // працює й без фото
      }
    }
    final p = MyPlant(
      id: '${at.microsecondsSinceEpoch}',
      nickname: (nickname ?? '').trim().isEmpty ? result.name : nickname!.trim(),
      result: result,
      added: at,
      thumbPath: thumb,
      lastWatered: at, // щойно додану вважаємо політою — відлік від сьогодні
    );
    _items.insert(0, p);
    await _save();
    return p;
  }

  Future<void> water(MyPlant p, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    p.lastWatered = when;
    p.log.insert(0, when);
    if (p.log.length > 60) p.log.removeRange(60, p.log.length);
    await _save();
  }

  Future<void> addCheck(MyPlant p, Progress progress, {DateTime? at}) async {
    p.checks.insert(0, PlantCheck(at: at ?? DateTime.now(), trend: progress.trend, note: progress.note));
    if (p.checks.length > 20) p.checks.removeRange(20, p.checks.length);
    await _save();
  }

  Future<void> setEvery(MyPlant p, int days) async {
    p.waterEveryDays = days.clamp(1, 60);
    await _save();
  }

  Future<void> rename(MyPlant p, String name) async {
    if (name.trim().isEmpty) return;
    p.nickname = name.trim();
    await _save();
  }

  Future<void> update(MyPlant p, PlantResult r) async {
    p.result = r;
    await _save();
  }

  Future<void> remove(MyPlant p) async {
    _items.removeWhere((x) => x.id == p.id);
    if (p.thumbPath != null) {
      try {
        await File(p.thumbPath!).delete();
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
