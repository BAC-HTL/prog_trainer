import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';

import 'code_runner.dart';

/// Definiert in web/runners.js.
@JS('progRun')
external JSPromise<JSString> _progRun(
    JSString language, JSString code, JSString stdin, JSNumber timeoutMs);

/// Browser: Python (Pyodide) und C# (Roslyn + .NET als WebAssembly) laufen
/// direkt in der Seite – siehe web/runners.js.
class BrowserRunner implements CodeRunner {
  BrowserRunner(this.language, this.timeout);

  final String language;
  final Duration timeout;

  @override
  Future<RunResult> run(String code, {String stdin = ''}) async {
    final Map<String, dynamic> value;
    try {
      final raw = await _progRun(language.toJS, code.toJS, stdin.toJS,
              timeout.inMilliseconds.toJS)
          .toDart;
      value = jsonDecode(raw.toDart) as Map<String, dynamic>;
    } catch (e) {
      return RunResult(error: 'Interner Fehler: $e');
    }
    final error = value['error'] as String?;
    return RunResult(
      stdout: value['stdout'] as String? ?? '',
      stderr: value['stderr'] as String? ?? '',
      error: error == null
          ? null
          : error == 'TIMEOUT'
              ? 'Zeitlimit überschritten (Endlosschleife?)'
              : error,
    );
  }
}

Map<String, CodeRunner> createRunners() => {
      'python': BrowserRunner('python', const Duration(seconds: 10)),
      'csharp': BrowserRunner('csharp', const Duration(seconds: 15)),
    };

List<Widget> runtimeHosts(Iterable<CodeRunner?> runners) => const [];

@JS('progDownload')
external void _progDownload(JSString name, JSString text);

@JS('progPickFile')
external JSPromise<JSString> _progPickFile();

const bool supportsBackupFiles = true;

Future<void> downloadTextFile(String name, String text) async =>
    _progDownload(name.toJS, text.toJS);

/// `null`, wenn nichts ausgewählt wurde.
Future<String?> pickTextFile() async {
  final text = (await _progPickFile().toDart).toDart;
  return text.isEmpty ? null : text;
}
