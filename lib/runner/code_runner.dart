import '../models/challenge.dart';

/// Ergebnis einer Code-Ausführung.
class RunResult {
  const RunResult({this.stdout = '', this.stderr = '', this.error});

  final String stdout;
  final String stderr;

  /// Kompilier-/Laufzeitfehler, Zeitüberschreitung o. Ä. `null` = alles ok.
  final String? error;

  bool get ok => error == null;
}

/// Führt Code einer bestimmten Sprache aus.
abstract class CodeRunner {
  Future<RunResult> run(String code, {String stdin = ''});
}

/// Vereinheitlicht Ausgaben für den Vergleich: Windows-Zeilenenden,
/// Leerzeichen am Zeilenende und Leerzeilen am Schluss werden ignoriert.
String normalizeOutput(String s) {
  return s
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) => line.trimRight())
      .join('\n')
      .trimRight();
}

bool outputMatches(String actual, String expected) =>
    normalizeOutput(actual) == normalizeOutput(expected);

class TestOutcome {
  const TestOutcome({
    required this.test,
    required this.result,
    required this.passed,
  });

  final ChallengeTest test;
  final RunResult result;
  final bool passed;
}

/// Führt alle Testfälle nacheinander aus.
Future<List<TestOutcome>> runTests(
  CodeRunner runner,
  String code,
  List<ChallengeTest> tests,
) async {
  final outcomes = <TestOutcome>[];
  for (final test in tests) {
    final result = await runner.run(code, stdin: test.stdin);
    outcomes.add(TestOutcome(
      test: test,
      result: result,
      passed: result.ok && outputMatches(result.stdout, test.expected),
    ));
    // Kompilierfehler betreffen alle Tests gleich – nicht unnötig wiederholen.
    if (result.error != null && result.error!.startsWith('Kompilierfehler')) {
      break;
    }
  }
  return outcomes;
}
