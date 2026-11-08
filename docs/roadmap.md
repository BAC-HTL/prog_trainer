# Roadmap

## Erledigt

- Lehrplan bis Senior für Python und C#
- Einsteiger und Fortgeschritten komplett, mit Abschlussprüfungen
- PDF-Zertifikate pro Kapitel
- Achievements
- Herausforderungen mit echter Code-Ausführung und Punkten pro Sprache
- Android und iOS

## Als Nächstes

- Inhalte für **Profi** und **Senior**
- Lernpfade Software-Architektur, Testing, Requirements Engineering
- Python offline: Pyodide in die App packen statt aus dem Internet laden
- C# ohne Server: Roslyn + .NET-WASM direkt am Gerät
- Herausforderungen für Profi/Senior
- Dunkler Modus

## Code-Ausführung: Hintergrund

| Option | Sprache | Offline | Status |
|---|---|---|---|
| **Pyodide** (WebView) | Python | nach erstem Laden | ✅ eingebaut |
| **Judge0** (Server) | C# (Mono, ≈ C# 7) | nein | ✅ eingebaut, API-Key nötig |
| Roslyn + .NET-WASM | C# (aktuell) | ja | geplant |
| Piston | viele | nein | seit 02/2026 keine Keys für Schulprojekte |

!!! info "App Store"
    Apple erlaubt Lern-Apps, Code auszuführen, wenn der Code für Nutzer
    sichtbar und bearbeitbar ist.
