import 'dart:convert';

import 'mission.dart';

/// Logik des Spielmodus: Programm zusammenbauen, Ereignisse der Simulation
/// auswerten, Ziele und Sterne berechnen.
///
/// Spiegelt tool/verify_missions.py – bei Änderungen beide anpassen!

/// Standardeingabe für die Simulation: Startwerte + Karte.
String simulationInput(Mission mission, MissionVariant variant) {
  final (x, y) = variant.start;
  final rows = variant.map.map((r) => r.replaceAll('R', '.')).join('\n');
  return '$x $y ${variant.dir} ${mission.energy}\n$rows\n';
}

/// Baut aus Simulation + Nutzer-Code das auszuführende Programm.
String buildProgram(String language, String simSource, String userCode) {
  if (language == 'python') {
    return '$simSource\n_starte(${jsonEncode(userCode)})\n';
  }
  return 'Robot.Start();\n$userCode\n\n$simSource';
}

class GameEvent {
  const GameEvent(this.kind, this.args);

  final String kind;
  final List<String> args;

  @override
  String toString() => '$kind ${args.join(' ')}';
}

class SimulationOutput {
  const SimulationOutput(this.events, this.console);

  final List<GameEvent> events;

  /// Alles, was der Nutzer selbst ausgegeben hat (print / Console.WriteLine).
  final List<String> console;
}

SimulationOutput parseOutput(String stdout) {
  final events = <GameEvent>[];
  final console = <String>[];
  for (final line in const LineSplitter().convert(stdout)) {
    if (line.startsWith('@@')) {
      final parts = line.substring(2).split(' ');
      events.add(GameEvent(parts.first, parts.sublist(1)));
    } else {
      console.add(line);
    }
  }
  return SimulationOutput(events, console);
}

/// Zustand des Roboters und der Karte zu einem Zeitpunkt.
class GameState {
  GameState({
    required this.grid,
    required this.x,
    required this.y,
    required this.dir,
    required this.energy,
    required this.startEnergy,
    required this.inventory,
    this.error,
    this.scanned,
  });

  factory GameState.initial(Mission mission, MissionVariant variant) {
    final (x, y) = variant.start;
    return GameState(
      grid: [
        for (final row in variant.map) row.replaceAll('R', '.').split(''),
      ],
      x: x,
      y: y,
      dir: variant.dir,
      energy: mission.energy,
      startEnergy: mission.energy,
      inventory: [],
    );
  }

  final List<List<String>> grid;
  int x;
  int y;
  String dir;
  int energy;
  int startEnergy;
  final List<String> inventory;

  /// Fehlermeldung, falls der Roboter verunglückt ist oder der Code abstürzte.
  String? error;

  /// Ergebnis des letzten Scans (für eine kurze Anzeige).
  String? scanned;

  int get energyUsed => startEnergy - energy;

  void apply(GameEvent e) {
    scanned = null;
    final a = e.args;
    switch (e.kind) {
      case 'START':
        x = int.parse(a[0]);
        y = int.parse(a[1]);
        dir = a[2];
        energy = int.parse(a[3]);
        startEnergy = energy;
      case 'MOVE':
        x = int.parse(a[0]);
        y = int.parse(a[1]);
        energy = int.parse(a[2]);
      case 'TURN':
        dir = a[0];
      case 'SCAN':
        scanned = a[0];
      case 'PICK':
        inventory.add(a[0]);
        final px = int.parse(a[1]);
        final py = int.parse(a[2]);
        if (grid[py][px] != 'Q') grid[py][px] = '.';
      case 'MIX':
        inventory.remove(a[0]);
        inventory.remove(a[1]);
        inventory.add(a[2]);
      case 'FEHLER':
        error = robotErrorMessage(a);
      case 'CODE':
        error = 'Fehler in deinem Code – ${a.join(' ')}';
    }
  }
}

String robotErrorMessage(List<String> a) {
  switch (a.isEmpty ? '' : a[0]) {
    case 'FELS':
      return 'Zusammenstoß mit einem Felsen! 💥';
    case 'LAVA':
      return 'Der Roboter ist in die Lava gefahren! 🔥';
    case 'AKKU':
      return 'Akku leer! 🪫';
    case 'NICHTS':
      return 'Hier gibt es nichts zum Aufheben.';
    case 'KEINLABOR':
      return 'Mischen geht nur im Labor ⚗️.';
    case 'FEHLT':
      return '„${a.length > 1 ? a[1] : '?'}“ ist nicht im Inventar.';
    case 'REZEPT':
      return 'Aus „${a[1]}“ und „${a[2]}“ entsteht nichts.';
    case 'LIMIT':
      return 'Zu viele Befehle – steckt der Roboter in einer Endlosschleife?';
    default:
      return 'Unbekannter Fehler: ${a.join(' ')}';
  }
}

/// Spielt alle Ereignisse ab und liefert den Endzustand.
GameState replay(Mission mission, MissionVariant variant, List<GameEvent> events) {
  final state = GameState.initial(mission, variant);
  for (final e in events) {
    state.apply(e);
  }
  return state;
}

const _itemChars = {'kristall': 'K', 'moos': 'M', 'erz': 'E'};

List<bool> checkGoals(Mission mission, MissionVariant variant, GameState s) {
  return [
    for (final g in mission.goals)
      switch (g.type) {
        'basis' => variant.map[s.y][s.x] == 'Z',
        'sammeln' || 'herstellen' =>
          s.inventory.where((i) => i == g.item).length >= g.count,
        'ohne' => !s.inventory.contains(g.item),
        'alle' => !s.grid.any((row) => row.contains(_itemChars[g.item])),
        _ => false,
      },
  ];
}

/// Zählt „echte“ Codezeilen: ohne Leerzeilen, Kommentare und (in C#) Zeilen
/// mit nur einer Klammer.
int countCodeLines(String code, String language) {
  var n = 0;
  for (final line in const LineSplitter().convert(code)) {
    final t = line.trim();
    if (t.isEmpty) continue;
    if (language == 'python' && t.startsWith('#')) continue;
    if (language == 'csharp' &&
        (t.startsWith('//') || t == '{' || t == '}' || t == '};')) {
      continue;
    }
    n++;
  }
  return n;
}

/// 1 Stern fürs Lösen, je 1 für sparsame Energie und kurzen Code.
int computeStars({
  required Mission mission,
  required String language,
  required int energyUsed,
  required int lines,
}) {
  var stars = 1;
  if (energyUsed <= mission.parEnergy) stars++;
  if (lines <= (mission.parLines[language] ?? 0)) stars++;
  return stars;
}
