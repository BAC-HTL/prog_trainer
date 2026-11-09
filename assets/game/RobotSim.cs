using System;
using System.Collections.Generic;

// Roboter-Simulation für den Spielmodus (C#).
//
// WICHTIG: Muss sich exakt so verhalten wie robot_sim.py!
// tool/verify_missions.py prüft das automatisch.
// Muss mit C# 7.3 kompilieren (Judge0 hat nur Mono). Keine geschweiften
// Klammern in Strings oder Kommentaren verwenden (der Code-Umbau zählt sie).
//
// Ablauf: Die App setzt `Robot.Start();` vor deinen Code und hängt diese
// Datei an. Karte und Startwerte kommen über die Standardeingabe.
public static class Robot
{
    const string Richtungen = "NOSW";
    const int MaxAktionen = 1000;

    static char[][] karte;
    static int x, y, energie, aktionen;
    static string richtung;
    static List<string> inv = new List<string>();

    public static void Start()
    {
        string[] kopf = Console.ReadLine().Split(' ');
        var zeilen = new List<char[]>();
        string zeile;
        while ((zeile = Console.ReadLine()) != null && zeile != "")
            zeilen.Add(zeile.ToCharArray());
        karte = zeilen.ToArray();
        x = int.Parse(kopf[0]);
        y = int.Parse(kopf[1]);
        richtung = kopf[2];
        energie = int.Parse(kopf[3]);
        Ev("START " + x + " " + y + " " + richtung + " " + energie);
    }

    // ---------- intern ----------
    static void Ev(string s)
    {
        Console.WriteLine("@@" + s);
    }

    static void Fehler(string code)
    {
        Ev("FEHLER " + code);
        Console.Out.Flush();
        Environment.Exit(0);
    }

    static void Zaehle()
    {
        aktionen++;
        if (aktionen > MaxAktionen) Fehler("LIMIT");
    }

    static char Feld(int fx, int fy)
    {
        if (fy >= 0 && fy < karte.Length && fx >= 0 && fx < karte[fy].Length)
            return karte[fy][fx];
        return '#';
    }

    static int Dx() { return richtung == "O" ? 1 : richtung == "W" ? -1 : 0; }
    static int Dy() { return richtung == "S" ? 1 : richtung == "N" ? -1 : 0; }

    static string Name(char f)
    {
        switch (f)
        {
            case '#': return "fels";
            case '~': return "lava";
            case 'K': return "kristall";
            case 'M': return "moos";
            case 'E': return "erz";
            case 'Q': return "quelle";
            case 'L': return "labor";
            case 'Z': return "basis";
            default: return "boden";
        }
    }

    static string Item(char f)
    {
        switch (f)
        {
            case 'K': return "kristall";
            case 'M': return "moos";
            case 'E': return "erz";
            case 'Q': return "wasser";
            default: return null;
        }
    }

    static string Rezept(string a, string b)
    {
        string paar = string.CompareOrdinal(a, b) <= 0 ? a + "+" + b : b + "+" + a;
        switch (paar)
        {
            case "kristall+wasser": return "energiezelle";
            case "moos+wasser": return "biogel";
            case "erz+kristall": return "legierung";
            case "biogel+legierung": return "nanobot";
            default: return null;
        }
    }

    // ---------- Bewegung ----------
    public static void Vor()
    {
        Zaehle();
        if (energie <= 0) Fehler("AKKU");
        int nx = x + Dx(), ny = y + Dy();
        char f = Feld(nx, ny);
        if (f == '#') Fehler("FELS");
        x = nx;
        y = ny;
        energie--;
        Ev("MOVE " + nx + " " + ny + " " + energie);
        if (f == '~') Fehler("LAVA");
    }

    public static void Links()
    {
        Zaehle();
        richtung = Richtungen[(Richtungen.IndexOf(richtung) + 3) % 4].ToString();
        Ev("TURN " + richtung);
    }

    public static void Rechts()
    {
        Zaehle();
        richtung = Richtungen[(Richtungen.IndexOf(richtung) + 1) % 4].ToString();
        Ev("TURN " + richtung);
    }

    // ---------- Sensoren ----------
    public static bool IstFrei()
    {
        Zaehle();
        char f = Feld(x + Dx(), y + Dy());
        return f != '#' && f != '~';
    }

    public static string Vorne()
    {
        Zaehle();
        return Name(Feld(x + Dx(), y + Dy()));
    }

    public static string Scannen()
    {
        Zaehle();
        string name = Name(Feld(x, y));
        Ev("SCAN " + name);
        return name;
    }

    public static int X { get { Zaehle(); return x; } }
    public static int Y { get { Zaehle(); return y; } }
    public static string Richtung { get { Zaehle(); return richtung; } }
    public static int Energie { get { Zaehle(); return energie; } }

    public static List<string> Inventar()
    {
        Zaehle();
        return new List<string>(inv);
    }

    // ---------- Labor ----------
    public static string Aufheben()
    {
        Zaehle();
        char f = Feld(x, y);
        string item = Item(f);
        if (item == null) Fehler("NICHTS");
        inv.Add(item);
        if (f != 'Q') karte[y][x] = '.';
        Ev("PICK " + item + " " + x + " " + y);
        return item;
    }

    public static string Mischen(string a, string b)
    {
        Zaehle();
        if (Feld(x, y) != 'L') Fehler("KEINLABOR");
        var rest = new List<string>(inv);
        if (!rest.Remove(a)) Fehler("FEHLT " + a);
        if (!rest.Remove(b)) Fehler("FEHLT " + b);
        string ergebnis = Rezept(a, b);
        if (ergebnis == null) Fehler("REZEPT " + a + " " + b);
        rest.Add(ergebnis);
        inv = rest;
        Ev("MIX " + a + " " + b + " " + ergebnis);
        return ergebnis;
    }
}
