/// Моделі відповіді PhotoAI Engine для профілю «repair».
library;

enum Skill { beginner, handy, pro }

enum Safety { diy, careful, pro }

enum Difficulty { easy, medium, hard }

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

List<String> _strings(Object? v) => ((v as List?) ?? const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();

class RepairParams {
  const RepairParams({this.language = 'uk', this.skill = Skill.handy, this.verifyThing, this.verifyCause});
  final String language;
  final Skill skill;
  // перевірка «після ремонту» — лише для одного запиту, не зберігається
  final String? verifyThing;
  final String? verifyCause;

  RepairParams copyWith({String? language, Skill? skill}) =>
      RepairParams(language: language ?? this.language, skill: skill ?? this.skill);

  RepairParams verify(String thing, String? cause) =>
      RepairParams(language: language, skill: skill, verifyThing: thing, verifyCause: cause);

  Map<String, dynamic> toJson() => {
        'language': language,
        'skill': skill.name,
        if (verifyThing != null) 'verify_thing': verifyThing,
        if (verifyCause != null) 'verify_cause': verifyCause,
      };

  factory RepairParams.fromJson(Map<String, dynamic> j) =>
      RepairParams(language: j['language'] as String? ?? 'uk', skill: _enum(Skill.values, j['skill'], Skill.handy));
}

class Cause {
  const Cause({
    required this.title,
    this.likelihood = 0.5,
    this.why = '',
    this.check = '',
    this.fix = const [],
    this.difficulty = Difficulty.medium,
    this.minutes = 30,
  });

  final String title;
  final double likelihood;
  final String why;
  final String check;
  final List<String> fix;
  final Difficulty difficulty;
  final int minutes;

  factory Cause.fromJson(Map<String, dynamic> j) => Cause(
        title: j['title'] as String? ?? '',
        likelihood: ((j['likelihood'] as num?)?.toDouble() ?? 0.5).clamp(0, 1),
        why: j['why'] as String? ?? '',
        check: j['check'] as String? ?? '',
        fix: _strings(j['fix']),
        difficulty: _enum(Difficulty.values, j['difficulty'], Difficulty.medium),
        minutes: ((j['minutes'] as num?)?.toInt() ?? 30).clamp(1, 2000),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'likelihood': likelihood,
        'why': why,
        'check': check,
        'fix': fix,
        'difficulty': difficulty.name,
        'minutes': minutes,
      };
}

class Part {
  const Part({required this.name, this.isTool = true, this.price});
  final String name;
  final bool isTool;
  final String? price;

  factory Part.fromJson(Map<String, dynamic> j) =>
      Part(name: j['name'] as String? ?? '', isTool: j['is_tool'] as bool? ?? true, price: j['price'] as String?);

  Map<String, dynamic> toJson() => {'name': name, 'is_tool': isTool, 'price': price};
}

/// Оцінка фото «після ремонту».
class AfterCheck {
  const AfterCheck({this.ok = false, this.issues = const [], this.advice = ''});
  final bool ok;
  final List<String> issues;
  final String advice;

  factory AfterCheck.fromJson(Map<String, dynamic> j) =>
      AfterCheck(ok: j['ok'] as bool? ?? false, issues: _strings(j['issues']), advice: j['advice'] as String? ?? '');
}

/// Регулярна справа, щоб не зламалось знову: «почистити фільтр» раз на 90 днів.
class Maintenance {
  const Maintenance({required this.task, this.everyDays = 90});
  final String task;
  final int everyDays;

  factory Maintenance.fromJson(Map<String, dynamic> j) =>
      Maintenance(task: j['task'] as String? ?? '', everyDays: ((j['every_days'] as num?)?.toInt() ?? 90).clamp(7, 730));

  Map<String, dynamic> toJson() => {'task': task, 'every_days': everyDays};
}

class RepairResult {
  const RepairResult({
    required this.thing,
    this.brandModel,
    this.category = 'other',
    this.confidence = 0.6,
    this.summary = '',
    this.safety = Safety.careful,
    this.safetyNote = '',
    this.causes = const [],
    this.parts = const [],
    this.proCost,
    this.signs = const [],
    this.maintenance = const [],
    this.after,
  });

  final String thing;
  final String? brandModel;
  final String category;
  final double confidence;
  final String summary;
  final Safety safety;
  final String safetyNote;
  final List<Cause> causes;
  final List<Part> parts;
  final String? proCost;
  final List<String> signs; // ознаки з фото — для перерахунку
  final List<Maintenance> maintenance;
  final AfterCheck? after; // лише у відповіді на перевірку після ремонту

  List<Part> get tools => parts.where((p) => p.isTool).toList();
  List<Part> get spares => parts.where((p) => !p.isTool).toList();

  String get emoji => switch (category) {
        'appliance' => '🧺',
        'plumbing' => '🚰',
        'electrical' => '🔌',
        'electronics' => '📱',
        'furniture' => '🪑',
        'walls_floor' => '🧱',
        'doors_windows' => '🚪',
        'car_bike' => '🚲',
        'clothing' => '🧵',
        _ => '🔧',
      };

  factory RepairResult.fromJson(Map<String, dynamic> j) => RepairResult(
        thing: j['thing'] as String? ?? '',
        brandModel: j['brand_model'] as String?,
        category: j['category'] as String? ?? 'other',
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.6,
        summary: j['summary'] as String? ?? '',
        safety: _enum(Safety.values, j['safety'], Safety.careful),
        safetyNote: j['safety_note'] as String? ?? '',
        causes: ((j['causes'] as List?) ?? const [])
            .map((e) => Cause.fromJson(e as Map<String, dynamic>))
            .where((c) => c.title.isNotEmpty)
            .toList(),
        parts: ((j['parts'] as List?) ?? const [])
            .map((e) => Part.fromJson(e as Map<String, dynamic>))
            .where((p) => p.name.isNotEmpty)
            .toList(),
        proCost: j['pro_cost'] as String?,
        signs: _strings(j['signs']),
        maintenance: ((j['maintenance'] as List?) ?? const [])
            .map((e) => Maintenance.fromJson(e as Map<String, dynamic>))
            .where((m) => m.task.trim().isNotEmpty)
            .toList(),
        after: j['after'] is Map<String, dynamic> ? AfterCheck.fromJson(j['after'] as Map<String, dynamic>) : null,
      );

  Map<String, dynamic> toJson() => {
        'thing': thing,
        'brand_model': brandModel,
        'category': category,
        'confidence': confidence,
        'summary': summary,
        'safety': safety.name,
        'safety_note': safetyNote,
        'causes': causes.map((c) => c.toJson()).toList(),
        'parts': parts.map((p) => p.toJson()).toList(),
        'pro_cost': proCost,
        'signs': signs,
        'maintenance': maintenance.map((m) => m.toJson()).toList(),
      };
}

class RepairAnswer {
  const RepairAnswer({required this.answer, this.steps = const []});
  final String answer;
  final List<String> steps;

  factory RepairAnswer.fromJson(Map<String, dynamic> j) =>
      RepairAnswer(answer: j['answer'] as String? ?? '', steps: _strings(j['steps']));
}
