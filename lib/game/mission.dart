/// Eine Mission im Spielmodus: Karte(n), Ziele, Starter-Code und
/// Musterlösung – für Python und C# gleich.
class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.story,
    required this.concept,
    required this.energy,
    required this.variants,
    required this.goals,
    required this.parEnergy,
    required this.parLines,
    required this.hints,
    required this.starter,
    required this.solution,
  });

  final String id;
  final String title;
  final String story;
  final String concept;

  /// Akku zu Beginn.
  final int energy;

  /// Mehrere Karten: Die Lösung muss auf allen funktionieren.
  final List<MissionVariant> variants;
  final List<Goal> goals;

  /// Energieverbrauch (Variante 1) für den Energie-Stern.
  final int parEnergy;

  /// Codezeilen pro Sprache für den Kurz-Code-Stern.
  final Map<String, int> parLines;
  final List<String> hints;
  final Map<String, String> starter;
  final Map<String, String> solution;

  factory Mission.fromJson(Map<String, dynamic> json) {
    final par = json['par'] as Map<String, dynamic>;
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      story: json['story'] as String,
      concept: json['concept'] as String? ?? '',
      energy: json['energy'] as int,
      variants: (json['variants'] as List)
          .map((v) => MissionVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      goals: (json['goals'] as List)
          .map((g) => Goal.fromJson(g as Map<String, dynamic>))
          .toList(),
      parEnergy: par['energy'] as int,
      parLines: Map<String, int>.from(par['lines'] as Map),
      hints: List<String>.from(json['hints'] as List? ?? const []),
      starter: Map<String, String>.from(json['starter'] as Map),
      solution: Map<String, String>.from(json['solution'] as Map),
    );
  }
}

class MissionVariant {
  const MissionVariant({required this.map, required this.dir});

  /// Kartenzeilen, `R` markiert den Start.
  final List<String> map;

  /// Startrichtung: N, O, S oder W.
  final String dir;

  factory MissionVariant.fromJson(Map<String, dynamic> json) => MissionVariant(
        map: List<String>.from(json['map'] as List),
        dir: json['dir'] as String,
      );

  int get width => map.first.length;
  int get height => map.length;

  (int, int) get start {
    for (var y = 0; y < map.length; y++) {
      final x = map[y].indexOf('R');
      if (x >= 0) return (x, y);
    }
    throw StateError('Karte ohne Startfeld');
  }
}

class Goal {
  const Goal({required this.type, this.item, this.count = 1});

  /// `basis`, `sammeln`, `herstellen`, `alle` oder `ohne`.
  final String type;
  final String? item;
  final int count;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        type: json['type'] as String,
        item: json['item'] as String?,
        count: json['count'] as int? ?? 1,
      );

  String get description {
    final name = itemLabel(item ?? '');
    switch (type) {
      case 'basis':
        return 'Fahr zur Basis 🏠';
      case 'sammeln':
        return 'Sammle ${count > 1 ? '$count× ' : ''}$name';
      case 'herstellen':
        return 'Stelle ${count > 1 ? '$count× ' : ''}$name her';
      case 'alle':
        return 'Sammle alle Felder mit $name ein';
      case 'ohne':
        return 'Nimm kein $name mit';
      default:
        return type;
    }
  }
}

const itemEmoji = {
  'kristall': '💎',
  'moos': '🌿',
  'erz': '🔩',
  'wasser': '💧',
  'energiezelle': '🔋',
  'biogel': '🧪',
  'legierung': '🛡️',
  'nanobot': '🦾',
};

String itemLabel(String item) {
  if (item.isEmpty) return '';
  final name = item[0].toUpperCase() + item.substring(1);
  final emoji = itemEmoji[item];
  return emoji == null ? name : '$name $emoji';
}

const recipes = [
  ('kristall', 'wasser', 'energiezelle'),
  ('moos', 'wasser', 'biogel'),
  ('erz', 'kristall', 'legierung'),
  ('biogel', 'legierung', 'nanobot'),
];
