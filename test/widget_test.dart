import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/data/content_repository.dart';
import 'package:prog_trainer/data/progress_store.dart';
import 'package:prog_trainer/main.dart';
import 'package:prog_trainer/models/challenge.dart';
import 'package:prog_trainer/models/content.dart';
import 'package:prog_trainer/runner/code_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _track = Track(
  id: 'python',
  title: 'Python',
  description: 'Test',
  icon: 'python',
  kind: TrackKind.language,
  levelPaths: ['python/einsteiger/level.json'],
  challengesPath: 'python/challenges.json',
  runtime: 'python',
);

class FakeRepository extends ContentRepository {
  @override
  Future<List<Track>> loadTracks() async => const [
        _track,
        Track(
          id: 'testing',
          title: 'Testing',
          description: 'Test',
          icon: 'testing',
          kind: TrackKind.concept,
          levelPaths: [],
        ),
      ];

  @override
  Future<List<Level>> loadLevels(Track track) async => const [
        Level(
          id: 'python-einsteiger',
          title: 'Einsteiger',
          description: 'Start',
          chapters: [
            Chapter(
              id: 'python-e1',
              title: 'Erste Schritte',
              description: 'Kapitel',
              lessonPaths: ['l1.json'],
              examPath: 'exam.json',
            ),
          ],
        ),
      ];

  @override
  Future<Lesson> loadLesson(String path) async => const Lesson(
        id: 'l1',
        title: 'Testlektion',
        summary: 'Kurz',
        sections: [LessonSection(type: SectionType.text, content: 'Erklärung')],
        quiz: [
          QuizQuestion(
            question: 'Was ist 1 + 1?',
            options: ['1', '2'],
            correctIndex: 1,
            explanation: 'Einfach gerechnet.',
          ),
        ],
      );

  @override
  Future<Exam> loadExam(String path) async => const Exam(
        id: 'exam',
        title: 'Prüfung',
        passPercent: 70,
        questions: [
          QuizQuestion(
            question: 'Was ist 2 + 2?',
            options: ['3', '4'],
            correctIndex: 1,
            explanation: '',
          ),
        ],
      );

  @override
  Future<List<Challenge>> loadChallenges(Track track) async => const [
        Challenge(
          id: 'py-001',
          title: 'Verdoppeln',
          level: 'einsteiger',
          difficulty: 'leicht',
          points: 10,
          description: 'Gib die Zahl doppelt aus.',
          starterCode: 'n = int(input())\n',
          hints: [],
          tests: [ChallengeTest(stdin: '4', expected: '8')],
          solution: 'print(int(input()) * 2)',
        ),
      ];
}

/// Tut so, als würde der Code korrekt laufen.
class FakeRunner implements CodeRunner {
  @override
  Future<RunResult> run(String code, {String stdin = ''}) async =>
      RunResult(stdout: '${int.parse(stdin) * 2}\n');
}

Future<ProgressStore> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final progress = await ProgressStore.load();
  await tester.pumpWidget(ProgTrainerApp(
    repository: FakeRepository(),
    progress: progress,
    runnerFor: (_) => FakeRunner(),
  ));
  await tester.pumpAndSettle();
  return progress;
}

void main() {
  testWidgets('Lektion → Quiz → Prüfung bestanden', (tester) async {
    final progress = await pumpApp(tester);

    expect(find.text('Bald verfügbar'), findsOneWidget);
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erste Schritte'));
    await tester.pumpAndSettle();

    // Prüfung ist noch gesperrt.
    expect(find.textContaining('Schließe zuerst alle Lektionen ab'),
        findsOneWidget);

    await tester.tap(find.text('Testlektion'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Quiz starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ergebnis'));
    await tester.pumpAndSettle();
    expect(progress.isLessonCompleted('l1.json'), isTrue);

    await tester.tap(find.text('Zurück zum Kapitel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prüfung starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abgeben'));
    await tester.pumpAndSettle();

    expect(find.text('Bestanden! 🎉'), findsOneWidget);
    expect(progress.isExamPassed('python-e1'), isTrue);
    expect(find.text('Zertifikat herunterladen (PDF)'), findsOneWidget);
  });

  testWidgets('Herausforderung lösen gibt Punkte', (tester) async {
    final progress = await pumpApp(tester);

    await tester.tap(find.text('Herausforderungen').last);
    await tester.pumpAndSettle();
    expect(find.text('0 Punkte'), findsOneWidget);

    await tester.tap(find.text('Verdoppeln'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Prüfen'));
    await tester.tap(find.text('Prüfen'));
    await tester.pumpAndSettle();

    expect(find.text('Tests: 1 von 1 bestanden'), findsOneWidget);
    expect(progress.points('python'), 10);
    expect(progress.isUnlocked('challenge_1'), isTrue);
  });
}
