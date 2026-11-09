#!/usr/bin/env python3
"""Prüft die Musterlösungen aller Herausforderungen gegen ihre Testfälle.

Aufruf:
    python3 tool/verify_challenges.py python
    python3 tool/verify_challenges.py csharp   # braucht das .NET SDK

C#-Code wird wie in der App (csharp_runtime/) als Programm mit
Top-Level-Statements und impliziten usings kompiliert.
"""
import json
import os
import subprocess
import sys
import tempfile

BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "content")

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
    <LangVersion>latest</LangVersion>
    <Nullable>disable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <InvariantGlobalization>true</InvariantGlobalization>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
""")
        with open(os.path.join(self.dir, "nuget.config"), "w") as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n<configuration>'
                    '<packageSources><clear /></packageSources></configuration>\n')

    def build(self, code):
        with open(os.path.join(self.dir, "Program.cs"), "w") as f:
            f.write(code)
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
