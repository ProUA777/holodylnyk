/// Моделі відповіді PhotoAI Engine для профілю «plants» (той самий формат, що віддає сервер).
library;

enum Place { any, indoor, balcony, garden }

enum Health { healthy, needsAttention, sick }

enum Severity { low, medium, high }

Health healthFrom(String? s) => switch (s) {
      'sick' => Health.sick,
      'needs_attention' => Health.needsAttention,
      _ => Health.healthy,
    };

String healthToJson(Health h) => switch (h) {
      Health.sick => 'sick',
      Health.needsAttention => 'needs_attention',
      Health.healthy => 'healthy',
    };

Severity severityFrom(String? s) => switch (s) {
      'high' => Severity.high,
      'low' => Severity.low,
      _ => Severity.medium,
    };

List<String> _strings(Object? v) => ((v as List?) ?? const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();

class PlantParams {
  const PlantParams({
    this.language = 'uk',
    this.place = Place.any,
    this.pets = false,
    this.kids = false,
    this.progressFor,
    this.progressProblems = const [],
    this.progressDays,
  });

  final String language;
  final Place place;
  final bool pets;
  final bool kids;
  // перевірка лікування — лише для одного запиту, не зберігається
  final String? progressFor;
  final List<String> progressProblems;
  final int? progressDays;

  PlantParams progress(String name, List<String> problems, int days) => PlantParams(
        language: language,
        place: place,
        pets: pets,
        kids: kids,
        progressFor: name,
        progressProblems: problems.take(5).toList(),
        progressDays: days.clamp(0, 365),
      );

  PlantParams copyWith({String? language, Place? place, bool? pets, bool? kids}) => PlantParams(
        language: language ?? this.language,
        place: place ?? this.place,
        pets: pets ?? this.pets,
        kids: kids ?? this.kids,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'place': place.name,
        'pets': pets,
        'kids': kids,
        if (progressFor != null) 'progress_for': progressFor,
        if (progressFor != null) 'progress_problems': progressProblems,
        if (progressDays != null) 'progress_days': progressDays,
      };

  factory PlantParams.fromJson(Map<String, dynamic> j) => PlantParams(
        language: j['language'] as String? ?? 'uk',
        place: Place.values.firstWhere((p) => p.name == j['place'], orElse: () => Place.any),
        pets: j['pets'] as bool? ?? false,
        kids: j['kids'] as bool? ?? false,
      );
}

class Alternative {
  const Alternative({required this.name, this.latin, this.confidence = 0.3});
  final String name;
  final String? latin;
  final double confidence;

  factory Alternative.fromJson(Map<String, dynamic> j) => Alternative(
        name: j['name'] as String? ?? '',
        latin: j['latin'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.3,
      );
}

class Problem {
  const Problem({
    required this.title,
    this.cause = 'other',
    this.severity = Severity.medium,
    this.signs = '',
    this.why = '',
    this.fixNow = const [],
    this.prevention,
    this.remedies = const [],
  });

  final String title;
  final String cause; // watering | light | pests | disease | nutrients | temperature | repotting | other
  final Severity severity;
  final String signs;
  final String why;
  final List<String> fixNow;
  final String? prevention;
  final List<String> remedies; // що купити: засіб, ґрунт, горщик

  factory Problem.fromJson(Map<String, dynamic> j) => Problem(
        title: j['title'] as String? ?? '',
        cause: j['cause'] as String? ?? 'other',
        severity: severityFrom(j['severity'] as String?),
        signs: j['signs'] as String? ?? '',
        why: j['why'] as String? ?? '',
        fixNow: _strings(j['fix_now']),
        prevention: j['prevention'] as String?,
        remedies: _strings(j['remedies']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'cause': cause,
        'severity': severity.name,
        'signs': signs,
        'why': why,
        'fix_now': fixNow,
        'prevention': prevention,
        'remedies': remedies,
      };

  String get emoji => switch (cause) {
        'watering' => '💧',
        'light' => '☀️',
        'pests' => '🐛',
        'disease' => '🍂',
        'nutrients' => '🧪',
        'temperature' => '🌡️',
        'repotting' => '🪴',
        _ => '🔎',
      };
}

class Care {
  const Care({
    this.light = '',
    this.watering = '',
    this.waterEveryDays = 7,
    this.humidity = '',
    this.temperature = '',
    this.soil = '',
    this.fertilizer = '',
    this.repotting = '',
    this.pruning,
    this.winterWaterEveryDays,
  });

  final String light, watering, humidity, temperature, soil, fertilizer, repotting;
  final int waterEveryDays;
  final int? winterWaterEveryDays; // взимку при опаленні
  final String? pruning;

  factory Care.fromJson(Map<String, dynamic>? j) {
    j ??= const {};
    return Care(
      light: j['light'] as String? ?? '',
      watering: j['watering'] as String? ?? '',
      waterEveryDays: ((j['water_every_days'] as num?)?.toInt() ?? 7).clamp(1, 60),
      humidity: j['humidity'] as String? ?? '',
      temperature: j['temperature'] as String? ?? '',
      soil: j['soil'] as String? ?? '',
      fertilizer: j['fertilizer'] as String? ?? '',
      repotting: j['repotting'] as String? ?? '',
      pruning: j['pruning'] as String?,
      winterWaterEveryDays: (j['winter_water_every_days'] as num?)?.toInt().clamp(1, 90),
    );
  }

  Map<String, dynamic> toJson() => {
        'light': light,
        'watering': watering,
        'water_every_days': waterEveryDays,
        'humidity': humidity,
        'temperature': temperature,
        'soil': soil,
        'fertilizer': fertilizer,
        'repotting': repotting,
        'pruning': pruning,
        'winter_water_every_days': winterWaterEveryDays,
      };
}

class Toxicity {
  const Toxicity({this.pets, this.kids, this.note});
  final bool? pets;
  final bool? kids;
  final String? note;

  bool get isToxic => pets == true || kids == true;

  factory Toxicity.fromJson(Map<String, dynamic>? j) =>
      Toxicity(pets: j?['pets'] as bool?, kids: j?['kids'] as bool?, note: j?['note'] as String?);

  Map<String, dynamic> toJson() => {'pets': pets, 'kids': kids, 'note': note};
}

enum Trend { better, same, worse }

/// Перевірка лікування: краще / так само / гірше
class Progress {
  const Progress({this.trend = Trend.same, this.note = '', this.still = const [], this.nextStep = ''});
  final Trend trend;
  final String note;
  final List<String> still;
  final String nextStep;

  String get emoji => switch (trend) { Trend.better => '📈', Trend.same => '➖', Trend.worse => '📉' };

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
        trend: Trend.values.firstWhere((v) => v.name == j['trend'], orElse: () => Trend.same),
        note: j['note'] as String? ?? '',
        still: _strings(j['still']),
        nextStep: j['next_step'] as String? ?? '',
      );
}

class PlantResult {
  const PlantResult({
    required this.name,
    this.latin,
    this.family,
    this.confidence = 0.5,
    this.alternatives = const [],
    this.health = Health.healthy,
    this.healthSummary = '',
    this.problems = const [],
    this.care = const Care(),
    this.toxicity = const Toxicity(),
    this.todoNow = const [],
    this.funFact,
    this.symptoms = const [],
    this.progress,
  });

  final String name;
  final String? latin;
  final String? family;
  final double confidence;
  final List<Alternative> alternatives;
  final Health health;
  final String healthSummary;
  final List<Problem> problems;
  final Care care;
  final Toxicity toxicity;
  final List<String> todoNow;
  final String? funFact;

  /// Ознаки з фото — щоб перерахувати діагноз, якщо людина виправить вид
  final List<String> symptoms;

  /// Лише у відповіді на перевірку лікування
  final Progress? progress;

  bool get unsure => confidence < 0.6;

  factory PlantResult.fromJson(Map<String, dynamic> j) => PlantResult(
        name: j['name'] as String? ?? '',
        latin: j['latin'] as String?,
        family: j['family'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.5,
        alternatives: ((j['alternatives'] as List?) ?? const [])
            .map((e) => Alternative.fromJson(e as Map<String, dynamic>))
            .where((a) => a.name.isNotEmpty)
            .toList(),
        health: healthFrom(j['health'] as String?),
        healthSummary: j['health_summary'] as String? ?? '',
        problems: ((j['problems'] as List?) ?? const [])
            .map((e) => Problem.fromJson(e as Map<String, dynamic>))
            .where((p) => p.title.isNotEmpty)
            .toList(),
        care: Care.fromJson(j['care'] as Map<String, dynamic>?),
        toxicity: Toxicity.fromJson(j['toxicity'] as Map<String, dynamic>?),
        todoNow: _strings(j['todo_now']),
        funFact: j['fun_fact'] as String?,
        symptoms: _strings(j['symptoms']),
        progress: j['progress'] is Map<String, dynamic> ? Progress.fromJson(j['progress'] as Map<String, dynamic>) : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'latin': latin,
        'family': family,
        'confidence': confidence,
        'health': healthToJson(health),
        'health_summary': healthSummary,
        'problems': problems.map((p) => p.toJson()).toList(),
        'care': care.toJson(),
        'toxicity': toxicity.toJson(),
        'todo_now': todoNow,
        'fun_fact': funFact,
        'symptoms': symptoms,
      };

  /// Запит на детальний план лікування однієї проблеми
  Map<String, dynamic> detailRequest(Problem p, PlantParams params) => {
        'name': name,
        'latin': latin,
        'problem': p.title,
        'signs': p.signs,
        'params': params.toJson(),
      };
}

class PlantAnswer {
  const PlantAnswer({required this.answer, this.steps = const []});
  final String answer;
  final List<String> steps;

  factory PlantAnswer.fromJson(Map<String, dynamic> j) =>
      PlantAnswer(answer: j['answer'] as String? ?? '', steps: _strings(j['steps']));
}
