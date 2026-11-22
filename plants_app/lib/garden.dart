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
  }) : waterEveryDays = waterEveryDays ?? result.care.waterEveryDays;

  final String id;
  String nickname; // «Монстера у вітальні»
  PlantResult result;
  final DateTime added;
  final String? thumbPath;
  DateTime? lastWatered;
  int waterEveryDays; // можна підлаштувати під свою квартиру

  /// Коли поливати наступного разу (без часу — лише дата)
  DateTime nextWater(DateTime now) {
    final from = lastWatered ?? added;
    final d = DateTime(from.year, from.month, from.day).add(Duration(days: waterEveryDays));
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
      };

  factory MyPlant.fromJson(Map<String, dynamic> j) => MyPlant(
        id: j['id'] as String,
        nickname: j['nickname'] as String? ?? '',
        result: PlantResult.fromJson(j['result'] as Map<String, dynamic>),
        added: DateTime.tryParse(j['added'] as String? ?? '') ?? DateTime.now(),
        thumbPath: j['thumb'] as String?,
        lastWatered: DateTime.tryParse(j['last_watered'] as String? ?? ''),
        waterEveryDays: (j['every'] as num?)?.toInt(),
      );
}

class GardenStore extends ChangeNotifier {
  static const _key = 'garden_v1';
  final List<MyPlant> _items = [];

  List<MyPlant> get items => List.unmodifiable(_items);

  /// Спершу ті, кого треба полити, далі — за датою наступного поливу
  List<MyPlant> sorted(DateTime now) =>
      List.of(_items)..sort((a, b) => a.daysToWater(now).compareTo(b.daysToWater(now)));

  int thirstyCount(DateTime now) => _items.where((p) => p.needsWater(now)).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
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
    p.lastWatered = at ?? DateTime.now();
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
