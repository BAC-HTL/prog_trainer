// Testet die C#-Laufzeit (csharp_runtime/) in einem echten Browser.
//
//   node tool/test_csharp_runtime.mjs http://localhost:8000/
//
// Voraussetzung: npm install playwright && npx playwright install chromium
// und die veröffentlichte Laufzeit wird unter der URL ausgeliefert.
//
// Geprüft wird:
//  * Grundfunktionen (Eingabe, Kompilier-/Laufzeitfehler, Endlosschleife,
//    modernes C#, Kommazahlen)
//  * alle C#-Musterlösungen der Herausforderungen
//  * alle C#-Musterlösungen der Spielmissionen: die Ereignisse müssen exakt
//    mit der Python-Simulation übereinstimmen
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const url = process.argv[2] ?? 'http://localhost:8000/';
const browser = await chromium.launch();
const page = await browser.newPage();
page.on('console', (m) => console.log('  [browser]', m.text()));
page.on('pageerror', (e) => console.log('  [pageerror]', e.message));
await page.goto(url);

const run = (code, stdin = '', timeoutMs = 20000) =>
  page.evaluate(([c, s, t]) => window.runCSharp(c, s, t), [code, stdin, timeoutMs]);

let failures = 0;
let passed = 0;
function check(name, ok, info) {
  if (ok) {
    passed++;
  } else {
    failures++;
    console.log('✗', name, JSON.stringify(info).slice(0, 600));
  }
}
const norm = (s) =>
  s.replace(/\r\n/g, '\n').split('\n').map((l) => l.trimEnd()).join('\n').trimEnd();

// ---------- Grundfunktionen ----------
let t0 = Date.now();
let r = await run('Console.WriteLine("Hallo " + Console.ReadLine());', 'Welt', 300000);
console.log(`Erster Lauf (inkl. Laden): ${Date.now() - t0} ms`);
check('Eingabe/Ausgabe', norm(r.stdout) === 'Hallo Welt' && !r.error, r);

t0 = Date.now();
r = await run('for (int i = 0; i < 3; i++) Console.Write(i);');
console.log(`Zweiter Lauf: ${Date.now() - t0} ms`);
check('Schleife', r.stdout === '012', r);

r = await run('int x = "a";');
check('Kompilierfehler mit Zeile', r.error?.includes('CS0029') && r.error.includes('Zeile 1'), r);

r = await run('int[] a = new int[1];\nConsole.WriteLine(a[5]);');
check('Laufzeitfehler', r.error?.includes('IndexOutOfRange'), r);

r = await run('var p = new P(3);\nConsole.WriteLine(p);\nConsole.WriteLine(p.X switch { 3 => "drei", _ => "?" });\n\nrecord P(int X);');
check('Modernes C# (record, switch-Ausdruck)', norm(r.stdout) === 'P { X = 3 }\ndrei', r);

r = await run('Console.WriteLine(1.5);\nConsole.WriteLine(3.4.ToString("0.00"));');
check('Kommazahlen mit Punkt', norm(r.stdout) === '1.5\n3.40', r);

r = await run('while (true) { }', '', 3000);
check('Endlosschleife wird abgebrochen', r.error === 'TIMEOUT', r);

r = await run('Console.WriteLine("nach Neustart");');
check('Neustart nach Endlosschleife', norm(r.stdout) === 'nach Neustart', r);

// ---------- Herausforderungen ----------
const challenges = JSON.parse(
  readFileSync('assets/content/csharp/challenges.json', 'utf8')).challenges;
for (const c of challenges) {
  for (const [i, test] of c.tests.entries()) {
    r = await run(c.solution, test.stdin ?? '');
    check(`${c.id} Test ${i + 1}`, !r.error && norm(r.stdout) === norm(test.expected),
      { expected: test.expected, got: r });
  }
}
console.log(`Herausforderungen: ${challenges.length} geprüft`);

// ---------- Spielmissionen ----------
const pySim = readFileSync('assets/game/robot_sim.py', 'utf8');
const csSim = readFileSync('assets/game/RobotSim.cs', 'utf8');
const index = JSON.parse(readFileSync('assets/game/index.json', 'utf8'));
const missions = index.files.flatMap(
  (f) => JSON.parse(readFileSync(`assets/game/${f}`, 'utf8')).missions);
const events = (out) => out.split('\n').filter((l) => l.startsWith('@@')).join('\n');

for (const m of missions) {
  for (const [i, v] of m.variants.entries()) {
    const y = v.map.findIndex((row) => row.includes('R'));
    const x = v.map[y].indexOf('R');
    const stdin = `${x} ${y} ${v.dir} ${m.energy}\n` +
      v.map.map((row) => row.replace('R', '.')).join('\n') + '\n';
    const py = execFileSync('python3',
      ['-c', `${pySim}\n_starte(${JSON.stringify(m.solution.python)})\n`],
      { input: stdin }).toString();
    r = await run(`${m.solution.csharp}\n\n${csSim}`, stdin);
    check(`${m.id} Karte ${i + 1}: gleiche Ereignisse wie Python`,
      !r.error && events(r.stdout) === events(py),
      { error: r.error, cs: events(r.stdout).slice(0, 200), py: events(py).slice(0, 200) });
  }
}
console.log(`Missionen: ${missions.length} geprüft`);

await browser.close();
console.log(`${passed} bestanden, ${failures} Fehler.`);
process.exit(failures ? 1 : 0);
