/// Моделі відповіді PhotoAI Engine для профілю «homework».
library;

enum Mode { learn, check }

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

List<String> _strings(Object? v) => ((v as List?) ?? const []).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();

class HomeworkParams {
  const HomeworkParams({this.language = 'uk', this.grade = 7, this.mode = Mode.learn});
  final String language;
  final int grade; // 1–11 клас, 12 — студент/дорослий
  final Mode mode;

  HomeworkParams copyWith({String? language, int? grade, Mode? mode}) =>
      HomeworkParams(language: language ?? this.language, grade: grade ?? this.grade, mode: mode ?? this.mode);

  Map<String, dynamic> toJson() => {'language': language, 'grade': grade, 'mode': mode.name};

  factory HomeworkParams.fromJson(Map<String, dynamic> j) => HomeworkParams(
        language: j['language'] as String? ?? 'uk',
        grade: ((j['grade'] as num?)?.toInt() ?? 7).clamp(1, 12),
        mode: _enum(Mode.values, j['mode'], Mode.learn),
      );
}

class SolutionStep {
  const SolutionStep({required this.text, this.formula});
  final String text;
  final String? formula;

  factory SolutionStep.fromJson(Map<String, dynamic> j) => SolutionStep(text: j['text'] as String? ?? '', formula: j['formula'] as String?);
  Map<String, dynamic> toJson() => {'text': text, 'formula': formula};
}

class Mistake {
  const Mistake({required this.where, required this.what});
  final String where;
  final String what;

  factory Mistake.fromJson(Map<String, dynamic> j) => Mistake(where: j['where'] as String? ?? '', what: j['what'] as String? ?? '');
  Map<String, dynamic> toJson() => {'where': where, 'what': what};
}

class Solution {
  const Solution({
    this.number,
    this.task = '',
    this.topic = '',
    this.idea = '',
    this.hints = const [],
    this.steps = const [],
    this.answer = '',
    this.check = '',
    this.similar,
    this.similarAnswer,
    this.studentCorrect,
    this.mistakes = const [],
    this.praise,
  });

  final String? number;
  final String task;
  final String topic;
  final String idea;
  final List<String> hints;
  final List<SolutionStep> steps;
  final String answer;
  final String check;
  final String? similar;
  final String? similarAnswer;
  final bool? studentCorrect; // лише в режимі перевірки
  final List<Mistake> mistakes;
  final String? praise;

  bool get checked => studentCorrect != null;

  factory Solution.fromJson(Map<String, dynamic> j) => Solution(
        number: j['number'] as String?,
        task: j['task'] as String? ?? '',
        topic: j['topic'] as String? ?? '',
        idea: j['idea'] as String? ?? '',
        hints: _strings(j['hints']),
        steps: ((j['steps'] as List?) ?? const [])
            .map((e) => SolutionStep.fromJson(e as Map<String, dynamic>))
            .where((s) => s.text.trim().isNotEmpty)
            .toList(),
        answer: j['answer'] as String? ?? '',
        check: j['check'] as String? ?? '',
        similar: j['similar'] as String?,
        similarAnswer: j['similar_answer'] as String?,
        studentCorrect: j['student_correct'] as bool?,
        mistakes: ((j['mistakes'] as List?) ?? const []).map((e) => Mistake.fromJson(e as Map<String, dynamic>)).toList(),
        praise: j['praise'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'task': task,
        'topic': topic,
        'idea': idea,
        'hints': hints,
        'steps': steps.map((s) => s.toJson()).toList(),
        'answer': answer,
        'check': check,
        'similar': similar,
        'similar_answer': similarAnswer,
        'student_correct': studentCorrect,
        'mistakes': mistakes.map((m) => m.toJson()).toList(),
        'praise': praise,
      };
}

class HomeworkResult {
  const HomeworkResult({this.subject = 'other', this.readable = true, this.solutions = const []});
  final String subject;
  final bool readable;
  final List<Solution> solutions;

  String get emoji => subjectEmoji(subject);

  factory HomeworkResult.fromJson(Map<String, dynamic> j) => HomeworkResult(
        subject: j['subject'] as String? ?? 'other',
        readable: j['readable'] as bool? ?? true,
        solutions: ((j['solutions'] as List?) ?? const []).map((e) => Solution.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() =>
      {'subject': subject, 'readable': readable, 'solutions': solutions.map((s) => s.toJson()).toList()};
}

String subjectEmoji(String s) => switch (s) {
      'math' || 'algebra' => '🔢',
      'geometry' => '📐',
      'physics' => '⚛️',
      'chemistry' => '🧪',
      'biology' => '🧬',
      'language' => '🔤',
      'literature' => '📖',
      'history' => '🏛️',
      'geography' => '🌍',
      'informatics' => '💻',
      _ => '📚',
    };

class StepAnswer {
  const StepAnswer({required this.answer, this.example});
  final String answer;
  final String? example;

  factory StepAnswer.fromJson(Map<String, dynamic> j) =>
      StepAnswer(answer: j['answer'] as String? ?? '', example: j['example'] as String?);
}
