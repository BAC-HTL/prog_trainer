#!/usr/bin/env python3
"""Prüft alle Spielmissionen.

Für jede Mission und jede Kartenvariante:
  * Musterlösung in Python UND C# ausführen (C# mit LangVersion 7.3, wie Mono)
  * beide Simulationen müssen exakt dieselben Ereignisse liefern
  * alle Ziele müssen erfüllt sein, ohne Fehler
  * die Musterlösungen müssen 3 Sterne erreichen
  * der Starter-Code darf die Mission NICHT schon lösen

Aufruf:
    python3 tool/verify_missions.py            # alles
    python3 tool/verify_missions.py --nur-python
    python3 tool/verify_missions.py m03        # nur eine Mission

Die Logik von replay()/check_goals()/count_lines() entspricht
lib/game/game_logic.dart – bei Änderungen beide anpassen!
"""
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from verify_challenges import CSharpRunner  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
GAME = os.path.join(ROOT, "assets", "game")
PY_SIM = open(os.path.join(GAME, "robot_sim.py"), encoding="utf-8").read()
CS_SIM = open(os.path.join(GAME, "RobotSim.cs"), encoding="utf-8").read()
DIRS = "NOSW"
GOAL_TYPES = {"basis", "sammeln", "herstellen", "alle", "ohne"}
ITEM_CHARS = {"kristall": "K", "moos": "M", "erz": "E"}


# ---------- gemeinsame Logik (Spiegel von game_logic.dart) ----------

def find_start(rows):
    for y, row in enumerate(rows):
        x = row.find("R")
        if x >= 0:
            return x, y
    raise ValueError("Karte ohne Startfeld R")


def stdin_for(mission, variant):
    rows = variant["map"]
    x, y = find_start(rows)
    clean = [r.replace("R", ".") for r in rows]
    return f"{x} {y} {variant['dir']} {mission['energy']}\n" + "\n".join(clean) + "\n"


def py_program(code):
    return PY_SIM + "\n_starte(" + json.dumps(code) + ")\n"


def cs_program(code):
    return "Robot.Start();\n" + code + "\n\n" + CS_SIM


def parse_events(stdout):
    return [l[2:].split(" ") for l in stdout.splitlines() if l.startswith("@@")]


def replay(rows, events):
    grid = [list(r.replace("R", ".")) for r in rows]
    st = {"x": 0, "y": 0, "dir": "N", "energy": 0, "inv": [], "error": None,
          "start_energy": 0}
    for ev in events:
        kind, args = ev[0], ev[1:]
        if kind == "START":
            st.update(x=int(args[0]), y=int(args[1]), dir=args[2],
                      energy=int(args[3]), start_energy=int(args[3]))
        elif kind == "MOVE":
            st.update(x=int(args[0]), y=int(args[1]), energy=int(args[2]))
        elif kind == "TURN":
            st["dir"] = args[0]
        elif kind == "PICK":
            st["inv"].append(args[0])
            x, y = int(args[1]), int(args[2])
            if grid[y][x] != "Q":
                grid[y][x] = "."
        elif kind == "MIX":
            st["inv"].remove(args[0])
            st["inv"].remove(args[1])
            st["inv"].append(args[2])
        elif kind in ("FEHLER", "CODE"):
            st["error"] = " ".join(ev)
    st["grid"] = grid
    return st


def check_goals(mission, rows, st):
    results = []
    for g in mission["goals"]:
        t = g["type"]
        if t == "basis":
            ok = rows[st["y"]][st["x"]] == "Z"
        elif t == "sammeln":
            ok = st["inv"].count(g["item"]) >= g.get("count", 1)
        elif t == "herstellen":
            ok = st["inv"].count(g["item"]) >= g.get("count", 1)
        elif t == "ohne":
            ok = g["item"] not in st["inv"]
        elif t == "alle":
            ch = ITEM_CHARS[g["item"]]
            ok = all(ch not in row for row in st["grid"])
        else:
            ok = False
        results.append(ok)
    return results


def count_lines(code, lang):
    n = 0
    for line in code.splitlines():
        t = line.strip()
        if not t:
            continue
        if lang == "python" and t.startswith("#"):
            continue
        if lang == "csharp" and (t.startswith("//") or t in ("{", "}", "};")):
            continue
        n += 1
    return n


# ---------- Ausführung ----------

def run_python(code, stdin):
    p = subprocess.run([sys.executable, "-c", py_program(code)], input=stdin,
                       capture_output=True, text=True, timeout=20)
    return p.stdout, p.stderr, p.returncode


