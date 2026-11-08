import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prog_trainer/certificates/certificate_pdf.dart';
import 'package:prog_trainer/data/progress_store.dart';
import 'package:prog_trainer/models/challenge.dart';
import 'package:prog_trainer/runner/code_runner.dart';
import 'package:prog_trainer/runner/csharp_wrapper.dart';
import 'package:prog_trainer/runner/judge0_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('normalizeOutput', () {
    test('ignoriert Zeilenende-Leerzeichen und Windows-Umbrüche', () {
      expect(outputMatches('a  \r\nb\n\n', 'a\nb'), isTrue);
      expect(outputMatches('a\nb', 'a\nc'), isFalse);
    });
  });

  group('wrapCSharp', () {
    test('packt Top-Level-Code in Main, Klassen bleiben außen', () {
      final out = wrapCSharp('using System.IO;\n'
          'Console.WriteLine(new Hund().Name);\n'
          '\n'
          'class Hund\n'
          '{\n'
          '    public string Name = "Rex";\n'
          '}');
      expect(out, contains('using System;'));
      expect(out, contains('using System.IO;'));
      final main = out.indexOf('static void Main()');
      final call = out.indexOf('Console.WriteLine');
      final cls = out.indexOf('class Hund');
      expect(main, lessThan(call));
      expect(call, lessThan(cls));
      expect('using System.IO;'.allMatches(out).length, 1);
    });

    test('lässt Programme mit eigener Main-Methode in Ruhe', () {
      const code = 'class P { static void Main() { } }';
      final out = wrapCSharp(code);
      expect(out, isNot(contains('class Program')));
    });
  });

  group('Judge0Runner', () {
    test('schickt Base64 und wertet Antwort aus', () async {
      late Map<String, dynamic> sent;
      late Map<String, String> headers;
      final client = MockClient((req) async {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        headers = req.headers;
        return http.Response(
          jsonEncode({
            'stdout': base64Encode(utf8.encode('8\n')),
            'status': {'id': 3, 'description': 'Accepted'},
          }),
          200,
        );
      });
      final runner = Judge0Runner(
        baseUrl: 'https://judge0-ce.p.rapidapi.com/',
        apiKey: 'KEY',
        languageId: 51,
        client: client,
      );
      final result = await runner.run('code', stdin: '4');
      expect(result.ok, isTrue);
      expect(result.stdout, '8\n');
      expect(utf8.decode(base64Decode(sent['stdin'] as String)), '4');
      expect(headers['X-RapidAPI-Key'], 'KEY');
    });

    test('meldet Kompilierfehler', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'compile_output': base64Encode(utf8.encode('error CS1002')),
              'status': {'id': 6, 'description': 'Compilation Error'},
            }),
            200,
          ));
      final runner = Judge0Runner(
          baseUrl: 'https://x.example', apiKey: '', languageId: 51, client: client);
      final result = await runner.run('x');
      expect(result.ok, isFalse);
      expect(result.error, startsWith('Kompilierfehler'));
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
}
