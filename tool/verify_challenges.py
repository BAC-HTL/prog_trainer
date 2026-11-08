#!/usr/bin/env python3
"""Prüft die Musterlösungen aller Herausforderungen gegen ihre Testfälle.

Aufruf:
    python3 tool/verify_challenges.py python
    python3 tool/verify_challenges.py csharp   # braucht das .NET SDK

C#-Code wird genauso umgebaut wie in der App (siehe lib/runner/csharp_wrapper.dart)
und mit LangVersion 7.3 kompiliert, weil der Judge0-Server nur Mono (≈ C# 7) hat.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "content")

DEFAULT_USINGS = [
    "using System;",
    "using System.Collections.Generic;",
    "using System.Linq;",
    "using System.Text;",
]
MAIN_RE = re.compile(r"static\s+(void|int|async\s+Task(<int>)?)\s+Main\s*\(")
TYPE_RE = re.compile(
    r"^((public|internal|static|abstract|sealed|partial)\s+)*(class|struct|enum|interface)\s+\w+"
)


def wrap_csharp(code: str) -> str:
    """Python-Kopie von wrapCSharp() aus lib/runner/csharp_wrapper.dart."""
    lines = code.replace("\r\n", "\n").split("\n")
    usings, types, body = [], [], []
    in_type, depth = False, 0
    for line in lines:
        t = line.strip()
        if (not in_type and t.startswith("using ") and t.endswith(";")
                and "=" not in t and "(" not in t):
            usings.append(t)
            continue
        if not in_type and TYPE_RE.match(line):
            in_type, depth = True, 0
        if in_type:
            types.append(line)
            depth += line.count("{") - line.count("}")
            if depth <= 0 and "}" in line:
                in_type = False
            continue
        body.append(line)

    header = []
    for u in DEFAULT_USINGS + usings:
        if u not in header:
            header.append(u)
    if MAIN_RE.search(code):
        return "\n".join(header + body + types) + "\n"
    out = header + ["", "class Program", "{", "static void Main()", "{"]
    out += body + ["}", "}", ""] + types
    return "\n".join(out) + "\n"


def normalize(s: str) -> str:
    lines = s.replace("\r\n", "\n").split("\n")
    return "\n".join(l.rstrip() for l in lines).rstrip()


def run_python(code, stdin):
    p = subprocess.run([sys.executable, "-c", code], input=stdin,
                       capture_output=True, text=True, timeout=10)
    return p.stdout, p.stderr, p.returncode


class CSharpRunner:
    def __init__(self):
        self.dir = tempfile.mkdtemp(prefix="csverify_")
        major = subprocess.run(["dotnet", "--version"], capture_output=True,
                               text=True).stdout.strip().split(".")[0]
        with open(os.path.join(self.dir, "v.csproj"), "w") as f:
            f.write(f"""<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net{major}.0</TargetFramework>
    <LangVersion>7.3</LangVersion>
    <Nullable>disable</Nullable>
    <ImplicitUsings>disable</ImplicitUsings>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
""")
        with open(os.path.join(self.dir, "nuget.config"), "w") as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n<configuration>'
                    '<packageSources><clear /></packageSources></configuration>\n')

    def build(self, code):
        with open(os.path.join(self.dir, "Program.cs"), "w") as f:
            f.write(wrap_csharp(code))
        p = subprocess.run(["dotnet", "build", "-c", "Release", "-o", "out",
                            "--nologo", "-v", "q"], cwd=self.dir,
                           capture_output=True, text=True, timeout=180)
        return p.returncode == 0, p.stdout + p.stderr

    def run(self, stdin):
        p = subprocess.run(["dotnet", os.path.join(self.dir, "out", "v.dll")],
                           input=stdin, capture_output=True, text=True, timeout=10)
        return p.stdout, p.stderr, p.returncode


def main():
    lang = sys.argv[1] if len(sys.argv) > 1 else "python"
    path = os.path.join(BASE, lang, "challenges.json")
    challenges = json.load(open(path, encoding="utf-8"))["challenges"]
    runner = CSharpRunner() if lang == "csharp" else None
    failures = 0
    for c in challenges:
        if runner:
            ok, log = runner.build(c["solution"])
            if not ok:
                print(f"✗ {c['id']}: Kompilierfehler\n{log}")
                failures += 1
                continue
        for i, t in enumerate(c["tests"]):
            if runner:
                out, err, code = runner.run(t.get("stdin", ""))
            else:
                out, err, code = run_python(c["solution"], t.get("stdin", ""))
            if code != 0 or normalize(out) != normalize(t["expected"]):
                print(f"✗ {c['id']} Test {i + 1}: erwartet {t['expected']!r}, "
                      f"bekommen {out!r} {err[-300:]!r}")
                failures += 1
    print(f"{len(challenges)} Herausforderungen geprüft, {failures} Fehler.")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
