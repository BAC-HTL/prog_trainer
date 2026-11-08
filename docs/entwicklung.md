# Entwicklung

Die App ist mit [Flutter](https://flutter.dev) geschrieben (Sprache: Dart).

## Lokal starten

1. [Flutter installieren](https://docs.flutter.dev/get-started/install).
2. Einmalig die Plattform-Ordner erzeugen:
   ```bash
   flutter create --platforms=android,ios --project-name prog_trainer .
   ```
3. Starten und testen:
   ```bash
   flutter pub get
   flutter run
   flutter test
   ```

## Architektur

```
lib/
  main.dart                      Einstiegspunkt, Theme
  models/content.dart            Track, Lesson, LessonSection, QuizQuestion
  data/content_repository.dart   lädt die JSON-Dateien aus assets/
  screens/
    home_screen.dart             Übersicht aller Lernpfade
    track_screen.dart            Lektionen eines Lernpfads
    lesson_screen.dart           Inhalt einer Lektion
    quiz_screen.dart             Quiz mit Auswertung
  widgets/                       Code-Box, Icons
```

**Inhalte und Code sind getrennt.** Das `ContentRepository` ist die einzige
Stelle, die weiß, woher die Inhalte kommen. Später kann es sie genauso von
einem Server laden, ohne dass sich die Screens ändern.

## Tests

- `test/content_test.dart` prüft alle Inhaltsdateien (gültiges JSON,
  richtige Antwort-Indizes, Ordner in `pubspec.yaml` eingetragen).
- `test/widget_test.dart` klickt sich einmal durch die App:
  Startseite → Lektion → Quiz → Ergebnis.

## Automatische Builds (GitHub Actions)

| Workflow | Wann | Was |
|---|---|---|
| `flutter.yml` | jeder Push / Pull Request | Analyse, Tests, Debug-APK als Artifact |
| `release.yml` | Push auf `main` | Release-APK → GitHub Release `latest` + diese Doku auf GitHub Pages |
