/// Datenmodelle für die Lerninhalte.
///
/// Die Inhalte liegen als JSON-Dateien unter `assets/content/` und werden
/// beim Start geladen. So kann man neue Sprachen und Lektionen hinzufügen,
/// ohne den App-Code anzufassen.
library;

enum TrackKind { language, concept }

/// Ein Lernpfad, z. B. "Python" oder "Software-Architektur".
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.kind,
    required this.lessonPaths,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final TrackKind kind;

  /// Pfade relativ zu `assets/content/`, z. B. `python/01_hallo_welt.json`.
  final List<String> lessonPaths;

  bool get isAvailable => lessonPaths.isNotEmpty;

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? 'code',
      kind: json['kind'] == 'concept' ? TrackKind.concept : TrackKind.language,
      lessonPaths: List<String>.from(json['lessons'] as List? ?? const []),
    );
  }
}

enum SectionType { text, code }

/// Ein Abschnitt einer Lektion: entweder Erklärtext oder ein Code-Beispiel.
class LessonSection {
  const LessonSection({required this.type, required this.content});

  final SectionType type;
  final String content;

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    return LessonSection(
      type: json['type'] == 'code' ? SectionType.code : SectionType.text,
      content: json['content'] as String,
    );
  }
}

/// Eine Multiple-Choice-Frage.
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.code,
  });

  final String question;

  /// Optionaler Code, auf den sich die Frage bezieht.
  final String? code;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      code: json['code'] as String?,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.sections,
    required this.quiz,
  });

  final String id;
  final String title;
  final String summary;
  final List<LessonSection> sections;
  final List<QuizQuestion> quiz;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      sections: (json['sections'] as List)
          .map((s) => LessonSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      quiz: (json['quiz'] as List? ?? const [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
