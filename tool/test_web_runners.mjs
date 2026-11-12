// Testet web/runners.js (Code-Ausführung der Web-Version) in Chromium.
//   node tool/test_web_runners.mjs http://localhost:8001/prog_trainer/app/
import { chromium } from 'playwright';

const url = process.argv[2];
// Vorinstalliertes Chrome der GitHub-Runner (kein Browser-Download nötig).
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || undefined });
const page = await browser.newPage();
page.on('pageerror', (e) => console.log('  [pageerror]', e.message));
await page.goto(url);

const run = async (lang, code, stdin = '', t = 20000) =>
  JSON.parse(await page.evaluate(([l, c, s, tt]) => window.progRun(l, c, s, tt),
    [lang, code, stdin, t]));

let fail = 0;
function check(name, ok, info) {
  console.log(ok ? '✓' : '✗', name, ok ? '' : JSON.stringify(info));
  if (!ok) fail++;
}

let r = await run('python', 'print("Hallo " + input())', 'Welt', 300000);
check('Python: Eingabe/Ausgabe', r.stdout.trim() === 'Hallo Welt' && !r.error, r);
r = await run('python', 'while True: pass', '', 3000);
check('Python: Endlosschleife', r.error === 'TIMEOUT', r);
r = await run('python', 'print(1/0)');
check('Python: Fehlermeldung', r.error?.includes('ZeroDivisionError'), r);
r = await run('csharp', 'Console.WriteLine("Hallo " + Console.ReadLine());', 'Welt', 300000);
check('C#: Eingabe/Ausgabe', r.stdout.trim() === 'Hallo Welt' && !r.error, r);
r = await run('csharp', 'int x = "a";');
check('C#: Kompilierfehler', r.error?.includes('CS0029'), r);

await browser.close();
console.log(fail ? `${fail} Fehler` : 'alles ok');
process.exit(fail ? 1 : 0);
