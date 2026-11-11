# Installation

## Im Browser (PC, Laptop, Tablet)

Ohne Installation: **[bac-htl.github.io/prog_trainer/app](https://bac-htl.github.io/prog_trainer/app/)** öffnen. Das funktioniert auch auf Schul-PCs, auf denen man nichts installieren darf. Python und C# laufen direkt im Browser.

!!! note "Wo dein Fortschritt gespeichert wird"
    Im Browser liegt der Fortschritt im Speicher **dieses** Browsers auf
    **diesem** Gerät. Er geht verloren, wenn du die Browserdaten löschst,
    im privaten Fenster arbeitest oder ein Schul-PC dein Profil beim
    Abmelden zurücksetzt. Sichere ihn deshalb ab und zu (siehe unten).


## Android

1. Am Handy die [APK herunterladen](https://github.com/BAC-HTL/prog_trainer/releases/download/latest/prog_trainer.apk).
2. Die Datei `prog_trainer.apk` antippen.
3. Wenn Android fragt, **Installation aus unbekannten Quellen** für den Browser bzw. die Dateien-App erlauben.
4. **Installieren** antippen.

!!! warning "Google Play Protect"
    Weil die App nicht aus dem Play Store kommt, kann Play Protect warnen.
    Mit „Trotzdem installieren“ geht es weiter.

## iOS (iPhone/iPad)

Apple erlaubt Apps außerhalb des App Stores nur signiert. Die
[IPA-Datei](https://github.com/BAC-HTL/prog_trainer/releases/download/latest/prog_trainer-unsigned.ipa)
ist unsigniert und muss vor der Installation signiert werden:

1. Am PC oder Mac [Sideloadly](https://sideloadly.io) oder
   [AltStore](https://altstore.io) installieren.
2. iPhone per Kabel verbinden, die IPA hineinziehen und mit der eigenen
   (kostenlosen) Apple-ID anmelden.
3. Am iPhone: Einstellungen → Allgemein → VPN & Geräteverwaltung → dem
   Entwickler vertrauen.

!!! note "7 Tage gültig"
    Mit einer kostenlosen Apple-ID läuft die Signatur nach 7 Tagen ab und
    muss erneuert werden. Eine dauerhafte Verteilung (TestFlight / App
    Store) braucht einen Apple-Developer-Account (99 $/Jahr).

## Update

Neue Version herunterladen und drüberinstallieren. Der Fortschritt bleibt
erhalten.

## Code ausführen – ohne Anmeldung

Python und C# laufen **direkt am Handy**. Es braucht kein Konto, keinen
API-Key und keinen Server. Beim ersten Ausführen lädt die App die jeweilige
Laufzeit einmalig herunter (Python ca. 10 MB, C# ca. 14 MB). Danach kommt sie
aus dem Zwischenspeicher, und es geht in Sekundenbruchteilen.

## Fortschritt sichern & auf ein anderes Gerät übertragen

Es gibt kein Konto. Dein Fortschritt bleibt auf deinem Gerät. So nimmst du ihn mit:

- **Übertragungscode:** In den Einstellungen auf „Übertragungscode kopieren“ tippen, den Code zum anderen Gerät schicken (z. B. per Mail oder Messenger an dich selbst) und dort „Übertragungscode einfügen“ wählen. Das klappt zwischen Handy-App und Browser in beide Richtungen.
- **Sicherungsdatei (Browser):** „Sicherung herunterladen“ speichert eine Datei `prog_trainer_fortschritt.json`. Mit „Sicherung öffnen“ lädst du sie wieder.

Beim Einlesen wird der Fortschritt auf dem Gerät **ersetzt**. Das enthält Lektionen, Prüfungen und Zertifikate, Punkte, Sterne, Achievements, deinen Namen und die Programmiersprache.
