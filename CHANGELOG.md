# Changelog

Alle inhaltlichen und technischen Änderungen aus der Überarbeitung nach
`CLAUDE_CODE_PROMPTS.md` (P0–P12). Format lose an
[Keep a Changelog](https://keepachangelog.com) angelehnt.

## [1.1.0] – 2026-08-16

### ⚠️ Wichtig für bestehende Nutzer: korrigierte Lösungswerte

Die folgenden Fragen hatten einen **falschen Lösungswert** - wer sie schon
bearbeitet hat, wurde für die *richtige* Antwort bestraft und hat unter
Umständen den falschen Wert gelernt. Bitte diese Karten im FSRS-Store
gezielt wiederholen bzw. beim nächsten Update auf "neu" zurücksetzen:

| ID | Datei | Alt | Neu |
|---|---|---|---|
| `ft-sd-005` | fertigungstechnik_schnittdaten | 6,0 cm³/min | **60,0 cm³/min** |
| `au-tb-009` | auftragsanalyse_technische_berechnungen | 15,0 kN | **21,8 kN** |
| `au-ih-007` | auftragsanalyse_instandhaltung | 87,5 % | **86,96 %** |
| `wi-ent-006` | wiso_entgelt | 3340,75 € | **3339,25 €** |
| `ft-ws-012` | fertigungstechnik_werkzeuge_schneidstoffe | 9,2 min | **9,8 min** |
| `wi-sv-021` | wiso_sozialversicherung | 73,35 € | **78,75 €** (Rechtsstand-Update, nicht nur Rechenfehler) |
| `au-tz-002` | auftragsanalyse_technisches_zeichnen | `wahr: true` | **`wahr: false`** (Aussage war invertiert) |

Zusätzlich waren die Erklärtexte (nicht der Lösungswert) bei `ft-fv-015`
(Faktor-10-Fehler, 39,6 statt 3,96 kNm) und `au-pn-016` (2808 statt
2803,1 mm²) rechnerisch falsch.

### Hinzugefügt
- Validator (`tool/validate_fragen.dart`) und Report-Tool
  (`tool/report_fragen.dart`) für den gesamten Fragenbestand.
- `tool/check_rechnungen.dart`: Heuristik-Check für `rechnung`-Fragen
  gegen den eigenen Erklärtext.
- `tool/rebalance_positionen.dart`: Einmal-Migration zur Auflockerung der
  Antwortpositionsverteilung bei `single`-Fragen.
- `tool/normalize_fragen.dart`: expandiert Minimalformat-Fragendateien
  aufs Vollformat (siehe `docs/FRAGENFORMAT.md`).
- Laufzeit-Shuffle der Antwortoptionen bei jeder Frage-Anzeige
  (`lib/core/quiz/options_shuffle.dart`) - Position der richtigen Antwort
  ist nicht mehr erlernbar.
- Robuste Antworterkennung (`lib/core/matching/antwort_matcher.dart`):
  Umlaut-, Bindestrich- und Dezimaltrennzeichen-Varianten werden jetzt
  automatisch akzeptiert, auch bei Fachgespräch-Schlüsselwörtern
  (tokenweises statt Teilstring-Matching).
- Backup: Export/Import des kompletten Lernstands als JSON-Datei
  (`lib/data/backup_store.dart`, `lib/features/settings/screens/backup_screen.dart`),
  drei Importmodi (Ersetzen/Zusammenführen/Abbrechen), unbekannte
  Frage-IDs werden übersprungen statt den Import abzubrechen.
- Zentraler WISO-Rechtsstand (`assets/fragen/_rechtsstand.json`) mit
  Quellenangaben, Anzeige in den Einstellungen, Validator-Warnung bei
  Veralterung (> 14 Monate).
- Stückliste je Prüfung (`PruefungsInfo.stueckliste`) als Fallback-
  Textliste, wenn eine Prüfungszeichnung fehlt.
- Anzeige der tatsächlich verfügbaren Aufgabenzahl je Prüfung in der
  Prüfungssimulations-Auswahl (unvollständige Datensätze werden nicht
  mehr stillschweigend simuliert).
- `assets/kurse/ap2-industriemechaniker/kurs.json`: Strukturfundament für
  die geplante Mehrkurs-Generalisierung (P11a, noch nicht von Screens
  gelesen).
- `docs/FRAGENFORMAT.md`: Pflichtfelder je Fragetyp mit Vollformat-Beispielen.
- Neue Tests: `antwort_matcher_test.dart`, `backup_store_test.dart`,
  `options_shuffle_test.dart`, `quiz_bewertung_test.dart` (alle 8
  Fragetypen inkl. Toleranzgrenze-Randfall), `frage_repository_bom_test.dart`.
- CI (`android-ci.yml`) führt jetzt `dart run tool/validate_fragen.dart` aus.

### Behoben
- 4 Fragendateien mit UTF-8-BOM luden nicht (`FrageRepository` fängt
  Ladefehler jetzt zusätzlich pro Datei ab).
- `fertigungstechnik_werkzeuge_schneidstoffe.json` komplett neu
  geschrieben (0 Umlaute im Originalzustand - verstümmeltes Deutsch).
- `ft-mp-003` (unbeantwortbare Frage) in zwei lösbare Fragen aufgeteilt
  (`ft-mp-003`, `ft-mp-003b`).
- 3 als `rechnung` getypte Fragen ohne Lösungswert auf `single`
  umgestellt (`ft-ww-005`, `wi-mp-013`, `wi-sv-015`); `wi-sv-015`
  zusätzlich inhaltlich repariert (widersprüchliche Angaben).
- 9 falsche Lösungswerte/Rechenfehler korrigiert (siehe Tabelle oben).
- 7 veraltete WISO-Rechtsstand-Werte aktualisiert (Stand 2026-08-16,
  Quellen in `_rechtsstand.json`): GKV-Zusatzbeitrag, Beitragsbemessungs-
  grenzen, Minijob-Grenze, PV-Satz, Essensgutschein-Freigrenze,
  EZB-Inflationsziel, Musterfeststellungsklage → VDuG/Abhilfeklage.
- 3 fachlich strittige Fragen korrigiert: Passfeder-Formschluss
  (`au-fa-002`), Wälzlager-Lastzuordnung (`fg-001-f03`), ungültige
  Werkstoffbezeichnung `CuSnB` → `CuSn8` (5 Fundstellen).
- 2 wortidentische/inhaltsgleiche Duplikate durch neue Fragen ersetzt
  (`au-sr-021`, `au-tb-030`).
- 3 `reihenfolge`-Fragen mit Identitätspermutation behoben
  (`au-fa-006`, `au-tz-011`, `ft-zg-012`).
- 3 Beispiele für zu leichte `multi`-Fragen (4-von-5) entschärft.
- `fg-005` fehlten `fertigungsauftrag`, `zeichnungsKey`, `kategorien`
  komplett - ergänzt (das waren die letzten 2 Validator-Fehler).
- `zeichnungsKey` bei `fg-004` (S17), `fg-006` (S18) ergänzt.
- ID-Präfixe vereinheitlicht: `wiso-av-*` → `wi-av-*`,
  `wiso-ba-*` → `wi-ba-*` (App war noch nicht veröffentlicht, daher ohne
  FSRS-Migration).
- App-Label „meine_app" → „AP2 Trainer" (Android + iOS).
- `android.permission.DUMP` defensiv ausgeschlossen (war in den
  aktuellen Quell-Manifesten ohnehin nicht mehr vorhanden).
- `zuordnung`-Bewertungslogik: verglich zuvor Auswahl-Positionen gegen
  eine bei jedem Aufruf neu sortierte rechte Spalte - potenzielle
  Fehlerquelle, jetzt über stabile Original-Indizes gelöst.

### Geändert
- `versionName`: `1.0.0` → `1.1.0` (Build-Nummer 2).
- `pubspec.yaml`-Beschreibung auf echten Produkttext gesetzt.

### Nicht umgesetzt (siehe `REVIEW_OFFEN.md` für Details und Gründe)
- P9: automatischer wöchentlicher Backup-Export (als "optional" markiert).
- P10a: Package-Name-Änderung (`joshai.meine_app`) - auf Nutzerwunsch
  zurückgestellt, **muss vor jeder Store-Veröffentlichung nachgeholt
  werden** (danach unwiderruflich).
- P11b: Import externer Kurs-Fragensätze aus `.zip`.
- P11a (Teil 2): Screens lesen noch nicht aus `kurs.json`, FSRS-Karten
  sind noch nicht pro Kurs getrennt.
- 34 von 37 identifizierten zu leichten `multi`-Fragen (4-von-5) - Liste
  mit Anleitung in `REVIEW_OFFEN.md`.
- Diverse fachliche Detailfragen, die echte Fachprüfung statt Software-
  Entscheidung brauchen (Werkstoffbezeichnung `CuSnB`-Ambiguität,
  `ft-cnc-025`-Kegeldurchmesser, S17/W22-Prüfungszuordnung bei
  `au-wk-018` u. a.) - vollständige Liste in `REVIEW_OFFEN.md`.

### Validator-Bilanz
27 Fehler → **0 Fehler** (`AUDIT_BASELINE.txt` vs. aktueller Lauf).
83 → 75 Warnungen (die verbleibenden sind bewusst dokumentierte
Restarbeit, keine stillen Lücken).
