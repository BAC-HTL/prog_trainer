# Roboter-Simulation für den Spielmodus (Python).
#
# WICHTIG: Muss sich exakt so verhalten wie RobotSim.cs!
# tool/verify_missions.py prüft das automatisch.
#
# Ablauf: Die App hängt an diese Datei die Zeile `_starte(<dein code>)` an.
# Karte und Startwerte kommen über die Standardeingabe:
#   Zeile 1: "x y Richtung Energie"
#   danach:  Kartenzeilen
# Der Roboter meldet jede Aktion als Zeile "@@EREIGNIS ..." – daraus
# animiert die App den Ablauf und prüft die Missionsziele.

_RICHTUNGEN = "NOSW"
_DELTA = {"N": (0, -1), "O": (1, 0), "S": (0, 1), "W": (-1, 0)}
_ITEMS = {"K": "kristall", "M": "moos", "E": "erz", "Q": "wasser"}
_NAMEN = {
    "#": "fels", "~": "lava", ".": "boden", "K": "kristall", "M": "moos",
    "E": "erz", "Q": "quelle", "L": "labor", "Z": "basis",
}
_REZEPTE = {
    "kristall+wasser": "energiezelle",
    "moos+wasser": "biogel",
    "erz+kristall": "legierung",
    "biogel+legierung": "nanobot",
}
_MAX_AKTIONEN = 1000


class RobotFehler(Exception):
    pass


def _ev(*teile):
    print("@@" + " ".join(str(t) for t in teile))


def _rezept(a, b):
    paar = "+".join(sorted([a, b]))
    return _REZEPTE.get(paar)


class _Robot:
    def __init__(self, karte, x, y, richtung, energie):
        self._karte = [list(z) for z in karte]
        self._x = x
        self._y = y
        self._r = richtung
        self._e = energie
        self._inv = []
        self._aktionen = 0
        _ev("START", x, y, richtung, energie)

    # ---------- intern ----------
    def _fehler(self, *code):
        _ev("FEHLER", *code)
        raise RobotFehler(" ".join(code))

    def _zaehle(self):
        self._aktionen += 1
        if self._aktionen > _MAX_AKTIONEN:
            self._fehler("LIMIT")

    def _feld(self, x, y):
        if 0 <= y < len(self._karte) and 0 <= x < len(self._karte[y]):
            return self._karte[y][x]
        return "#"

    def _vorne_xy(self):
        dx, dy = _DELTA[self._r]
        return self._x + dx, self._y + dy

    # ---------- Bewegung ----------
    def vor(self):
        self._zaehle()
        if self._e <= 0:
            self._fehler("AKKU")
        nx, ny = self._vorne_xy()
        f = self._feld(nx, ny)
        if f == "#":
            self._fehler("FELS")
        self._x, self._y = nx, ny
        self._e -= 1
        _ev("MOVE", nx, ny, self._e)
        if f == "~":
            self._fehler("LAVA")

    def links(self):
        self._zaehle()
        self._r = _RICHTUNGEN[(_RICHTUNGEN.index(self._r) + 3) % 4]
        _ev("TURN", self._r)

    def rechts(self):
        self._zaehle()
        self._r = _RICHTUNGEN[(_RICHTUNGEN.index(self._r) + 1) % 4]
        _ev("TURN", self._r)

    # ---------- Sensoren ----------
    def ist_frei(self):
        self._zaehle()
        nx, ny = self._vorne_xy()
        return self._feld(nx, ny) not in "#~"

    def vorne(self):
        self._zaehle()
        nx, ny = self._vorne_xy()
        return _NAMEN[self._feld(nx, ny)]

    def scannen(self):
        self._zaehle()
        name = _NAMEN[self._feld(self._x, self._y)]
        _ev("SCAN", name)
        return name

    def position(self):
        self._zaehle()
        return (self._x, self._y)

    def richtung(self):
        self._zaehle()
        return self._r

    def energie(self):
        self._zaehle()
        return self._e

    def inventar(self):
        self._zaehle()
        return list(self._inv)

    # ---------- Labor ----------
    def aufheben(self):
        self._zaehle()
        f = self._feld(self._x, self._y)
        if f not in _ITEMS:
            self._fehler("NICHTS")
        item = _ITEMS[f]
        self._inv.append(item)
        if f != "Q":
            self._karte[self._y][self._x] = "."
        _ev("PICK", item, self._x, self._y)
        return item

    def mischen(self, a, b):
        self._zaehle()
        if self._feld(self._x, self._y) != "L":
            self._fehler("KEINLABOR")
        rest = list(self._inv)
        if a not in rest:
            self._fehler("FEHLT", a)
        rest.remove(a)
        if b not in rest:
            self._fehler("FEHLT", b)
        rest.remove(b)
        ergebnis = _rezept(a, b)
        if ergebnis is None:
            self._fehler("REZEPT", a, b)
        rest.append(ergebnis)
        self._inv = rest
        _ev("MIX", a, b, ergebnis)
        return ergebnis


def _starte(code):
    kopf = input().split()
    karte = []
    while True:
        try:
            zeile = input()
        except EOFError:
            break
        if zeile == "":
            break
        karte.append(zeile)
    robot = _Robot(karte, int(kopf[0]), int(kopf[1]), kopf[2], int(kopf[3]))
    umgebung = {"robot": robot, "RobotFehler": RobotFehler, "__name__": "__main__"}
    try:
        programm = compile(code, "<dein code>", "exec")
    except SyntaxError as e:
        _ev("CODE", "Zeile " + str(e.lineno) + ": SyntaxError: " + str(e.msg))
        return
    try:
        exec(programm, umgebung)
    except RobotFehler:
        pass
    except Exception as e:
        import traceback
        zeile = None
        for frame in traceback.extract_tb(e.__traceback__):
            if frame.filename == "<dein code>":
                zeile = frame.lineno
        ort = "Zeile " + str(zeile) + ": " if zeile else ""
        _ev("CODE", ort + type(e).__name__ + ": " + str(e))
