/// Lehrplan nach der Höheren Lehranstalt für Informatik (HTL, Österreich):
/// Stufen (1.–5. Jahrgang, danach Junior/Senior/Expert) × Fächer × Module.
///
/// Quelle: `assets/content/curriculum.json`.
library;

class Curriculum {
  const Curriculum({
    required this.stages,
    required this.subjects,
    required this.topics,
    required this.languages,
    required this.modules,
  });

  final List<Stage> stages;
  final List<Subject> subjects;
  final List<Topic> topics;
  final List<Language> languages;
  final List<CurriculumModule> modules;

  Stage stage(String id) => stages.firstWhere((s) => s.id == id);
  Subject subject(String id) => subjects.firstWhere((s) => s.id == id);
  Topic topic(String id) => topics.firstWhere((t) => t.id == id);
  String languageTitle(String id) =>
      languages.firstWhere((l) => l.id == id, orElse: () => Language(id, id)).title;

  factory Curriculum.fromJson(Map<String, dynamic> json) => Curriculum(
        stages: [
          for (final s in json['stages'] as List) Stage.fromJson(s as Map<String, dynamic>)
        ],
        subjects: [
          for (final s in json['subjects'] as List) Subject.fromJson(s as Map<String, dynamic>)
        ],
        topics: [
          for (final t in json['topics'] as List) Topic.fromJson(t as Map<String, dynamic>)
        ],
        languages: [
          for (final l in json['languages'] as List)
            Language((l as Map)['id'] as String, l['title'] as String)
        ],
        modules: [
          for (final m in json['modules'] as List)
            CurriculumModule.fromJson(m as Map<String, dynamic>)
        ],
      );
}

/// Eine Stufe: 1.–5. Jahrgang (HTL) oder Junior/Senior/Expert (Beruf).
class Stage {
  const Stage({required this.id, required this.title, required this.group, required this.description});

  final String id;
  final String title;

  /// `htl` oder `beruf`.
  final String group;
  final String description;

  factory Stage.fromJson(Map<String, dynamic> json) => Stage(
        id: json['id'] as String,
        title: json['title'] as String,
        group: json['group'] as String? ?? 'htl',
        description: json['description'] as String? ?? '',
      );
}

/// Ein Fachgegenstand, z. B. POS = Programmieren und Software Engineering.
class Subject {
  const Subject({required this.id, required this.title, required this.icon});

  final String id;
  final String title;
  final String icon;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        title: json['title'] as String,
        icon: json['icon'] as String? ?? 'school',
      );
}

/// Ein Thema zum Filtern, z. B. „Netzwerke“ oder „Datenbanken“.
class Topic {
  const Topic({required this.id, required this.title});

  final String id;
  final String title;

  factory Topic.fromJson(Map<String, dynamic> json) =>
      Topic(id: json['id'] as String, title: json['title'] as String);
}

class Language {
  const Language(this.id, this.title);

  final String id;
  final String title;
}

/// Lektionen + Abschlussprüfung eines Moduls (ggf. für eine Sprache).
class ModuleContent {
  const ModuleContent({
    required this.id,
    required this.lessonPaths,
    this.examPath,
    this.title,
  });

  /// Schlüssel für den Fortschritt (Prüfung, Zertifikat).
  final String id;
  final List<String> lessonPaths;
  final String? examPath;

  /// Abweichender Titel für diese Sprache (optional).
  final String? title;

  bool get isAvailable => lessonPaths.isNotEmpty;

  factory ModuleContent.fromJson(Map<String, dynamic> json, String fallbackId) =>
      ModuleContent(
        id: json['id'] as String? ?? fallbackId,
        lessonPaths: List<String>.from(json['lessons'] as List? ?? const []),
        examPath: json['exam'] as String?,
        title: json['title'] as String?,
      );
}

/// Ein Modul des Lehrplans (entspricht einem Kapitel mit Abschlussprüfung).
class CurriculumModule {
  const CurriculumModule({
    required this.id,
    required this.stage,
    required this.subject,
    required this.title,
    required this.description,
    required this.topics,
    this.semester,
    this.variants = const {},
    this.neutral,
    this.notes = const {},
  });

  final String id;
  final String stage;
  final String subject;
  final int? semester;
  final String title;
  final String description;
  final List<String> topics;

  /// Inhalte pro Programmiersprache (z. B. POS-Module).
  final Map<String, ModuleContent> variants;

  /// Sprachunabhängige Inhalte (z. B. Netzwerke, Logik).
  final ModuleContent? neutral;

  /// Hinweis, wenn es für eine Sprache keine Variante gibt.
  final Map<String, String> notes;

  bool get isLanguageSpecific => variants.isNotEmpty;

  /// Inhalt für die gewählte Sprache – oder `null`, wenn es ihn nicht gibt.
  ModuleContent? contentFor(String language) =>
      isLanguageSpecific ? variants[language] : neutral;

  String titleFor(String language) => contentFor(language)?.title ?? title;

  factory CurriculumModule.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final variants = <String, ModuleContent>{};
    (json['variants'] as Map<String, dynamic>? ?? {}).forEach((lang, v) {
      variants[lang] = ModuleContent.fromJson(v as Map<String, dynamic>, '$id-$lang');
    });
    return CurriculumModule(
      id: id,
      stage: json['stage'] as String,
      subject: json['subject'] as String,
      semester: json['semester'] as int?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      topics: List<String>.from(json['topics'] as List? ?? const []),
      variants: variants,
      neutral: variants.isEmpty ? ModuleContent.fromJson(json, id) : null,
      notes: Map<String, String>.from(json['note'] as Map? ?? const {}),
    );
  }
}

/// Alles, was Kapitel- und Prüfungsansicht über ein Modul wissen müssen.
class ChapterContext {
  const ChapterContext({
    required this.chapterId,
    required this.title,
    required this.description,
    required this.lessonPaths,
    required this.examPath,
    required this.trackId,
    required this.trackTitle,
    required this.levelTitle,
    required this.subjectId,
  });

  /// Schlüssel für Prüfungsergebnis und Zertifikat.
  final String chapterId;
  final String title;
  final String description;
  final List<String> lessonPaths;
  final String? examPath;

  /// `python`/`csharp` bei sprachabhängigen Modulen, sonst das Fach.
  final String trackId;

  /// Für Zertifikate, z. B. „Programmieren und Software Engineering (Python)“.
  final String trackTitle;

  /// Stufe, z. B. „1. Jahrgang“.
  final String levelTitle;
  final String subjectId;

  static ChapterContext? of(
      Curriculum c, CurriculumModule m, String language) {
    final content = m.contentFor(language);
    if (content == null) return null;
    final subject = c.subject(m.subject);
    return ChapterContext(
      chapterId: content.id,
      title: m.titleFor(language),
      description: m.description,
      lessonPaths: content.lessonPaths,
      examPath: content.examPath,
      trackId: m.isLanguageSpecific ? language : m.subject.toLowerCase(),
      trackTitle: m.isLanguageSpecific
          ? '${subject.title} (${c.languageTitle(language)})'
          : subject.title,
      levelTitle: c.stage(m.stage).title,
      subjectId: m.subject,
    );
  }
}
