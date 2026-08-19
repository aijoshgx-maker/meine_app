# Lernkarten-Trainer

Eine Offline-Lern-App mit Wiederholungsplanung nach **FSRS**. Sie ist nicht
auf ein Thema festgelegt: Lernpakete lassen sich als Datei importieren, und
jeder Kurs führt seinen Lernfortschritt getrennt.

Mitgeliefert wird ein vollständiger Kurs für die **IHK-Abschlussprüfung
Teil 2, Industriemechaniker** — 681 Fragen, vier echte Prüfungen, 38
Fachgespräch-Szenarien.

**Web-Version:** https://aijoshgx-maker.github.io/meine_app/

---

## Was die App kann

**Acht Fragetypen** — Single- und Mehrfachauswahl, Wahr/Falsch, Rechnen mit
Toleranz, Kurzantwort, Lückentext, Zuordnung, Reihenfolge.

**Wiederholung nach FSRS 4.5** — eigene Implementierung in
[`fsrs_scheduler.dart`](lib/core/spaced_repetition/fsrs_scheduler.dart). Der
nächste Termin folgt aus dem tatsächlichen Antwortverhalten, nicht aus festen
Stufen.

**Hypercorrection** — wer sich sicher war und trotzdem falsch lag, bekommt
das Intervall halbiert. Solche Karten sammeln sich im Modus *Fehlerquellen*
und verschwinden dort, sobald sie sitzen.

**Konfidenz-Kalibrierung** — vor dem Aufdecken schätzt man sich selbst ein.
Das Dashboard zeigt, wie gut Selbsteinschätzung und Trefferquote
zusammenpassen.

**Fünf Modi** — Frei üben · Heute fällig · Thema vertiefen · Fehlerquellen ·
Testlauf auf Zeit.

**Eigene Kurse** — Lernpakete als `.json` oder `.zip` importieren. Format in
[`docs/PAKETFORMAT.md`](docs/PAKETFORMAT.md), Beispiel in
[`docs/beispiel-lernpaket.json`](docs/beispiel-lernpaket.json).

**Komplett offline** — kein Konto, kein Tracking, nicht einmal die
`INTERNET`-Berechtigung. Alles liegt lokal in Hive und lässt sich als Datei
sichern.

---

## Aufbau

```
lib/
├── app/          MaterialApp, GoRouter, Shell, Einstellungen
├── core/
│   ├── kurse/            Paket-Parser (JSON/ZIP), Bildauflösung
│   ├── matching/         Antwortvergleich mit Normalisierung
│   ├── plattform/        Datei-Zugriff, bedingt für io/web
│   ├── quiz/             Mischen der Antwortoptionen
│   └── spaced_repetition/  FSRS
├── data/         Repositories, Hive-Stores, Migrationen, Backup
├── models/       Kurs, Lernpaket, Frage, Szenario
└── features/     dashboard · quiz · kurse · fachgespraech
                  pruefungssimulation · themenauswahl · settings
```

**Stack:** Flutter · Riverpod 3 · go_router · Hive · fl_chart

Kein Code-Generator — alle `fromJson`/`toMap` sind handgeschrieben.

### Zwei Entscheidungen, die den Rest erklären

**Lernfortschritt hängt an `kursId::frageId`.** Ohne diese Trennung würden
gleichnamige Frage-IDs aus verschiedenen Kursen einander überschreiben.
[`migrationen.dart`](lib/data/migrationen.dart) schlüsselt Bestandsdaten beim
ersten Start um — idempotent, ein Abbruch mittendrin schadet nicht.

**Datei-Zugriffe laufen über eine Plattform-Naht.** `dart:io` gibt es im
Web-Build nicht, und `kIsWeb`-Abfragen helfen nicht, weil schon der *Import*
scheitert. Deshalb existiert
[`datei_ablage.dart`](lib/core/plattform/datei_ablage.dart) zweimal, gewählt
per bedingtem Import. Ein Test wacht darüber, dass kein Anwendungscode
`dart:io` direkt einbindet.

---

## Entwicklung

```bash
flutter pub get
flutter run

flutter analyze          # muss 0/0/0 sein
flutter test             # 157 Tests
dart format lib test
```

### Werkzeuge

```bash
dart run tool/validate_fragen.dart   # Fragenbestand prüfen
dart run tool/report_fragen.dart     # Statistik
dart run flutter_launcher_icons      # Icons neu erzeugen
python tool/icons.py                 # Icon-Grafiken neu zeichnen
```

### Builds

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release --base-href /meine_app/
```

> In Git Bash `MSYS_NO_PATHCONV=1` voranstellen, sonst wird `--base-href` zu
> einem Windows-Pfad verbogen.

Der Web-Build wird bei jedem Push auf `master` automatisch nach GitHub Pages
veröffentlicht.

**Signatur:** Der Release-Build liest `android/key.properties`. Fehlt die
Datei, fällt er stillschweigend auf den Debug-Key zurück — praktisch für
`flutter run --release`, aber nicht store-tauglich. Die Prüfung dafür steht
in [`docs/release-checklist.md`](docs/release-checklist.md).

---

## Dokumentation

| Datei | Inhalt |
|---|---|
| [`docs/PAKETFORMAT.md`](docs/PAKETFORMAT.md) | Aufbau eines Lernpakets |
| [`docs/FRAGENFORMAT.md`](docs/FRAGENFORMAT.md) | Aufbau einer einzelnen Frage |
| [`docs/release-checklist.md`](docs/release-checklist.md) | Vor dem Veröffentlichen |
| [`docs/store/`](docs/store/) | Datenschutz und Store-Texte |
| [`CHANGELOG.md`](CHANGELOG.md) | Änderungen je Version |
| [`REVIEW_OFFEN.md`](REVIEW_OFFEN.md) | Offene inhaltliche Fragen |
