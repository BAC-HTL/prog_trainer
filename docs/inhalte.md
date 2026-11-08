# Lerninhalte schreiben

Alle Inhalte liegen als JSON-Dateien in `assets/content/`. Für neue Lektionen
muss kein Dart-Code geändert werden.

## Neue Lektion hinzufügen

1. Datei anlegen, z. B. `assets/content/python/06_listen.json`.
2. Pfad in `assets/content/index.json` beim passenden Lernpfad unter
   `lessons` eintragen.
3. **Neuer Ordner** (z. B. eine neue Sprache)? Den Ordner zusätzlich in
   `pubspec.yaml` unter `flutter: assets:` eintragen.
4. `flutter test` ausführen. Der Test prüft alle Dateien automatisch.

## Aufbau einer Lektion

```json
{
  "id": "python-06",
  "title": "Listen",
  "summary": "Mehrere Werte in einer Variable speichern.",
  "sections": [
    { "type": "text", "content": "Erklärtext ..." },
    { "type": "code", "content": "zahlen = [1, 2, 3]\nprint(zahlen[0])" }
  ],
  "quiz": [
    {
      "question": "Was gibt dieser Code aus?",
      "code": "zahlen = [4, 5, 6]\nprint(zahlen[1])",
      "options": ["4", "5", "6", "Fehler"],
      "correctIndex": 1,
      "explanation": "Die Zählung beginnt bei 0, also ist zahlen[1] das zweite Element."
    }
  ]
}
```

| Feld | Bedeutung |
|---|---|
| `sections[].type` | `text` für Erklärungen, `code` für Code-Beispiele |
| `quiz[].code` | optional, Code der zur Frage angezeigt wird |
| `quiz[].correctIndex` | Position der richtigen Antwort, **ab 0 gezählt** |

## Neuer Lernpfad

In `index.json` einen Eintrag unter `tracks` ergänzen:

```json
{
  "id": "java",
  "title": "Java",
  "description": "Kurzbeschreibung",
  "icon": "code",
  "kind": "language",
  "lessons": []
}
```

`kind` ist `language` (Programmiersprache) oder `concept` (z. B. Testing).
Lernpfade ohne Lektionen werden als „Bald verfügbar“ angezeigt.

## Tipps für gute Lektionen

- Kurze Abschnitte, ein Gedanke pro Absatz.
- Jedes Code-Beispiel vorher wirklich ausführen.
- Falsche Antworten sollen plausibel sein, z. B. typische Anfängerfehler.
- Die richtige Antwort nicht immer an dieselbe Position setzen.
