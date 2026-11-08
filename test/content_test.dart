import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/models/content.dart';

/// Prüft alle Inhaltsdateien, damit kaputte JSON-Dateien oder falsche
/// Antwort-Indizes sofort auffallen.
void main() {
  const base = 'assets/content';

  final indexJson =
      jsonDecode(File('$base/index.json').readAsStringSync()) as Map<String, dynamic>;
  final tracks = (indexJson['tracks'] as List)
      .map((t) => Track.fromJson(t as Map<String, dynamic>))
      .toList();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('Track-IDs sind eindeutig', () {
    final ids = tracks.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final track in tracks) {
    for (final path in track.lessonPaths) {
      group('${track.id}: $path', () {
        test('Datei existiert und ist in pubspec.yaml eingetragen', () {
          expect(File('$base/$path').existsSync(), isTrue);
          final folder = path.substring(0, path.lastIndexOf('/') + 1);
          expect(pubspec.contains('$base/$folder'), isTrue,
              reason: 'Ordner $base/$folder fehlt unter assets in pubspec.yaml');
        });

        test('Lektion ist gültig', () {
          final lesson = Lesson.fromJson(
            jsonDecode(File('$base/$path').readAsStringSync())
                as Map<String, dynamic>,
          );
          expect(lesson.sections, isNotEmpty);
          for (final q in lesson.quiz) {
            expect(q.options.length, greaterThanOrEqualTo(2));
            expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1),
                reason: q.question);
          }
        });
      });
    }
  }
}
