import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'code_runner.dart';

/// Führt Python direkt am Handy aus – mit Pyodide (CPython als WebAssembly)
/// in einer unsichtbaren WebView.
///
/// Der Code läuft in einem Web Worker. So kann eine Endlosschleife nach dem
/// Zeitlimit hart abgebrochen werden. Pyodide wird beim ersten Start aus
/// dem Internet geladen (~10 MB) und danach vom Browser-Cache genutzt.
class PyodideRunner implements CodeRunner {
  PyodideRunner({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  static const pyodideUrl = 'https://cdn.jsdelivr.net/pyodide/v0.29.3/full/';

  HeadlessInAppWebView? _webView;
  InAppWebViewController? _controller;
  Completer<void>? _loaded;

  Future<InAppWebViewController> _ensureStarted() async {
    if (_loaded == null) {
      final loaded = _loaded = Completer<void>();
      _webView = HeadlessInAppWebView(
        initialData: InAppWebViewInitialData(
          data: _html,
          baseUrl: WebUri('https://prog-trainer.local/'),
        ),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
        onWebViewCreated: (c) => _controller = c,
        onLoadStop: (c, url) {
          if (!loaded.isCompleted) loaded.complete();
        },
        onReceivedError: (c, request, error) {
          if (!loaded.isCompleted) loaded.completeError(error.description);
        },
      );
      await _webView!.run();
    }
    await _loaded!.future;
    return _controller!;
  }

  @override
  Future<RunResult> run(String code, {String stdin = ''}) async {
    final InAppWebViewController controller;
    try {
      controller = await _ensureStarted();
    } catch (e) {
      _loaded = null;
      return RunResult(error: 'Python-Umgebung konnte nicht starten: $e');
    }

    final result = await controller.callAsyncJavaScript(
      functionBody: 'return await window.runPython(code, stdin, timeoutMs);',
      arguments: {
        'code': code,
        'stdin': stdin,
        'timeoutMs': timeout.inMilliseconds,
      },
    );
    if (result == null || result.error != null) {
      return RunResult(error: 'Interner Fehler: ${result?.error}');
    }
    final value = Map<String, dynamic>.from(result.value as Map);
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

  Future<void> dispose() async {
    await _webView?.dispose();
    _webView = null;
    _loaded = null;
  }

  static const _html = '''
<!doctype html>
<html><head><meta charset="utf-8"></head><body>
<script id="worker-src" type="text/worker">
importScripts("$pyodideUrl" + "pyodide.js");
const pyReady = loadPyodide({ indexURL: "$pyodideUrl" }).then(
  (py) => { self.postMessage({ type: "ready" }); return py; },
  (e) => { self.postMessage({ type: "loadError", error: String(e) }); throw e; }
);
self.onmessage = async (e) => {
  const { code, stdin } = e.data;
  const py = await pyReady;
  const out = [], err = [];
  const lines = stdin.length ? stdin.split("\\n") : [];
  py.setStdin({ stdin: () => (lines.length ? lines.shift() : null) });
  py.setStdout({ batched: (s) => out.push(s) });
  py.setStderr({ batched: (s) => err.push(s) });
  let error = null;
  const globals = py.globals.get("dict")();
  try {
    await py.runPythonAsync(code, { globals });
  } catch (ex) {
    error = String(ex && ex.message ? ex.message : ex);
    // Nur die letzten Zeilen des Tracebacks sind für Lernende interessant.
    const tb = error.split("\\n").filter((l) => l.trim().length);
    const idx = tb.findIndex((l) => l.includes('File "<exec>"'));
    if (idx >= 0) error = tb.slice(idx).join("\\n");
  } finally {
    globals.destroy();
  }
  self.postMessage({ type: "result", stdout: out.join("\\n"), stderr: err.join("\\n"), error });
};
</script>
<script>
const blobUrl = URL.createObjectURL(
  new Blob([document.getElementById("worker-src").textContent], { type: "text/javascript" })
);
let worker = null, ready = null;

function startWorker() {
  worker = new Worker(blobUrl);
  ready = new Promise((resolve, reject) => {
    worker.onmessage = (e) => {
      if (e.data.type === "ready") resolve();
      else if (e.data.type === "loadError") reject(new Error(e.data.error));
    };
    worker.onerror = (e) => reject(new Error(e.message || "Worker-Fehler"));
  });
}

window.runPython = async (code, stdin, timeoutMs) => {
  if (!worker) startWorker();
  try {
    await ready;
  } catch (e) {
    if (worker) worker.terminate();
    worker = null;
    return { stdout: "", stderr: "", error: "Python konnte nicht geladen werden (Internet?): " + e.message };
  }
  const w = worker;
  return await new Promise((resolve) => {
    const timer = setTimeout(() => {
      w.terminate();
      worker = null;
      resolve({ stdout: "", stderr: "", error: "TIMEOUT" });
    }, timeoutMs);
    w.onmessage = (e) => {
      if (e.data.type === "result") {
        clearTimeout(timer);
        resolve(e.data);
      }
    };
    w.postMessage({ code, stdin });
  });
};

startWorker(); // Pyodide schon im Hintergrund laden
</script>
</body></html>
''';
}
