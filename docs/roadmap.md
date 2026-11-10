# Roadmap

## Erledigt

- Lehrplan nach HTL Informatik (1.–5. Jahrgang) plus Junior, Senior, Expert
- 1. und 2. Jahrgang in allen Fächern ausgearbeitet
- Filter nach Stufe, Fach und Thema
- PDF-Zertifikate pro Kapitel
- Achievements
- Herausforderungen mit echter Code-Ausführung und Punkten pro Sprache
- Android und iOS
- Python **und** C# laufen direkt am Handy, ohne Anmeldung
- Spielmodus „Expedition Xeno-7“ mit 16 Missionen

## Als Nächstes

- Inhalte für den **3.–5. Jahrgang**
- Inhalte für **Junior, Senior und Expert**
- Python offline: Pyodide in die App packen statt aus dem Internet laden
- Herausforderungen für höhere Jahrgänge
- Dunkler Modus
- Weitere Spielmissionen für höhere Jahrgänge, z. B. mit Klassen und Rekursion

## Code-Ausführung: Hintergrund

| Option | Sprache | Offline | Status |
|---|---|---|---|
| **Pyodide** (WebView) | Python | nach erstem Laden | ✅ eingebaut |
| **Roslyn + .NET-WASM** (WebView) | C# (aktuell) | nach erstem Laden | ✅ eingebaut, ohne Anmeldung |
| Piston | viele | nein | seit 02/2026 keine Keys für Schulprojekte |

!!! info "App Store"
    Apple erlaubt Lern-Apps, Code auszuführen, wenn der Code für Nutzer
    sichtbar und bearbeitbar ist.
