import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'code_runner.dart';

/// Adresse der C#-Laufzeit (Roslyn + .NET als WebAssembly, siehe
/// `csharp_runtime/`). Wird mit der Doku auf GitHub Pages veröffentlicht.
const csharpRuntimeUrl = 'https://bac-htl.github.io/prog_trainer/csharp/';

/// Führt Code direkt am Handy in einer unsichtbaren WebView aus – ohne
/// Server und ohne Anmeldung.
///
/// * Python: Pyodide (CPython als WebAssembly)
/// * C#: Roslyn + .NET als WebAssembly
///
/// In beiden Fällen läuft der Code in einem Web Worker, den die Seite nach
/// dem Zeitlimit beendet (Endlosschleifen). Die Laufzeit wird beim ersten
/// Mal aus dem Internet geladen und danach vom Browser-Cache genutzt.
///
/// Die WebView entsteht erst beim ersten Ausführen und wird über
/// [RuntimeHost] (1×1 Pixel, unsichtbar) in den Widget-Baum gehängt.
class WebViewRunner implements CodeRunner {
  WebViewRunner._({
    required this.label,
    required this.jsFunction,
    this.html,
    this.url,
    this.timeout = const Duration(seconds: 15),
  });

  factory WebViewRunner.python() => WebViewRunner._(
        label: 'Python',
        jsFunction: 'runPython',
        html: _pythonHtml,
        timeout: const Duration(seconds: 10),
      );

  factory WebViewRunner.csharp() => WebViewRunner._(
        label: 'C#',
        jsFunction: 'runCSharp',
        url: csharpRuntimeUrl,
      );

  final String label;
  final String jsFunction;
  final String? html;
  final String? url;

  /// Zeitlimit pro Ausführung (wird in der Seite durchgesetzt).
  final Duration timeout;

  /// Aktueller WebView-Controller (oder `null`, solange nie etwas lief).
  final ValueNotifier<WebViewController?> controller = ValueNotifier(null);

  Completer<void>? _ready;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  int _nextId = 0;

  WebViewController _ensureController() {
    final existing = controller.value;
    if (existing != null) return existing;

    final ready = _ready = Completer<void>();
    final c = WebViewController();
    c.setJavaScriptMode(JavaScriptMode.unrestricted);
    c.addJavaScriptChannel('RunnerBridge', onMessageReceived: _onMessage);
    c.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) {
        if (!ready.isCompleted) ready.complete();
      },
      onWebResourceError: (error) {
        if ((error.isForMainFrame ?? false) && !ready.isCompleted) {
          ready.completeError(error.description);
        }
      },
    ));
    if (html != null) {
      c.loadHtmlString(html!, baseUrl: 'https://prog-trainer.local/');
    } else {
      c.loadRequest(Uri.parse(url!));
    }
    controller.value = c;
    return c;
  }

  void _onMessage(JavaScriptMessage message) {
    final data = jsonDecode(message.message) as Map<String, dynamic>;
    _pending.remove(data['id'] as int?)?.complete(data);
  }

  void _reset() {
    controller.value = null;
    _ready = null;
  }

  @override
  Future<RunResult> run(String code, {String stdin = ''}) async {
    final c = _ensureController();
    try {
      await _ready!.future.timeout(const Duration(seconds: 60));
    } catch (e) {
      _reset();
      return RunResult(
          error: '$label konnte nicht gestartet werden (Internet?): $e');
    }

    final id = _nextId++;
    final completer = _pending[id] = Completer<Map<String, dynamic>>();
    try {
      await c.runJavaScript(
        'window.$jsFunction(${jsonEncode(code)}, ${jsonEncode(stdin)}, '
        '${timeout.inMilliseconds}).then('
        'function (r) { r.id = $id; RunnerBridge.postMessage(JSON.stringify(r)); },'
        'function (e) { RunnerBridge.postMessage(JSON.stringify('
        '{ id: $id, stdout: "", stderr: "", error: String(e) })); });',
      );
    } catch (e) {
      _pending.remove(id);
      return RunResult(error: 'Interner Fehler: $e');
    }

    // Großzügig, weil beim ersten Mal die Laufzeit heruntergeladen wird.
    final value = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pending.remove(id);
        _reset();
        return {'error': '$label hat nicht geantwortet (Internet?)'};
      },
    );
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

  static const _pythonHtml = '''
<!doctype html>
<html><head><meta charset="utf-8"></head><body>
<script id="worker-src" type="text/worker">
const PYODIDE = "https://cdn.jsdelivr.net/pyodide/v0.29.3/full/";
importScripts(PYODIDE + "pyodide.js");
const pyReady = loadPyodide({ indexURL: PYODIDE }).then(
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

/// Hängt die WebView eines [WebViewRunner] unsichtbar in den Widget-Baum,
/// damit sie auf allen Plattformen zuverlässig JavaScript ausführt.
class RuntimeHost extends StatelessWidget {
  const RuntimeHost({super.key, required this.runner});

  final WebViewRunner runner;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WebViewController?>(
      valueListenable: runner.controller,
      builder: (context, controller, _) {
        if (controller == null) return const SizedBox.shrink();
        return IgnorePointer(
          child: Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: WebViewWidget(controller: controller),
            ),
          ),
        );
      },
    );
  }
}
