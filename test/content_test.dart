import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/models/challenge.dart';
import 'package:prog_trainer/models/content.dart';

/// Prüft alle Inhaltsdateien, damit kaputte JSON-Dateien, fehlende Dateien
/// oder falsche Antwort-Indizes sofort auffallen.
const base = 'assets/content';

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File('$base/$path').readAsStringSync()) as Map<String, dynamic>;

void checkQuestions(List<QuizQuestion> questions) {
  for (final q in questions) {
    expect(q.options.length, greaterThanOrEqualTo(2), reason: q.question);
    expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1),
        reason: q.question);
  }
}

void main() {
  final tracks = (readJson('index.json')['tracks'] as List)
      .map((t) => Track.fromJson(t as Map<String, dynamic>))
      .toList();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  void expectAssetFolder(String path) {
    final folder = path.substring(0, path.lastIndexOf('/') + 1);
    expect(pubspec.contains('- $base/$folder\n'), isTrue,
        reason: 'Ordner $base/$folder fehlt unter assets in pubspec.yaml');
  }

  test('Track-IDs sind eindeutig', () {
    final ids = tracks.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  final allIds = <String>{};

  for (final track in tracks) {
    for (final levelPath in track.levelPaths) {
      final level = Level.fromJson(readJson(levelPath));
      group('${track.id}/${level.title}', () {
        test('level.json in pubspec eingetragen', () {
          expectAssetFolder(levelPath);
        });

        for (final chapter in level.chapters) {
          for (final path in chapter.lessonPaths) {
            test('Lektion $path', () {
              expect(File('$base/$path').existsSync(), isTrue,
                  reason: 'Datei fehlt');
              expectAssetFolder(path);
              final lesson = Lesson.fromJson(readJson(path));
              expect(lesson.sections, isNotEmpty);
              expect(allIds.add(lesson.id), isTrue,
                  reason: 'doppelte ID ${lesson.id}');
              checkQuestions(lesson.quiz);
            });
          }
          if (chapter.examPath != null) {
            test('Prüfung ${chapter.examPath}', () {
              expect(File('$base/${chapter.examPath}').existsSync(), isTrue,
                  reason: 'Datei fehlt');
              final exam = Exam.fromJson(readJson(chapter.examPath!));
              expect(exam.questions.length, greaterThanOrEqualTo(5));
              expect(exam.passPercent, inInclusiveRange(1, 100));
              checkQuestions(exam.questions);
            });
          }
        }
      });
    }

    if (track.challengesPath != null) {
      test('${track.id}: Herausforderungen', () {
        expectAssetFolder(track.challengesPath!);
        final list = (readJson(track.challengesPath!)['challenges'] as List)
            .map((c) => Challenge.fromJson(c as Map<String, dynamic>))
            .toList();
        final ids = <String>{};
        for (final c in list) {
          expect(ids.add(c.id), isTrue, reason: 'doppelte ID ${c.id}');
          expect(c.tests, isNotEmpty, reason: c.id);
          expect(c.points, greaterThan(0), reason: c.id);
          expect(levelTitles.keys, contains(c.level), reason: c.id);
          expect(c.solution, isNotEmpty, reason: c.id);
        }
      });
    }
  }
}
