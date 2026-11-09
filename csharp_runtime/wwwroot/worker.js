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

try {
  const { getAssemblyExports, getConfig } = await dotnet.create();
  exports = await getAssemblyExports(getConfig().mainAssemblyName);
  // Einmal aufwärmen, damit der erste echte Lauf schneller ist.
  exports.Runner.Run('Console.Write(1);', '');
  self.postMessage({ type: 'ready' });
} catch (e) {
  self.postMessage({ type: 'loadError', error: String(e) });
}
