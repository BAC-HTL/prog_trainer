import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/data/content_repository.dart';
import 'package:prog_trainer/data/progress_store.dart';
import 'package:prog_trainer/game/mission.dart';
import 'package:prog_trainer/main.dart';
import 'package:prog_trainer/models/challenge.dart';
import 'package:prog_trainer/models/content.dart';
import 'package:prog_trainer/models/curriculum.dart';
import 'package:prog_trainer/runner/code_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _track = Track(
  id: 'python',
  title: 'Python',
  description: 'Test',
  icon: 'python',
  challengesPath: 'python/challenges.json',
  runtime: 'python',
);

const _content = ModuleContent(
    id: 'python-e1', lessonPaths: ['l1.json'], examPath: 'exam.json');

const _curriculum = Curriculum(
  stages: [
    Stage(id: 'j1', title: '1. Jahrgang', group: 'htl', description: 'Start'),
    Stage(id: 'j2', title: '2. Jahrgang', group: 'htl', description: 'Weiter'),
  ],
  subjects: [
    Subject(id: 'POS', title: 'Programmieren und Software Engineering', icon: 'code'),
    Subject(id: 'NVS', title: 'Netzwerksysteme und Verteilte Systeme', icon: 'lan'),
  ],
  topics: [
    Topic(id: 'programmieren', title: 'Programmieren'),
    Topic(id: 'netzwerke', title: 'Netzwerke'),
  ],
  languages: [Language('python', 'Python'), Language('csharp', 'C#')],
  modules: [
    CurriculumModule(
      id: 'pos-j1-erste-schritte',
      stage: 'j1',
      subject: 'POS',
      semester: 1,
      title: 'Erste Schritte',
      description: 'Kapitel',
      topics: ['programmieren'],
      variants: {
        'python': _content,
        'csharp': ModuleContent(
            id: 'csharp-e1', lessonPaths: ['c1.json'], examPath: 'exam.json'),
      },
    ),
    CurriculumModule(
      id: 'pos-j1-leer',
      stage: 'j1',
      subject: 'POS',
      title: 'Leeres Modul',
      description: 'Noch ohne Inhalt',
      topics: ['programmieren'],
      neutral: ModuleContent(id: 'pos-j1-leer', lessonPaths: []),
    ),
    CurriculumModule(
      id: 'nvs-j2-grundlagen',
      stage: 'j2',
      subject: 'NVS',
      semester: 3,
      title: 'Netzwerk-Grundlagen',
      description: 'Medien und Protokolle',
      topics: ['netzwerke'],
      neutral: ModuleContent(
          id: 'nvs-j2-grundlagen', lessonPaths: ['n1.json'], examPath: 'exam.json'),
    ),
  ],
);

class FakeRepository extends ContentRepository {
  @override
  Future<List<Track>> loadTracks() async => const [_track];

  @override
  Future<Curriculum> loadCurriculum() async => _curriculum;

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

  @override
  Future<List<Mission>> loadMissions() async => const [
        Mission(
          id: 'm01',
          title: 'Landung',
          story: 'Fahr zur Basis.',
          concept: 'Befehle',
          energy: 10,
          variants: [
            MissionVariant(map: ['#####', '#R.Z#', '#####'], dir: 'O'),
          ],
          goals: [Goal(type: 'basis')],
          parEnergy: 2,
          parLines: {'python': 2, 'csharp': 2},
          hints: [],
          starter: {'python': 'robot.vor()\n', 'csharp': 'Robot.Vor();\n'},
          solution: {'python': '', 'csharp': ''},
        ),
      ];

  @override
  Future<String> loadSimulation(String language) async => '# SIM';
}

/// Tut so, als würde der Code korrekt laufen.
class FakeRunner implements CodeRunner {
  @override
  Future<RunResult> run(String code, {String stdin = ''}) async {
    if (code.contains('_starte(')) {
      // Spielmodus: Roboter fährt zwei Felder zur Basis.
      return const RunResult(
          stdout: '@@START 1 1 O 10\n@@MOVE 2 1 9\nHallo Xeno\n@@MOVE 3 1 8\n');
    }
    return RunResult(stdout: '${int.parse(stdin) * 2}\n');
  }
}

Future<ProgressStore> pumpApp(WidgetTester tester) async {
  // Großer Bildschirm, damit alle Buttons ohne Scrollen sichtbar sind.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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

    // 1. Jahrgang ist vorausgewählt; das leere Modul ist noch gesperrt.
    expect(find.textContaining('Bald verfügbar'), findsOneWidget);
    expect(find.text('Netzwerk-Grundlagen'), findsNothing);
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

    await tester.tap(find.text('Aufgaben'));
    await tester.pumpAndSettle();
    expect(find.text('0 Punkte'), findsOneWidget);

    await tester.tap(find.text('Verdoppeln'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prüfen'));
    await tester.pumpAndSettle();

    expect(find.text('Tests: 1 von 1 bestanden'), findsOneWidget);
    expect(progress.points('python'), 10);
    expect(progress.isUnlocked('challenge_1'), isTrue);
  });

  testWidgets('Spielmission erfüllen gibt Sterne und Punkte', (tester) async {
    final progress = await pumpApp(tester);

    await tester.tap(find.text('Spiel'));
    await tester.pumpAndSettle();
    expect(find.text('Expedition Xeno-7'), findsOneWidget);

    await tester.tap(find.text('Landung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roboter starten'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pumpAndSettle();

    expect(find.text('Mission erfüllt! 🎉'), findsOneWidget);
    expect(find.text('+30 Punkte'), findsOneWidget);
    expect(find.text('Hallo Xeno'), findsOneWidget);
    expect(progress.missionStars('python', 'm01'), 3);
    expect(progress.points('python'), 30);
    expect(progress.isUnlocked('mission_1'), isTrue);
  });

  testWidgets('Stufen, Themenfilter und Sprachwahl', (tester) async {
    final progress = await pumpApp(tester);

    // Stufe wechseln
    await tester.tap(find.text('2. Jahrgang'));
    await tester.pumpAndSettle();
    expect(find.text('Netzwerk-Grundlagen'), findsOneWidget);
    expect(find.text('Erste Schritte'), findsNothing);

    // Alle Stufen
    await tester.tap(find.text('Alle'));
    await tester.pumpAndSettle();
    expect(find.text('Netzwerk-Grundlagen'), findsOneWidget);
    expect(find.text('Erste Schritte'), findsOneWidget);

    // Nach Thema filtern
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Netzwerke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anzeigen'));
    await tester.pumpAndSettle();
    expect(find.text('Netzwerk-Grundlagen'), findsOneWidget);
    expect(find.text('Erste Schritte'), findsNothing);

    // Sprache umstellen
    await tester.tap(find.text('C#'));
    await tester.pumpAndSettle();
    expect(progress.language, 'csharp');
  });
}
