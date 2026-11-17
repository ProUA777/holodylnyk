import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../app.dart';
import 'catalog.dart';

enum ApiError { limit, badPhoto, network, server, generic }

class ApiException implements Exception {
  final ApiError kind;
  final String? detail;
  const ApiException(this.kind, [this.detail]);
  @override
  String toString() => 'ApiException($kind, $detail)';
}

/// An idea returned by the AI for the user's own pile.
class AiIdea {
  final String id, title, emoji, diff, desc;
  final int minutes;
  final List<String> uses;
  final List<BuildStep> steps;

  const AiIdea({
    required this.id,
    required this.title,
    required this.emoji,
    required this.diff,
    required this.desc,
    required this.minutes,
    required this.uses,
    required this.steps,
  });

  bool get has3d => steps.any((s) => s.bricks.isNotEmpty);

  factory AiIdea.fromJson(Map j, int index) {
    final steps = <BuildStep>[];
    var budget = 60; // never render more than 60 AI bricks
    for (final s in (j['steps'] as List? ?? const [])) {
      if (s is String) {
        steps.add(BuildStep(label: 'details', text: s, bricks: const []));
      } else if (s is Map) {
        final bricks = [for (final b in (s['bricks'] as List? ?? const [])) Brick.tryParse(b)].whereType<Brick>().take(max(0, budget)).toList();
        budget -= bricks.length;
        steps.add(BuildStep(label: 'details', text: (s['text'] ?? '').toString(), bricks: bricks));
      }
    }
    final diff = j['difficulty']?.toString();
    final title = (j['title'] ?? '').toString();
    return AiIdea(
      id: 'ai-${title.toLowerCase().hashCode.toRadixString(36)}-$index',
      title: title,
      emoji: (j['emoji'] ?? '🧱').toString(),
      diff: const ['easy', 'medium', 'hard', 'expert'].contains(diff) ? diff! : 'medium',
      desc: (j['description'] ?? '').toString(),
      minutes: (j['minutes'] is num) ? (j['minutes'] as num).toInt() : 15,
      uses: [for (final u in (j['uses'] as List? ?? const [])) u.toString()],
      steps: steps,
    );
  }
}

class PieceColor {
  final String name, hex;
  final int? count;
  const PieceColor(this.name, this.hex, this.count);
}

class ScanResult {
  final bool readable;
  final String? retakeHint;
  final int? total;
  final List<PieceColor> colors;
  final List<String> notable;
  final List<AiIdea> ideas;
  final int remaining;

  /// What the photo shows: pile | instructions | built | other.
  final String source;

  /// For instructions/built models: what is depicted ("a golden dragon").
  final String? depicted;

  /// Catalog models the AI picked for this photo: (id, why).
  final List<(String, String)> matches;

  const ScanResult({
    this.source = 'pile',
    this.depicted,
    this.matches = const [],
    required this.readable,
    this.retakeHint,
    this.total,
    required this.colors,
    required this.notable,
    required this.ideas,
    required this.remaining,
  });

  factory ScanResult.fromJson(Map r, int remaining) {
    final pieces = (r['pieces'] as Map?) ?? const {};
    return ScanResult(
      readable: r['readable'] != false,
      source: const ['pile', 'instructions', 'built', 'other'].contains(r['source']) ? r['source'] as String : 'pile',
      depicted: (r['depicted'] is String && (r['depicted'] as String).trim().isNotEmpty) ? (r['depicted'] as String).trim() : null,
      matches: [
        for (final m in (r['matches'] as List? ?? const []))
          if (m is Map && m['id'] is String) (m['id'] as String, (m['why'] ?? '').toString()),
      ],
      retakeHint: r['retake_hint']?.toString(),
      total: (pieces['total_estimate'] as num?)?.toInt(),
      colors: [
        for (final c in (pieces['colors'] as List? ?? const []))
          if (c is Map) PieceColor((c['name'] ?? '').toString(), (c['hex'] ?? '').toString(), (c['count'] as num?)?.toInt())
          else PieceColor(c.toString(), '', null),
      ],
      notable: [for (final n in (pieces['notable'] as List? ?? const [])) n.toString()],
      ideas: [
        for (final (i, e) in (r['ideas'] as List? ?? const []).indexed)
          if (e is Map) AiIdea.fromJson(e, i),
      ],
      remaining: remaining,
    );
  }
}

class Api {
  /// Flags an AI answer (Google Play AI-generated content policy). Sends only text, never the photo.
  static Future<bool> report({required String reason, required String content, required String lang}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(Uri.parse('${AppConfig.apiBase}/v1/report'));
      req.headers
        ..set('X-App-Key', AppConfig.appKey)
        ..contentType = ContentType.json;
      req.write(jsonEncode({
        'profile': AppConfig.profileId,
        'lang': lang,
        'reason': reason,
        'content': content.length > 3900 ? content.substring(0, 3900) : content,
      }));
      final res = await req.close().timeout(const Duration(seconds: 15));
      await res.drain<void>();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  static Future<ScanResult> analyze(File photo, {required String lang, required String deviceId}) async {
    final uri = Uri.parse('${AppConfig.apiBase}/v1/analyze/${AppConfig.profileId}');
    final boundary = 'wtb${Random().nextInt(1 << 32).toRadixString(16)}${DateTime.now().microsecondsSinceEpoch}';
    final bytes = await photo.readAsBytes();
    final head = StringBuffer()
      ..write('--$boundary\r\nContent-Disposition: form-data; name="lang"\r\n\r\n$lang\r\n')
      ..write('--$boundary\r\nContent-Disposition: form-data; name="image"; filename="photo.jpg"\r\nContent-Type: image/jpeg\r\n\r\n');
    final tail = '\r\n--$boundary--\r\n';

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(uri);
      req.headers
        ..set('X-App-Key', AppConfig.appKey)
        ..set('X-Device-Id', deviceId)
        ..contentType = ContentType('multipart', 'form-data', parameters: {'boundary': boundary});
      final headBytes = utf8.encode(head.toString()), tailBytes = utf8.encode(tail);
      req.contentLength = headBytes.length + bytes.length + tailBytes.length;
      req
        ..add(headBytes)
        ..add(bytes)
        ..add(tailBytes);
      final res = await req.close().timeout(const Duration(seconds: 120));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode == 429) throw const ApiException(ApiError.limit);
      if (res.statusCode == 400 || res.statusCode == 413) throw const ApiException(ApiError.badPhoto);
      if (res.statusCode >= 500) throw ApiException(ApiError.server, text);
      if (res.statusCode != 200) throw ApiException(ApiError.generic, '${res.statusCode} $text');
      final data = jsonDecode(text) as Map;
      return ScanResult.fromJson(data['result'] as Map, (data['remaining_today'] as num?)?.toInt() ?? 0);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(ApiError.network);
    } on HandshakeException {
      throw const ApiException(ApiError.network);
    } on TimeoutException {
      throw const ApiException(ApiError.server);
    } on FormatException catch (e) {
      throw ApiException(ApiError.generic, e.message);
    } finally {
      client.close(force: true);
    }
  }
}
