# Roadmap

## Als Nächstes

- Lernfortschritt speichern (erledigte Lektionen, Quiz-Ergebnisse)
- Weitere Lektionen: Listen, Funktionen, Klassen
- Erste Lektionen zu Testing, Software-Architektur und Requirements Engineering

## Code am Handy ausführen

Recherche-Stand November 2026:

| Option | Sprache | Offline | Bewertung |
|---|---|---|---|
| **Pyodide** in einer WebView | Python | ja | Empfohlen für Version 1. Läuft auf Android und iOS gleich. Die App wird dadurch größer. |
| serious_python | Python | ja | Echtes CPython, aber für eine Lern-REPL umständlich |
| Chaquopy | Python | ja | Nur Android |
| **Judge0** (Server) | C# und viele mehr | nein | Gratis-Plan mit 50 Ausführungen/Tag, selbst hosten kostenlos |
| Piston (öffentliche API) | viele | nein | Seit Feb. 2026 nur mit Schlüssel, keine Schlüssel für Schulprojekte |
| Roslyn + .NET-WASM in WebView | C# | ja | Vielversprechend für später, Downloadgröße noch ungeklärt |

**Plan:**

1. Python über Pyodide direkt am Handy ausführen.
2. C# zuerst über einen Judge0-Server, später möglichst ebenfalls offline
   über .NET-WASM.

!!! info "App Store"
    Apple erlaubt Lern-Apps, Code auszuführen, wenn der Code für Nutzer
    sichtbar und bearbeitbar ist. Die Laufzeit sollte in der App enthalten
    sein und nicht nachgeladen werden.
