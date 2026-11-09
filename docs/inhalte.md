# Lerninhalte schreiben

Alle Inhalte liegen als JSON-Dateien in `assets/content/`. Für neue Inhalte
muss kein Dart-Code geändert werden.

## Aufbau

```
assets/content/
  index.json                  Lernpfade (Python, C#, Architektur …)
  python/
    challenges.json           Herausforderungen für Python
    einsteiger/
      level.json              Kapitel dieses Levels
      e1_01_erstes_programm.json
      e1_pruefung.json        Abschlussprüfung Kapitel e1
    fortgeschritten/ profi/ senior/
  csharp/ …                   gleich aufgebaut
```

## Kapitel (`level.json`)

```json
{
  "id": "python-einsteiger",
  "title": "Einsteiger",
  "description": "…",
  "chapters": [
    {
      "id": "python-e1",
      "title": "Erste Schritte",
      "description": "…",
      "lessons": ["python/einsteiger/e1_01_erstes_programm.json"],
      "exam": "python/einsteiger/e1_pruefung.json"
    }
  ]
}
```

Kapitel ohne Lektionen werden als „Bald verfügbar“ angezeigt.

## Lektion

```json
{
  "id": "python-e4_01_listen",
  "title": "Listen",
  "summary": "Mehrere Werte in einer Variable speichern.",
  "sections": [
    { "type": "text", "content": "Erklärtext …" },
    { "type": "code", "content": "zahlen = [1, 2, 3]\nprint(zahlen[0])" }
  ],
  "quiz": [
    {
      "question": "Was gibt dieser Code aus?",
      "code": "zahlen = [4, 5, 6]\nprint(zahlen[1])",
      "options": ["4", "5", "6", "Fehler"],
      "correctIndex": 1,
      "explanation": "Die Zählung beginnt bei 0."
    }
  ]
}
```

`correctIndex` zählt **ab 0**.

## Abschlussprüfung

```json
{
  "id": "python-e4-pruefung",
  "title": "Abschlussprüfung: Listen & Strings",
  "passPercent": 70,
  "questions": [ /* 10 Fragen im selben Format wie das Quiz */ ]
}
```

Die Prüfung wird freigeschaltet, sobald alle Lektionen des Kapitels
abgeschlossen sind. Wer sie besteht, bekommt ein PDF-Zertifikat.

## Herausforderung (`challenges.json`)

```json
{
  "id": "py-001",
  "title": "Verdoppeln",
  "level": "einsteiger",
  "difficulty": "leicht",
  "points": 10,
  "description": "Lies eine Zahl ein und gib das Doppelte aus.",
  "starterCode": "n = int(input())\n",
  "hints": ["Multipliziere mit 2."],
  "tests": [ { "stdin": "4", "expected": "8" } ],
  "solution": "n = int(input())\nprint(n * 2)"
}
```

- Eingabe nur über die Standardeingabe: in Python `input()` **ohne** Text, in C# `Console.ReadLine()`.
- Verglichen wird die Ausgabe zeilenweise. Leerzeichen am Zeilenende werden ignoriert.
- C#-Lösungen werden als Top-Level-Programm mit impliziten usings ausgeführt, wie bei `dotnet new console`. Aktuelle Sprachfeatures (records, switch-Ausdrücke …) sind erlaubt.
- Alle Lösungen prüfen:
  ```bash
  python3 tool/verify_challenges.py python
  python3 tool/verify_challenges.py csharp   # braucht das .NET SDK
  ```

## Nach jeder Änderung

`flutter test` ausführen. Es prüft, ob alle Dateien existieren, gültig sind
und in `pubspec.yaml` eingetragen sind.
