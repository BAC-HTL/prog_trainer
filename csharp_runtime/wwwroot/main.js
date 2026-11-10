// Stellt window.runCSharp(code, stdin, timeoutMs) bereit.
// Die eigentliche Arbeit macht worker.js (.NET + Roslyn als WebAssembly).
const status = document.getElementById('status');
let worker = null;
let ready = null;
let runs = 0;

// Jeder Lauf lädt ein neues Assembly, das nie mehr entladen wird. Damit der
// Speicher am Handy nicht vollläuft, gibt es regelmäßig einen frischen Worker
// (dauert ~2 s, die Dateien kommen aus dem Cache).
const RUNS_PER_WORKER = 15;

function stopWorker() {
  if (worker) worker.terminate();
  worker = null;
}

function startWorker() {
  runs = 0;
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
  let result = await runOnce(code, stdin, timeoutMs);
  if (result.error === 'CRASH') {
    console.log('C#-Laufzeit abgestürzt (' + result.detail + '), Neustart …');
    stopWorker();
    result = await runOnce(code, stdin, timeoutMs);
    if (result.error === 'CRASH') {
      stopWorker();
      result = {
        stdout: '',
        stderr: '',
        error: 'Dein Programm hat die C#-Laufzeit zum Absturz gebracht – ' +
          'meist wegen einer Endlosschleife oder zu viel Speicherverbrauch.',
      };
    }
  }
  delete result.type;
  delete result.detail;
  return result;
};

async function runOnce(code, stdin, timeoutMs) {
  if (worker && runs >= RUNS_PER_WORKER) stopWorker();
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
  runs++;
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
    w.onerror = (e) => {
      clearTimeout(timer);
      resolve({ stdout: '', stderr: '', error: 'CRASH', detail: e.message || 'Worker-Fehler' });
    };
    w.postMessage({ code, stdin });
  });
}

startWorker(); // schon im Hintergrund laden
