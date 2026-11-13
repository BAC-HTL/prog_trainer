import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/models/challenge.dart';
import 'package:prog_trainer/models/content.dart';
import 'package:prog_trainer/models/curriculum.dart';

/// Prüft den Lehrplan und alle Inhaltsdateien, damit kaputte JSON-Dateien,
/// fehlende Dateien oder falsche Antwort-Indizes sofort auffallen.
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
  final curriculum = Curriculum.fromJson(readJson('curriculum.json'));
  final tracks = (readJson('index.json')['tracks'] as List)
      .map((t) => Track.fromJson(t as Map<String, dynamic>))
      .toList();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  void expectAssetFolder(String path) {
    final folder = path.substring(0, path.lastIndexOf('/') + 1);
    expect(pubspec.contains('- $base/$folder\n'), isTrue,
        reason: 'Ordner $base/$folder fehlt unter assets in pubspec.yaml');
  }

  group('Lehrplan', () {
    test('IDs sind eindeutig, Verweise gültig', () {
      final stageIds = curriculum.stages.map((s) => s.id).toSet();
      final subjectIds = curriculum.subjects.map((s) => s.id).toSet();
      final topicIds = curriculum.topics.map((t) => t.id).toSet();
      final languageIds = curriculum.languages.map((l) => l.id).toSet();
      final moduleIds = <String>{};
      final contentIds = <String>{};
      for (final m in curriculum.modules) {
        expect(moduleIds.add(m.id), isTrue, reason: 'doppeltes Modul ${m.id}');
        expect(stageIds, contains(m.stage), reason: m.id);
        expect(subjectIds, contains(m.subject), reason: m.id);
        expect(topicIds, containsAll(m.topics), reason: m.id);
        expect(languageIds, containsAll(m.variants.keys), reason: m.id);
        for (final c in [...m.variants.values, if (m.neutral != null) m.neutral!]) {
          expect(contentIds.add(c.id), isTrue,
              reason: 'doppelte Fortschritts-ID ${c.id}');
          // Module mit Lektionen brauchen eine Abschlussprüfung.
          if (c.isAvailable) expect(c.examPath, isNotNull, reason: m.id);
        }
      }
    });

    test('Jeder HTL-Jahrgang hat Module, 1.–5. Jahrgang sind verfügbar', () {
      for (final s in curriculum.stages) {
        expect(curriculum.modules.where((m) => m.stage == s.id), isNotEmpty,
            reason: s.title);
      }
      for (final stage in ['j1', 'j2', 'j3', 'j4', 'j5']) {
        for (final m in curriculum.modules.where((m) => m.stage == stage)) {
          final contents = [...m.variants.values, if (m.neutral != null) m.neutral!];
          expect(contents.every((c) => c.isAvailable), isTrue,
              reason: '${m.id} hat noch keine Lektionen');
        }
      }
    });
  });

  final lessonIds = <String>{};
  final seenPaths = <String>{};

  for (final m in curriculum.modules) {
    final contents = <String, ModuleContent>{
      ...m.variants,
      if (m.neutral != null) 'neutral': m.neutral!,
    };
    for (final entry in contents.entries) {
      final c = entry.value;
      if (!c.isAvailable) continue;
      group('${m.id} (${entry.key})', () {
        for (final path in c.lessonPaths) {
          test('Lektion $path', () {
            expect(seenPaths.add(path), isTrue,
                reason: 'Lektion in mehreren Modulen verwendet');
            expect(File('$base/$path').existsSync(), isTrue, reason: 'Datei fehlt');
            expectAssetFolder(path);
            final lesson = Lesson.fromJson(readJson(path));
            expect(lesson.sections, isNotEmpty);
            expect(lessonIds.add(lesson.id), isTrue,
                reason: 'doppelte ID ${lesson.id}');
            checkQuestions(lesson.quiz);
          });
        }
        test('Prüfung ${c.examPath}', () {
          expect(File('$base/${c.examPath}').existsSync(), isTrue,
              reason: 'Datei fehlt');
          expectAssetFolder(c.examPath!);
          final exam = Exam.fromJson(readJson(c.examPath!));
          expect(exam.questions.length, greaterThanOrEqualTo(5));
          expect(exam.passPercent, inInclusiveRange(1, 100));
          checkQuestions(exam.questions);
        });
      });
    }
  }

  for (final track in tracks) {
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
