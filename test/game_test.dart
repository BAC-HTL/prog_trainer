import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prog_trainer/game/game_logic.dart';
import 'package:prog_trainer/game/mission.dart';

const _mission = Mission(
  id: 't1',
  title: 'Test',
  story: '',
  concept: '',
  energy: 10,
  variants: [
    MissionVariant(map: ['######', '#RKLZ#', '######'], dir: 'O'),
  ],
  goals: [
    Goal(type: 'basis'),
    Goal(type: 'herstellen', item: 'energiezelle'),
    Goal(type: 'alle', item: 'kristall'),
  ],
  parEnergy: 3,
  parLines: {'python': 5, 'csharp': 7},
  hints: [],
  starter: {},
  solution: {},
);

void main() {
  test('Eingabe für die Simulation', () {
    expect(simulationInput(_mission, _mission.variants.first),
        '1 1 O 10\n######\n#.KLZ#\n######\n');
  });

  test('Programm wird je Sprache richtig zusammengebaut', () {
    expect(buildProgram('python', 'SIM', 'robot.vor()\n'),
        'SIM\n_starte("robot.vor()\\n")\n');
    expect(buildProgram('csharp', 'SIM', 'Robot.Vor();'), 'Robot.Vor();\n\nSIM');
  });

  test('Ereignisse abspielen und Ziele prüfen', () {
    final out = parseOutput('@@START 1 1 O 10\n'
        'hallo\n'
        '@@MOVE 2 1 9\n'
        '@@PICK kristall 2 1\n'
        '@@MOVE 3 1 8\n'
        '@@MIX kristall wasser energiezelle\n'
        '@@MOVE 4 1 7\n');
    expect(out.console, ['hallo']);
    final v = _mission.variants.first;
    final end = replay(_mission, v, out.events);
    expect((end.x, end.y), (4, 1));
    expect(end.energyUsed, 3);
    expect(end.grid[1][2], '.');
    // "wasser" war nie im Inventar → remove() ignoriert es, energiezelle zählt.
    expect(end.inventory, ['energiezelle']);
    expect(checkGoals(_mission, v, end), [true, true, true]);
  });

  test('Fehler werden übersetzt', () {
    final end = replay(_mission, _mission.variants.first,
        parseOutput('@@START 1 1 O 10\n@@FEHLER FELS\n').events);
    expect(end.error, contains('Felsen'));
    final code = replay(_mission, _mission.variants.first,
        parseOutput('@@START 1 1 O 10\n@@CODE Zeile 2: NameError: x\n').events);
    expect(code.error, contains('Zeile 2'));
  });

  test('Codezeilen und Sterne', () {
    expect(countCodeLines('# Kommentar\nrobot.vor()\n\nrobot.vor()\n', 'python'), 2);
    expect(countCodeLines('// x\nfor (int i = 0; i < 3; i++)\n{\n    Robot.Vor();\n}\n', 'csharp'), 2);
    expect(computeStars(mission: _mission, language: 'python', energyUsed: 3, lines: 5), 3);
    expect(computeStars(mission: _mission, language: 'python', energyUsed: 4, lines: 5), 2);
    expect(computeStars(mission: _mission, language: 'csharp', energyUsed: 9, lines: 9), 1);
  });

  test('Alle Missionsdateien sind gültig', () {
    final index = jsonDecode(File('assets/game/index.json').readAsStringSync())
        as Map<String, dynamic>;
    final ids = <String>{};
    for (final f in List<String>.from(index['files'] as List)) {
      final json = jsonDecode(File('assets/game/$f').readAsStringSync())
          as Map<String, dynamic>;
      for (final m in (json['missions'] as List)
          .map((m) => Mission.fromJson(m as Map<String, dynamic>))) {
        expect(ids.add(m.id), isTrue, reason: 'doppelte ID ${m.id}');
        expect(m.variants, isNotEmpty);
        for (final v in m.variants) {
          v.start; // wirft, wenn kein R
          expect(v.map.every((r) => r.length == v.width), isTrue, reason: m.id);
        }
        expect(m.starter.keys, containsAll(['python', 'csharp']));
        expect(m.parLines.keys, containsAll(['python', 'csharp']));
      }
    }
    expect(ids, isNotEmpty);
  });
}
