/// Baut C#-Code mit Top-Level-Statements in ein klassisches Programm mit
/// `Main`-Methode um.
///
/// Hintergrund: Der Judge0-Server hat nur Mono (≈ C# 7), das kennt noch
/// keine Top-Level-Statements und keine impliziten usings.
///
/// - `using`-Direktiven wandern nach oben, Standard-usings werden ergänzt.
/// - Typ-Deklarationen (class, struct, enum, interface), die in Spalte 0
///   beginnen, kommen außerhalb von `Main`.
/// - Alles andere wird zum Rumpf von `Main` (Methoden dort werden zu
///   lokalen Funktionen).
///
/// Eine Python-Kopie davon steht in `tool/verify_challenges.py` – bei
/// Änderungen beide anpassen!
library;

const _defaultUsings = [
  'using System;',
  'using System.Collections.Generic;',
  'using System.Linq;',
  'using System.Text;',
];

final _mainRe = RegExp(r'static\s+(void|int|async\s+Task(<int>)?)\s+Main\s*\(');
final _typeRe = RegExp(
  r'^((public|internal|static|abstract|sealed|partial)\s+)*'
  r'(class|struct|enum|interface)\s+\w+',
);

String wrapCSharp(String code) {
  final lines = code.replaceAll('\r\n', '\n').split('\n');
  final usings = <String>[];
  final types = <String>[];
  final body = <String>[];
  var inType = false;
  var depth = 0;

  for (final line in lines) {
    final t = line.trim();
    if (!inType &&
        t.startsWith('using ') &&
        t.endsWith(';') &&
        !t.contains('=') &&
        !t.contains('(')) {
      usings.add(t);
      continue;
    }
    if (!inType && _typeRe.hasMatch(line)) {
      inType = true;
      depth = 0;
    }
    if (inType) {
      types.add(line);
      depth += '{'.allMatches(line).length - '}'.allMatches(line).length;
      if (depth <= 0 && line.contains('}')) inType = false;
      continue;
    }
    body.add(line);
  }

  final header = <String>[];
  for (final u in [..._defaultUsings, ...usings]) {
    if (!header.contains(u)) header.add(u);
  }

  if (_mainRe.hasMatch(code)) {
    return '${[...header, ...body, ...types].join('\n')}\n';
  }
  return '${[
    ...header,
    '',
    'class Program',
    '{',
    'static void Main()',
    '{',
    ...body,
    '}',
    '}',
    '',
    ...types,
  ].join('\n')}\n';
}
