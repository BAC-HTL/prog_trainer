import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/data/content_repository.dart';
import 'package:prog_trainer/main.dart';
import 'package:prog_trainer/models/content.dart';

class FakeRepository extends ContentRepository {
  static const lesson = Lesson(
    id: 'test-01',
    title: 'Testlektion',
    summary: 'Kurz',
    sections: [
      LessonSection(type: SectionType.text, content: 'Erklärung'),
      LessonSection(type: SectionType.code, content: 'print("hi")'),
    ],
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
  Future<List<Track>> loadTracks() async => const [
        Track(
          id: 'python',
          title: 'Python',
          description: 'Test',
          icon: 'python',
          kind: TrackKind.language,
          lessonPaths: ['python/test.json'],
        ),
        Track(
          id: 'testing',
          title: 'Testing',
          description: 'Test',
          icon: 'testing',
          kind: TrackKind.concept,
          lessonPaths: [],
        ),
      ];

  @override
  Future<Lesson> loadLesson(String path) async => lesson;
}

void main() {
  testWidgets('Startseite → Lektion → Quiz → Ergebnis', (tester) async {
    await tester.pumpWidget(ProgTrainerApp(repository: FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Bald verfügbar'), findsOneWidget);

    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Testlektion'));
    await tester.pumpAndSettle();

    expect(find.text('Erklärung'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('Richtig! 🎉'), findsOneWidget);

    await tester.tap(find.text('Ergebnis'));
    await tester.pumpAndSettle();
    expect(find.text('1 von 1 richtig'), findsOneWidget);
  });
}
