import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/certificates/certificate_pdf.dart';
import 'package:prog_trainer/data/progress_store.dart';
import 'package:prog_trainer/models/challenge.dart';
import 'package:prog_trainer/runner/code_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('normalizeOutput', () {
    test('ignoriert Zeilenende-Leerzeichen und Windows-Umbrüche', () {
      expect(outputMatches('a  \r\nb\n\n', 'a\nb'), isTrue);
      expect(outputMatches('a\nb', 'a\nc'), isFalse);
    });
  });

  group('ProgressStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Punkte gibt es nur beim ersten Lösen, Achievements werden freigeschaltet',
        () async {
      final store = await ProgressStore.load();
      final unlocked = <String>[];
      store.onAchievementUnlocked = (a) => unlocked.add(a.id);
      const c = Challenge(
        id: 'py-001',
        title: 't',
        level: 'einsteiger',
        difficulty: 'leicht',
        points: 10,
        description: '',
        starterCode: '',
        hints: [],
        tests: [],
        solution: '',
      );
      expect(await store.solveChallenge('python', c), isTrue);
      expect(await store.solveChallenge('python', c), isFalse);
      expect(store.points('python'), 10);
      expect(store.points('csharp'), 0);
      expect(unlocked, contains('challenge_1'));

      await store.completeLesson('python/einsteiger/a.json');
      expect(unlocked, contains('lektion_1'));

      // Neu laden: alles bleibt gespeichert.
      final reloaded = await ProgressStore.load();
      expect(reloaded.points('python'), 10);
      expect(reloaded.isLessonCompleted('python/einsteiger/a.json'), isTrue);
      expect(reloaded.isUnlocked('challenge_1'), isTrue);
    });

    test('bestes Prüfungsergebnis bleibt erhalten', () async {
      final store = await ProgressStore.load();
      ExamResult r(int p) => ExamResult(
            trackId: 'python',
            trackTitle: 'Python',
            levelTitle: 'Einsteiger',
            chapterTitle: 'Schleifen',
            percent: p,
            passed: p >= 70,
            date: DateTime(2026, 11, 8),
          );
      await store.recordExam('python-e3', r(80));
      await store.recordExam('python-e3', r(50));
      expect(store.examResult('python-e3')!.percent, 80);
      await store.recordExam('python-e3', r(100));
      expect(store.examResult('python-e3')!.percent, 100);
      expect(store.isUnlocked('perfekt'), isTrue);
    });
  });

  test('Zertifikat-PDF wird erzeugt (auch mit Sonderzeichen)', () async {
    final bytes = await buildCertificate(
      name: 'Jürgen Müller – 😀',
      trackTitle: 'C#',
      levelTitle: 'Einsteiger',
      chapterTitle: 'Arrays & Strings',
      percent: 90,
      date: DateTime(2026, 11, 8),
    );
    expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
    expect(certificateFileName('C#', 'Arrays & Strings'),
        'zertifikat_csharp_arrays_strings.pdf');
  });

  group('Sichern & Übertragen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Übertragungscode und Datei stellen den Fortschritt wieder her', () async {
      final a = await ProgressStore.load();
      await a.setUserName('Anna');
      await a.setLanguage('csharp');
      await a.completeLesson('l1.json');
      await a.recordMission('python', 'm01', 3);
      final code = a.exportCode();
      final file = a.exportJson();
      expect(code, startsWith('PT1:'));

      for (final backup in [code, file]) {
        SharedPreferences.setMockInitialValues({});
        final b = await ProgressStore.load();
        await b.completeLesson('andere.json');
        await b.importBackup(backup);
        expect(b.isLessonCompleted('l1.json'), isTrue);
        expect(b.isLessonCompleted('andere.json'), isFalse);
        expect(b.missionStars('python', 'm01'), 3);
        expect(b.points('python'), 30);
        expect(b.userName, 'Anna');
        expect(b.language, 'csharp');
        // Bleibt nach Neustart erhalten.
        final c = await ProgressStore.load();
        expect(c.isLessonCompleted('l1.json'), isTrue);
      }
    });

    test('Ungültige Sicherung ändert nichts', () async {
      final s = await ProgressStore.load();
      await s.completeLesson('l1.json');
      for (final bad in ['Hallo', 'PT1:!!!', '{"progress": {}}']) {
        await expectLater(s.importBackup(bad), throwsFormatException);
      }
      expect(s.isLessonCompleted('l1.json'), isTrue);
    });
  });
}
