# Spielmodus: Expedition Xeno-7

Im Spielmodus steuerst du einen Forschungsroboter auf dem Planeten
**Xeno-7**, und zwar mit echtem Python- oder C#-Code. Du sammelst Proben,
braust im Labor neue Stoffe und meidest Lava, Felsen und einen leeren Akku.

## So funktioniert's

1. Im Tab **Spiel** die Sprache wählen. Fortschritt und Punkte werden pro Sprache getrennt geführt.
2. Eine Mission öffnen, die Geschichte und die Ziele lesen.
3. Code schreiben und auf **Roboter starten** tippen. Der Roboter führt deinen Code Schritt für Schritt animiert aus.
4. Manche Missionen haben **mehrere Karten**. Dein Programm muss auf allen funktionieren, also nutze die Sensoren, statt den Weg auswendig zu fahren.

## Sterne

| Stern | Bedingung |
|---|---|
| ⭐ | Mission erfüllt |
| ⭐ | sparsam: höchstens so viel Energie wie angegeben (Karte 1) |
| ⭐ | kurz: höchstens so viele Codezeilen wie angegeben |

Jeder neue Stern bringt 10 Punkte in der jeweiligen Sprache. Die nächste
Mission wird freigeschaltet, sobald die vorherige gelöst ist.

## Die Karte

| Feld | Bedeutung |
|---|---|
| ⬛ Fels | Wand. Hineinfahren beschädigt den Roboter. |
| 🔥 Lava | tödlich, niemals betreten |
| 💎 Kristall, 🌿 Moos, 🔩 Erz | Proben, verschwinden beim Aufheben |
| 💧 Quelle | liefert beliebig oft Wasser |
| ⚗️ Labor | nur hier kann gemischt werden |
| 🏠 Basis | Ziel vieler Missionen |

Jeder Schritt nach vorne kostet 1 Energie. Ein Programm darf höchstens
1000 Befehle ausführen. So werden Endlosschleifen erkannt.

## Rezepte

| Zutaten | Ergebnis |
|---|---|
| Kristall + Wasser | 🔋 Energiezelle |
| Moos + Wasser | 🧪 Biogel |
| Erz + Kristall | 🛡️ Legierung |
| Biogel + Legierung | 🦾 Nanobot |

## Befehle

| Python | C# | Bedeutung |
|---|---|---|
| `robot.vor()` | `Robot.Vor();` | ein Feld vorwärts |
| `robot.links()` / `robot.rechts()` | `Robot.Links();` / `Robot.Rechts();` | drehen |
| `robot.ist_frei()` | `Robot.IstFrei()` | ist vorne frei (kein Fels, keine Lava)? |
| `robot.vorne()` | `Robot.Vorne()` | was ist vorne? `"fels"`, `"lava"`, `"kristall"` … |
| `robot.scannen()` | `Robot.Scannen()` | was liegt unter dem Roboter? |
| `robot.aufheben()` | `Robot.Aufheben()` | Probe aufheben |
| `robot.mischen(a, b)` | `Robot.Mischen(a, b)` | im Labor mischen |
| `robot.inventar()` | `Robot.Inventar()` | Liste der gesammelten Stoffe |
| `robot.position()` | `Robot.X`, `Robot.Y` | Position |
| `robot.richtung()` | `Robot.Richtung` | `"N"`, `"O"`, `"S"`, `"W"` |
| `robot.energie()` | `Robot.Energie` | verbleibende Energie |

## Eigene Missionen bauen

Missionen liegen in `assets/game/missions_*.json` (welche Dateien geladen
werden, steht in `assets/game/index.json`). Eine Mission sieht so aus:

```json
{
  "id": "m03",
  "title": "Unbekannter Tunnel",
  "story": "Ein Tunnel führt zur Basis …",
  "concept": "while-Schleife",
  "energy": 20,
  "variants": [
    { "map": ["#####", "#R.Z#", "#####"], "dir": "O" },
    { "map": ["##########", "#R......Z#", "##########"], "dir": "O" }
  ],
  "goals": [{ "type": "basis" }],
  "par": { "energy": 7, "lines": { "python": 2, "csharp": 2 } },
  "hints": ["ist_frei() sagt dir, ob vor dem Roboter Platz ist."],
  "starter": { "python": "robot.vor()\n", "csharp": "Robot.Vor();\n" },
  "solution": {
    "python": "while robot.ist_frei():\n    robot.vor()\n",
    "csharp": "while (Robot.IstFrei())\n    Robot.Vor();\n"
  }
}
```

**Ziele** (`goals`):

- `basis`: Am Ende auf der Basis stehen.
- `sammeln`: Eine Anzahl einer Probe im Inventar haben.
- `herstellen`: Einen Stoff im Inventar haben.
- `alle`: Alle Felder einer Probensorte einsammeln.
- `ohne`: Diese Probe darf am Ende nicht im Inventar sein.

Danach immer prüfen:

```bash
python3 tool/verify_missions.py
```

Das Skript führt beide Musterlösungen in der Python- **und** der
C#-Simulation auf allen Karten aus. Es prüft, dass sich beide gleich
verhalten, dass die Ziele und Sterne erreicht werden und dass der Starter-Code
die Mission noch nicht löst.
