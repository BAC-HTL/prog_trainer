// Web Worker: lädt .NET + Roslyn und führt C#-Code aus.
// Läuft getrennt vom Haupt-Thread, damit eine Endlosschleife per
// worker.terminate() abgebrochen werden kann.
import { dotnet } from './_framework/dotnet.js';

let exports = null;

self.onmessage = (e) => {
  const { code, stdin } = e.data;
  let result;
  try {
    result = JSON.parse(exports.Runner.Run(code, stdin));
  } catch (err) {
    result = { stdout: '', stderr: '', error: 'Interner Fehler: ' + err };
  }
  self.postMessage({ type: 'result', ...result });
};

// GitHub Pages liefert die vorgepackten .gz-Dateien nicht automatisch aus.
// Deshalb laden wir sie selbst und entpacken sie im Browser:
// ~14 MB statt ~43 MB Download (nur beim ersten Mal, danach Cache).
let compressed = 0;
function loadCompressed(type, name, defaultUri) {
  if (type === 'dotnetjs' || typeof DecompressionStream === 'undefined') return undefined;
  return fetch(defaultUri + '.gz').then((r) => {
    if (!r.ok || !r.body) return fetch(defaultUri);
    compressed++;
    return new Response(r.body.pipeThrough(new DecompressionStream('gzip')), {
      headers: {
        'content-type': type === 'dotnetwasm' ? 'application/wasm' : 'application/octet-stream',
      },
    });
  }, () => fetch(defaultUri));
}

try {
  const { getAssemblyExports, getConfig } = await dotnet
    .withResourceLoader(loadCompressed)
    .create();
  console.log(`C#-Laufzeit: ${compressed} Dateien komprimiert geladen`);
  exports = await getAssemblyExports(getConfig().mainAssemblyName);
  // Einmal aufwärmen, damit der erste echte Lauf schneller ist.
  const warm = JSON.parse(exports.Runner.Run('Console.Write(1);', ''));
  if (warm.error) console.log('Aufwärmen fehlgeschlagen: ' + warm.error);
  self.postMessage({ type: 'ready' });
} catch (e) {
  self.postMessage({ type: 'loadError', error: String(e) });
}
