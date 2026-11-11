// Code-Ausführung für die Web-Version der App.
//
//   window.progRun(sprache, code, stdin, timeoutMs) → Promise<JSON-Text>
//   Ergebnis: { stdout, stderr, error }   (error === "TIMEOUT" bei Zeitlimit)
//
// * Python: Pyodide in einem Web Worker (wie in der Handy-App).
// * C#: die C#-Laufzeit von ../csharp/ (Roslyn + .NET als WebAssembly),
//   erst beim ersten C#-Lauf geladen.
// Außerdem: den Browser bitten, den gespeicherten Fortschritt dauerhaft
// aufzuheben (navigator.storage.persist).
(() => {
  const PYODIDE = 'https://cdn.jsdelivr.net/pyodide/v0.29.3/full/';

  const workerSource = `
importScripts("${PYODIDE}" + "pyodide.js");
const pyReady = loadPyodide({ indexURL: "${PYODIDE}" }).then(
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
    const tb = error.split("\\n").filter((l) => l.trim().length);
    const idx = tb.findIndex((l) => l.includes('File "<exec>"'));
    if (idx >= 0) error = tb.slice(idx).join("\\n");
  } finally {
    globals.destroy();
  }
  self.postMessage({ type: "result", stdout: out.join("\\n"), stderr: err.join("\\n"), error });
};`;
  const blobUrl = URL.createObjectURL(new Blob([workerSource], { type: 'text/javascript' }));
  let worker = null;
  let ready = null;

  function startWorker() {
    worker = new Worker(blobUrl);
    ready = new Promise((resolve, reject) => {
      worker.onmessage = (e) => {
        if (e.data.type === 'ready') resolve();
        else if (e.data.type === 'loadError') reject(new Error(e.data.error));
      };
      worker.onerror = (e) => reject(new Error(e.message || 'Worker-Fehler'));
    });
  }

  async function runPython(code, stdin, timeoutMs) {
    if (!worker) startWorker();
    try {
      await ready;
    } catch (e) {
      if (worker) worker.terminate();
      worker = null;
      return { stdout: '', stderr: '', error: 'Python konnte nicht geladen werden (Internet?): ' + e.message };
    }
    const w = worker;
    return await new Promise((resolve) => {
      const timer = setTimeout(() => {
        w.terminate();
        worker = null;
        resolve({ stdout: '', stderr: '', error: 'TIMEOUT' });
      }, timeoutMs);
      w.onmessage = (e) => {
        if (e.data.type === 'result') {
          clearTimeout(timer);
          resolve({ stdout: e.data.stdout, stderr: e.data.stderr, error: e.data.error });
        }
      };
      w.postMessage({ code, stdin });
    });
  }

  let csharpLoaded = null;
  async function runCSharp(code, stdin, timeoutMs) {
    try {
      // Setzt window.runCSharp (siehe csharp_runtime/wwwroot/main.js).
      csharpLoaded ??= import(new URL('../csharp/main.js', document.baseURI).href);
      await csharpLoaded;
    } catch (e) {
      csharpLoaded = null;
      return { stdout: '', stderr: '', error: 'C# konnte nicht geladen werden (Internet?): ' + e };
    }
    return await window.runCSharp(code, stdin, timeoutMs);
  }

  window.progRun = async (language, code, stdin, timeoutMs) => {
    let result;
    try {
      result = language === 'python'
        ? await runPython(code, stdin, timeoutMs)
        : await runCSharp(code, stdin, timeoutMs);
    } catch (e) {
      result = { stdout: '', stderr: '', error: 'Interner Fehler: ' + e };
    }
    return JSON.stringify(result);
  };

  // Fortschritt (localStorage) möglichst nicht automatisch löschen lassen.
  try {
    navigator.storage?.persist?.();
  } catch (_) { /* ältere Browser */ }
})();

// Sicherungsdatei herunterladen / einlesen (Einstellungen → Fortschritt).
window.progDownload = (name, text) => {
  const url = URL.createObjectURL(new Blob([text], { type: 'application/json' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
};

window.progPickFile = () => new Promise((resolve) => {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.json,application/json,text/plain';
  input.onchange = async () => {
    const file = input.files && input.files[0];
    resolve(file ? await file.text() : '');
  };
  input.addEventListener('cancel', () => resolve(''));
  input.click();
});
