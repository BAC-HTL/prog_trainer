/// Eine Programmier-Herausforderung: Der Nutzer schreibt Code, der gegen
/// Testfälle (Eingabe → erwartete Ausgabe) geprüft wird.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.level,
    required this.difficulty,
    required this.points,
    required this.description,
    required this.starterCode,
    required this.hints,
    required this.tests,
    required this.solution,
  });

  final String id;
  final String title;

  /// `einsteiger`, `fortgeschritten`, `profi` oder `senior`.
  final String level;

  /// `leicht`, `mittel` oder `schwer`.
  final String difficulty;
  final int points;
  final String description;
  final String starterCode;
  final List<String> hints;
  final List<ChallengeTest> tests;
  final String solution;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      level: json['level'] as String? ?? 'einsteiger',
      difficulty: json['difficulty'] as String? ?? 'leicht',
      points: json['points'] as int? ?? 10,
      description: json['description'] as String,
      starterCode: json['starterCode'] as String? ?? '',
      hints: List<String>.from(json['hints'] as List? ?? const []),
      tests: (json['tests'] as List)
          .map((t) => ChallengeTest.fromJson(t as Map<String, dynamic>))
          .toList(),
      solution: json['solution'] as String? ?? '',
    );
  }
}

class ChallengeTest {
  const ChallengeTest({required this.stdin, required this.expected});

  final String stdin;
  final String expected;

  factory ChallengeTest.fromJson(Map<String, dynamic> json) {
    return ChallengeTest(
      stdin: json['stdin'] as String? ?? '',
      expected: json['expected'] as String,
    );
  }
}

const levelTitles = {
  'einsteiger': 'Einsteiger',
  'fortgeschritten': 'Fortgeschritten',
  'profi': 'Profi',
  'senior': 'Senior',
};
