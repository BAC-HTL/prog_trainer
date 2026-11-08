import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_logic.dart';
import '../game/mission.dart';

/// Zeichnet die Karte einer Mission mit Roboter.
class GameMap extends StatelessWidget {
  const GameMap({super.key, required this.state});

  final GameState state;

  static const _tileColors = {
    '#': Color(0xFF4A4A57),
    '~': Color(0xFFE65100),
    '.': Color(0xFFEADBB8),
    'Q': Color(0xFFB3E5FC),
    'L': Color(0xFFE1BEE7),
    'Z': Color(0xFFC8E6C9),
  };

  static const _tileEmoji = {
    'K': '💎',
    'M': '🌿',
    'E': '🔩',
    'Q': '💧',
    'L': '⚗️',
    'Z': '🏠',
    '~': '🔥',
  };

  static const _angles = {'N': 0.0, 'O': 0.5, 'S': 1.0, 'W': 1.5};

  @override
  Widget build(BuildContext context) {
    final rows = state.grid.length;
    final cols = state.grid.first.length;

    return LayoutBuilder(builder: (context, constraints) {
      final cell = math.min(constraints.maxWidth / cols, 44.0);
      return Center(
        child: SizedBox(
          width: cell * cols,
          height: cell * rows,
          child: Stack(
            children: [
              for (var y = 0; y < rows; y++)
                for (var x = 0; x < cols; x++)
                  Positioned(
                    left: x * cell,
                    top: y * cell,
                    width: cell,
                    height: cell,
                    child: _Tile(
                      char: state.grid[y][x],
                      size: cell,
                    ),
                  ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                left: state.x * cell,
                top: state.y * cell,
                width: cell,
                height: cell,
                child: _Robot(
                  size: cell,
                  turns: _angles[state.dir] ?? 0,
                  crashed: state.error != null,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.char, required this.size});

  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emoji = GameMap._tileEmoji[char];
    return Container(
      decoration: BoxDecoration(
        color: GameMap._tileColors[char] ?? GameMap._tileColors['.'],
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      alignment: Alignment.center,
      child: emoji == null || char == '#'
          ? null
          : Text(emoji, style: TextStyle(fontSize: size * 0.55)),
    );
  }
}

class _Robot extends StatelessWidget {
  const _Robot({required this.size, required this.turns, required this.crashed});

  final double size;
  final double turns;
  final bool crashed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(crashed ? '💥' : '🤖', style: TextStyle(fontSize: size * 0.6)),
        AnimatedRotation(
          duration: const Duration(milliseconds: 180),
          turns: turns,
          child: Align(
            alignment: Alignment.topCenter,
            child: Icon(Icons.arrow_drop_up,
                size: size * 0.45, color: Colors.indigo.shade900),
          ),
        ),
      ],
    );
  }
}

/// Kleine Legende mit allen Feldtypen.
class GameLegend extends StatelessWidget {
  const GameLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const entries = [
      ('⬛', 'Fels'),
      ('🔥', 'Lava'),
      ('💎', 'Kristall'),
      ('🌿', 'Moos'),
      ('🔩', 'Erz'),
      ('💧', 'Quelle (Wasser)'),
      ('⚗️', 'Labor'),
      ('🏠', 'Basis'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final (e, label) in entries)
          Text('$e $label', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String inventoryText(List<String> inventory) {
  if (inventory.isEmpty) return 'leer';
  final counts = <String, int>{};
  for (final i in inventory) {
    counts[i] = (counts[i] ?? 0) + 1;
  }
  return counts.entries
      .map((e) => '${itemEmoji[e.key] ?? ''} ${e.key}${e.value > 1 ? ' ×${e.value}' : ''}')
      .join('   ');
}
