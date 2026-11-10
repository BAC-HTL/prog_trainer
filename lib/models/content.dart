/// Datenmodelle für Lektionen, Quizfragen und Prüfungen.
///
/// Wie die Lektionen im Lehrplan angeordnet sind, beschreibt
/// `curriculum.dart` (Datei `assets/content/curriculum.json`).
library;

/// Eine Programmiersprache mit Herausforderungen und Spielmodus.
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.challengesPath,
    this.runtime,
  });

  final String id;
  final String title;
  final String description;
  final String icon;

  /// Datei mit den Herausforderungen dieser Sprache (falls vorhanden).
  final String? challengesPath;

  /// Welche Laufzeit Code dieses Tracks ausführt (`python`, `csharp`).
  final String? runtime;

  bool get hasChallenges => challengesPath != null;

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? 'code',
      challengesPath: json['challenges'] as String?,
      runtime: json['runtime'] as String?,
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

/// Eine Multiple-Choice-Frage (für Quiz und Prüfung).
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

/// Abschlussprüfung eines Kapitels.
class Exam {
  const Exam({
    required this.id,
    required this.title,
    required this.passPercent,
    required this.questions,
  });

  final String id;
  final String title;
  final int passPercent;
  final List<QuizQuestion> questions;

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      passPercent: json['passPercent'] as int? ?? 70,
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
