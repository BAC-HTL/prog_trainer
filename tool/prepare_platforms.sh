#!/usr/bin/env bash
# Erzeugt die Plattform-Ordner (android/, ios/), falls sie fehlen, und setzt
# die Einstellungen, die die App braucht. Vorhandene Dateien bleiben erhalten.
#
#   ./tool/prepare_platforms.sh            # Android + iOS
#   ./tool/prepare_platforms.sh android    # nur Android
set -euo pipefail
cd "$(dirname "$0")/.."

PLATFORMS="${1:-android,ios}"
flutter create --platforms="$PLATFORMS" --org at.bachtl --project-name prog_trainer .

MANIFEST=android/app/src/main/AndroidManifest.xml
if [ -f "$MANIFEST" ] && ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  # Internet wird beim ersten Start gebraucht, um die Python- und C#-Laufzeit zu laden.
  perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$MANIFEST"
fi
if [ -f "$MANIFEST" ]; then
  perl -0pi -e 's#android:label="prog_trainer"#android:label="Prog Trainer"#' "$MANIFEST"
fi

PODFILE=ios/Podfile
if [ -f "$PODFILE" ]; then
  # Plugins brauchen mindestens iOS 13.
  perl -0pi -e "s/^#?\s*platform :ios, '[0-9.]+'/platform :ios, '13.0'/m" "$PODFILE"
fi
PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ]; then
  perl -0pi -e 's#(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)#$1Prog Trainer$2#' "$PLIST"
fi

# App-Icon aus assets/icon/ erzeugen (Konfiguration in pubspec.yaml).
flutter pub get
dart run flutter_launcher_icons

echo "Plattform-Ordner bereit."
