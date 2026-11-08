# Entwicklung

Die App ist mit [Flutter](https://flutter.dev) (Sprache: Dart) geschrieben
und läuft auf Android und iOS.

## Lokal starten

1. [Flutter installieren](https://docs.flutter.dev/get-started/install).
2. Einmalig die Plattform-Ordner erzeugen:
   ```bash
   bash tool/prepare_platforms.sh
   ```
3. Starten und testen:
   ```bash
   flutter pub get
   flutter run
   flutter test
   ```

Für iOS braucht man einen Mac mit Xcode.

## Architektur

```
lib/
  main.dart                  Start, Dienste verdrahten
  app_services.dart          stellt Repository, Fortschritt, Code-Runner bereit
  models/                    Track, Level, Chapter, Lesson, Exam, Challenge
  data/
    content_repository.dart  lädt die JSON-Inhalte
    progress_store.dart      Fortschritt, Punkte, Prüfungen (shared_preferences)
    achievements.dart        alle Achievements + Regeln
  runner/
    code_runner.dart         Schnittstelle + Testauswertung
    pyodide_runner.dart      Python am Gerät (WebView + Web Worker)
    judge0_runner.dart       Code auf Judge0-Server (C#)
    csharp_wrapper.dart      Top-Level-Code → Main (für Mono)
  certificates/              PDF-Zertifikat
  screens/                   Lernen, Kapitel, Lektion, Quiz, Prüfung,
                             Herausforderungen, Erfolge, Einstellungen
```

**Code-Ausführung.** Hinter der Schnittstelle `CodeRunner` können Laufzeiten ausgetauscht werden. Eine neue Sprache braucht nur einen neuen Runner und einen Eintrag in `main.dart`.

**Python** läuft über [Pyodide](https://pyodide.org) in einer unsichtbaren WebView. Der Code wird in einem Web Worker ausgeführt, damit Endlosschleifen nach 10 Sekunden abgebrochen werden können. Beim ersten Start wird Pyodide aus dem Internet geladen.

**C#** wird über die Judge0-API ausgeführt. Der Server hat nur Mono (≈ C# 7), deshalb verpackt `csharp_wrapper.dart` Top-Level-Code automatisch in eine `Main`-Methode.

## Tests

| Datei | Prüft |
|---|---|
| `test/content_test.dart` | alle Lektionen, Prüfungen, Herausforderungen |
| `test/logic_test.dart` | Fortschritt, Achievements, C#-Wrapper, Judge0, PDF |
| `test/widget_test.dart` | Durchklicken: Lektion → Quiz → Prüfung, Herausforderung lösen |
| `tool/verify_challenges.py` | führt alle Musterlösungen gegen ihre Tests aus |

## Automatische Builds (GitHub Actions)

| Workflow | Wann | Was |
|---|---|---|
| `flutter.yml` | jeder Push / Pull Request | Lösungen prüfen, Analyse, Tests, Android-APK, iOS-Build |
| `release.yml` | Push auf `main` | APK + IPA → Release `latest`, Doku auf GitHub Pages |