def evaluate(mission, events_per_variant, ok_per_variant):
    """Gibt (gelöst, energieVerbrauch der 1. Variante) zurück."""
    solved = True
    used = None
    for variant, events, ok in zip(mission["variants"], events_per_variant, ok_per_variant):
        st = replay(variant["map"], events)
        goals = check_goals(mission, variant["map"], st)
        if not ok or st["error"] or not all(goals):
            solved = False
        if used is None:
            used = st["start_energy"] - st["energy"]
    return solved, used


def validate_structure(m):
    errs = []
    for key in ("id", "title", "story", "concept", "energy", "variants", "goals",
                "par", "starter", "solution", "hints"):
        if key not in m:
            errs.append(f"Feld '{key}' fehlt")
    for i, v in enumerate(m.get("variants", [])):
        rows = v["map"]
        if sum(r.count("R") for r in rows) != 1:
            errs.append(f"Variante {i + 1}: genau ein R nötig")
        if v.get("dir") not in list(DIRS):
            errs.append(f"Variante {i + 1}: dir muss N/O/S/W sein")
        if len({len(r) for r in rows}) != 1:
            errs.append(f"Variante {i + 1}: alle Kartenzeilen gleich lang")
        bad = set("".join(rows)) - set("#~.KMEQLZR")
        if bad:
            errs.append(f"Variante {i + 1}: unbekannte Zeichen {bad}")
    for g in m.get("goals", []):
        if g.get("type") not in GOAL_TYPES:
            errs.append(f"unbekanntes Ziel {g}")
    return errs


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    only_python = "--nur-python" in sys.argv
    index = json.load(open(os.path.join(GAME, "index.json"), encoding="utf-8"))
    missions = []
    for f in index["files"]:
        missions += json.load(open(os.path.join(GAME, f), encoding="utf-8"))["missions"]
    ids = [m["id"] for m in missions]
    failures = 0
    if len(ids) != len(set(ids)):
        print("✗ doppelte Missions-IDs")
        failures += 1

    cs = None if only_python else CSharpRunner()

    for m in missions:
        if args and m["id"] not in args:
            continue
        errs = validate_structure(m)
        if errs:
            print(f"✗ {m.get('id')}: " + "; ".join(errs))
            failures += 1
            continue

        stdins = [stdin_for(m, v) for v in m["variants"]]
        logs = {}
        for lang in ("python", "csharp"):
            if lang == "csharp" and cs is None:
                continue
            for role in ("solution", "starter"):
                code = m[role][lang]
                events, oks = [], []
                if lang == "csharp":
                    built, log = cs.build(cs_program(code))
                    if not built:
                        if role == "solution":
                            print(f"✗ {m['id']} C#-Lösung kompiliert nicht:\n{log[-1500:]}")
                            failures += 1
                        events = [[] for _ in stdins]
                        oks = [False for _ in stdins]
                if not events:
                    for stdin in stdins:
                        if lang == "python":
                            out, err, rc = run_python(code, stdin)
                        else:
                            out, err, rc = cs.run(stdin)
                        events.append(parse_events(out))
                        oks.append(rc == 0)
                        if rc != 0 and role == "solution":
                            print(f"✗ {m['id']} {lang}: Absturz {err[-500:]}")
                solved, used = evaluate(m, events, oks)
                if role == "solution":
                    logs[lang] = events
                    lines = count_lines(code, lang)
                    if not solved:
                        print(f"✗ {m['id']} {lang}: Lösung erfüllt die Ziele nicht")
                        for i, (v, ev) in enumerate(zip(m["variants"], events)):
                            st = replay(v["map"], ev)
                            print(f"    Variante {i + 1}: Ziele {check_goals(m, v['map'], st)}"
                                  f" Fehler {st['error']} Inventar {st['inv']}")
                        failures += 1
                    if used is not None and used > m["par"]["energy"]:
                        print(f"✗ {m['id']} {lang}: Energie {used} > par {m['par']['energy']}")
                        failures += 1
                    if lines > m["par"]["lines"][lang]:
                        print(f"✗ {m['id']} {lang}: {lines} Zeilen > par {m['par']['lines'][lang]}")
                        failures += 1
                elif solved:
                    print(f"✗ {m['id']} {lang}: Starter-Code löst die Mission schon")
                    failures += 1

        if "python" in logs and "csharp" in logs and logs["python"] != logs["csharp"]:
            for i, (a, b) in enumerate(zip(logs["python"], logs["csharp"])):
                if a != b:
                    print(f"✗ {m['id']} Variante {i + 1}: Python und C# verhalten sich "
                          f"unterschiedlich\n    py: {a[:12]}\n    cs: {b[:12]}")
            failures += 1

    print(f"{len(missions)} Missionen geprüft, {failures} Fehler.")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
