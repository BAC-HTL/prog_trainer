#!/usr/bin/env bash
# Erzeugt die Plattform-Ordner (android/, ios/), falls sie fehlen, und setzt
# die Einstellungen, die die App braucht. Vorhandene Dateien bleiben erhalten.
#
#   ./tool/prepare_platforms.sh            # Android + iOS
#   ./tool/prepare_platforms.sh android    # nur Android
#   ./tool/prepare_platforms.sh web        # Web-Version (Browser)
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

WEB_INDEX=web/index.html
if [ -f "$WEB_INDEX" ]; then
  # Code-Ausführung im Browser (Python/C#) – siehe web/runners.js.
  grep -q 'runners.js' "$WEB_INDEX" ||
    perl -0pi -e 's#</head>#  <script src="runners.js"></script>\n</head>#' "$WEB_INDEX"
  perl -0pi -e 's#<title>[^<]*</title>#<title>Prog Trainer</title>#' "$WEB_INDEX"
  perl -0pi -e 's#(<meta name="description" content=")[^"]*#$1Informatik lernen nach dem HTL-Lehrplan – Python, C# und mehr.#' "$WEB_INDEX"
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

# App-Icon (Roboter mit ">_") aus assets/icon/ erzeugen – nur für die
# Plattformen, deren Ordner es gibt.
HAS_ANDROID=false; [ -d android ] && HAS_ANDROID=true
HAS_IOS=false; [ -d ios ] && HAS_IOS=true
HAS_WEB=false; [ -f web/index.html ] && HAS_WEB=true
ICON_CONFIG="$(mktemp -t icons-XXXX.yaml)"
cat > "$ICON_CONFIG" <<YAML
flutter_launcher_icons:
  android: $HAS_ANDROID
  ios: $HAS_IOS
  image_path: "assets/icon/icon.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#3949AB"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
  web:
    generate: $HAS_WEB
    image_path: "assets/icon/icon.png"
    background_color: "#3949AB"
    theme_color: "#3949AB"
YAML
flutter pub get
dart run flutter_launcher_icons -f "$ICON_CONFIG"
rm -f "$ICON_CONFIG"

echo "Plattform-Ordner bereit."
