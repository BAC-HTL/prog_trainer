// Stellt window.runCSharp(code, stdin, timeoutMs) bereit.
// Die eigentliche Arbeit macht worker.js (.NET + Roslyn als WebAssembly).
const status = document.getElementById('status');
let worker = null;
let ready = null;

function startWorker() {
  worker = new Worker(new URL('./worker.js', import.meta.url), { type: 'module' });
  ready = new Promise((resolve, reject) => {
    worker.onmessage = (e) => {
      if (e.data.type === 'ready') {
        status.textContent = 'C#-Laufzeit bereit.';
        resolve();
      } else if (e.data.type === 'loadError') {
        reject(new Error(e.data.error));
      }
    };
    worker.onerror = (e) => reject(new Error(e.message || 'Worker-Fehler'));
  });
}

/** Kompiliert und startet C#-Code. Ergebnis: { stdout, stderr, error }. */
window.runCSharp = async (code, stdin, timeoutMs = 15000) => {
  if (!worker) startWorker();
  try {
    await ready;
  } catch (e) {
    if (worker) worker.terminate();
    worker = null;
    status.textContent = 'Fehler beim Laden: ' + e.message;
    return { stdout: '', stderr: '', error: 'C# konnte nicht geladen werden (Internet?): ' + e.message };
  }
  const w = worker;
  return await new Promise((resolve) => {
    const timer = setTimeout(() => {
      // Endlosschleife: Worker beenden, beim nächsten Lauf neu starten.
      w.terminate();
      worker = null;
      resolve({ stdout: '', stderr: '', error: 'TIMEOUT' });
    }, timeoutMs);
    w.onmessage = (e) => {
      if (e.data.type === 'result') {
        clearTimeout(timer);
        resolve(e.data);
      }
    };
    w.postMessage({ code, stdin });
  });
};

startWorker(); // schon im Hintergrund laden
