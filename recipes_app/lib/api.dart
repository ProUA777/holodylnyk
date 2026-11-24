import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'models.dart';

/// Помилка сервера/мережі. Текст для людини — через L10n.of(context).error(e).
class ApiException implements Exception {
  final String code;
  final String? serverMessage;
  ApiException(this.code, {this.serverMessage});
  @override
  String toString() => 'ApiException($code${serverMessage == null ? '' : ': $serverMessage'})';
}

/// Клієнт PhotoAI Engine. Для інших апок на тому ж двигуні міняється лише profileId і моделі.
class EngineClient {
  EngineClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 120);
  String? _deviceId;

  /// Випадковий id телефона: сервер рахує за ним денні ліміти. Не містить особистих даних.
  Future<String> _device() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      final r = Random.secure();
      id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('device_id', id);
    }
    return _deviceId = id;
  }

  Future<Map<String, String>> _headers({bool json = false}) async => {
        if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
        'X-Device-Id': await _device(),
        if (json) 'Content-Type': 'application/json',
      };

  Uri _uri(String action) => Uri.parse('${AppConfig.apiUrl}/v1/${AppConfig.profileId}/$action');

  /// До 3 фото за раз (холодильник, морозилка, полиця) — сервер об'єднує продукти.
  Future<RecipesResult> analyze(List<File> images, RecipeParams params) async {
    final req = http.MultipartRequest('POST', _uri('analyze'))
      ..headers.addAll(await _headers())
      ..fields['params'] = jsonEncode(params.toJson());
    for (final img in images) {
      req.files.add(await http.MultipartFile.fromPath('image', img.path));
    }
    final streamed = await _guard(() => _client.send(req));
    final resp = await http.Response.fromStream(streamed);
    return RecipesResult.fromJson(_decode(resp));
  }

  Future<RecipesResult> refine(List<String> ingredients, RecipeParams params,
      {List<String> excludeTitles = const [], List<String> useSoon = const []}) async {
    final headers = await _headers(json: true);
    final resp = await _guard(() => _client.post(
          _uri('refine'),
          headers: headers,
          body: jsonEncode({
            'ingredients': ingredients,
            'use_soon': useSoon,
            'exclude_titles': excludeTitles,
            'params': params.toJson(),
          }),
        ));
    return RecipesResult.fromJson(_decode(resp));
  }

  /// Детальний рецепт у Markdown. Однакові страви сервер віддає з кешу (швидко й безкоштовно).
  Future<String> detail(Recipe recipe, RecipeParams params) async {
    final headers = await _headers(json: true);
    final resp = await _guard(() => _client.post(
          _uri('detail'),
          headers: headers,
          body: jsonEncode(recipe.toDetailRequest(params)),
        ));
    final body = _decode(resp);
    return (body['markdown'] as String?) ?? '';
  }

  /// Меню на кілька днів з наявних продуктів + зведений список покупок.
  Future<WeekPlan> plan(List<String> ingredients, RecipeParams params,
      {List<String> useSoon = const [], int days = 7, int mealsPerDay = 2}) async {
    final headers = await _headers(json: true);
    final resp = await _guard(() => _client.post(
          Uri.parse('${AppConfig.apiUrl}/v1/${AppConfig.profileId}/action/plan'),
          headers: headers,
          body: jsonEncode({
            'ingredients': ingredients,
            'use_soon': useSoon,
            'days': days,
            'meals_per_day': mealsPerDay,
            'params': params.toJson(),
          }),
        ));
    return WeekPlan.fromJson(_decode(resp));
  }

  /// Скарга на відповідь AI (вимога Google Play). Фото не надсилаються — лише текст відповіді.
  Future<void> report({required String content, required String reason, String comment = '', String language = 'uk'}) async {
    final resp = await _guard(() async => _client.post(
          _uri('report'),
          headers: await _headers(json: true),
          body: jsonEncode({
            'reason': reason,
            'comment': comment.trim().length > 500 ? comment.trim().substring(0, 500) : comment.trim(),
            'content': content.length > 4000 ? content.substring(0, 4000) : content,
            'language': language,
          }),
        ));
    _decode(resp);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('timeout');
    } on SocketException {
      throw ApiException('network');
    } on http.ClientException {
      throw ApiException('network');
    }
  }

  Map<String, dynamic> _decode(http.Response resp) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300 && body != null) return body;
    final code = body?['code'] as String? ?? 'http_${resp.statusCode}';
    throw ApiException(code, serverMessage: body?['message'] as String?);
  }
}
