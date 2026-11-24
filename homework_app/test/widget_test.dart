import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yak_rozvyazaty/history.dart';
import 'package:yak_rozvyazaty/l10n.dart';
import 'package:yak_rozvyazaty/models.dart';
import 'package:yak_rozvyazaty/screens/splash_screen.dart';

// Відповідь сервера в тому ж форматі, що віддає PhotoAI Engine (профіль homework)
final sample = {
  'detected': true,
  'subject': 'algebra',
  'readable': false,
  'solutions': [
    {
      'number': '№ 245',
      'task': 'Розв’яжіть рівняння: 2x + 3 = 11',
      'topic': 'Лінійні рівняння',
      'idea': 'Залиш x сам.',
      'hints': ['a', 'b', 'c'],
      'steps': [
        {'text': 'Переносимо 3', 'formula': '2x = 8'},
        {'text': ' '},
      ],
      'answer': 'x = 4',
      'check': '2·4 + 3 = 11',
      'similar': '3x − 4 = 11',
      'similar_answer': 'x = 5',
      'student_correct': false,
      'mistakes': [
        {'where': 'рядок 1', 'what': 'знак'},
      ],
    },
  ],
};

void main() {
  test('HomeworkResult parses engine response', () {
    final r = HomeworkResult.fromJson(sample);
    expect(r.emoji, '🔢');
    expect(r.readable, isFalse);
    final s = r.solutions.single;
    expect(s.steps.length, 1); // порожній крок відкинуто
    expect(s.checked, isTrue);
    expect(s.mistakes.single.where, 'рядок 1');
    final back = HomeworkResult.fromJson(r.toJson());
    expect(back.solutions.single.similarAnswer, 'x = 5');
    expect(HomeworkParams.fromJson(const HomeworkParams(grade: 12, mode: Mode.check).toJson()).mode, Mode.check);
    expect(HomeworkParams.fromJson({'grade': 40}).grade, 12);
  });

  test('history keeps starred, plurals', () async {
    SharedPreferences.setMockInitialValues({});
    final h = HistoryStore();
    final first = await h.add(HomeworkResult.fromJson(sample));
    await h.toggleStar(first);
    for (var i = 0; i < 45; i++) {
      await h.add(HomeworkResult.fromJson(sample));
    }
    expect(h.items.length, 40);
    expect(h.items.any((e) => e.id == first.id), isTrue); // ⭐ не видаляється
    expect(first.title, 'Лінійні рівняння');
    final again = HistoryStore();
    await again.load();
    expect(again.items.length, 40);

    final uk = supportedStrings['uk']!, pl = supportedStrings['pl']!;
    expect(uk.gradeLabel(7), '7 клас');
    expect(uk.gradeLabel(12), 'Студент');
    expect(uk.tasksN(1), '1 завдання');
    expect(uk.tasksN(5), '5 завдань');
    expect(pl.tasksN(2), '2 zadania');
    expect(pl.tasksN(5), '5 zadań');
  });

  testWidgets('splash: Koreec → app icon → disappears', (tester) async {
    await tester.pumpWidget(L10n(
      strings: supportedStrings['uk']!,
      child: const MaterialApp(home: AnimatedSplash(child: Text('ГОЛОВНА'))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('Як розв’язати?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Як розв’язати?'), findsNothing);
    expect(find.text('ГОЛОВНА'), findsOneWidget);
  });
}
