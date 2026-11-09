#!/usr/bin/env bash
# Baut die C#-Laufzeit (Roslyn + .NET als WebAssembly) und packt sie so,
# wie sie auf GitHub Pages veröffentlicht wird:
#   * .wasm-Dateien nur noch gzip-komprimiert (main.js/worker.js entpacken
#     sie im Browser) – halbiert Größe und Dateianzahl
#   * keine Brotli-Dateien
#
#   ./tool/package_csharp_runtime.sh <zielordner>
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:?Zielordner angeben}"

dotnet publish csharp_runtime -c Release -o csharp_runtime/out
rm -rf "$OUT"
cp -r csharp_runtime/out/wwwroot "$OUT"

find "$OUT" -name '*.br' -delete
# Unkomprimierte .wasm löschen, wenn es eine .gz-Version gibt.
find "$OUT" -name '*.wasm' | while read -r f; do
  [ -f "$f.gz" ] && rm "$f"
done

echo "C#-Laufzeit: $(du -sh "$OUT" | cut -f1), $(find "$OUT" -type f | wc -l) Dateien"
