# Lerninhalte schreiben

Alle Inhalte liegen als JSON-Dateien in `assets/content/`. Für neue Inhalte
muss kein Dart-Code geändert werden.

## Aufbau

```
assets/content/
  curriculum.json             der Lehrplan: Stufen, Fächer, Themen, Module
  index.json                  Programmiersprachen (für Herausforderungen und Spiel)
  pos/j1/python/ …            neue Inhalte: <fach>/<stufe>/[<sprache>/]
  dbi/j2/, nvs/j2/, tinf/j1/ …
  python/, csharp/            ältere Programmier-Lektionen und Herausforderungen
```

## Modul im Lehrplan (`curriculum.json`)

Sprachunabhängiges Modul:

```json
{
  "id": "nvs-j2-adressierung",
  "stage": "j2",
  "subject": "NVS",
  "semester": 3,
  "title": "Adressierung & Subnetting",
  "description": "MAC- und IP-Adressen, Subnetze, IPv6.",
  "topics": ["netzwerke"],
  "lessons": ["nvs/j2/adressierung_01_mac_ip.json"],
  "exam": "nvs/j2/adressierung_pruefung.json"
}
```

Programmier-Modul mit einer Variante pro Sprache:

```json
{
  "id": "pos-j2-rekursion",
  "stage": "j2", "subject": "POS", "semester": 3,
  "title": "Rekursion", "description": "…", "topics": ["programmieren", "algorithmen"],
  "variants": {
    "python": { "id": "pos-j2-rekursion-python", "lessons": ["…"], "exam": "…" },
    "csharp": { "id": "pos-j2-rekursion-csharp", "lessons": ["…"], "exam": "…" }
  }
}
```

- `stage`: `j1`–`j5`, `junior`, `senior` oder `expert`.
- `subject`: `POS`, `DBI`, `NVS`, `TINF` oder `SYP`.
- `topics`: Themen für den Filter. Die Liste aller Themen steht oben in `curriculum.json`.
- Die `id` eines Moduls bzw. einer Variante ist der Schlüssel für Prüfungsergebnis und Zertifikat. Sie darf sich später nicht mehr ändern.
- Module ohne `lessons` erscheinen als „Bald verfügbar“.
- Neue Ordner müssen in `pubspec.yaml` unter `flutter: assets:` eingetragen werden.

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
