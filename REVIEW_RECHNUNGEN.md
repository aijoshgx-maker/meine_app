# Review: Rechnung-Fragen – Konsistenzprüfung

Erzeugt von `tool/check_rechnungen.dart`.

Heuristik: letzte im Erklärtext/workedExample genannte Zahl vor der Einheit wird mit `loesungswert ± toleranz` verglichen. **Kein Beweis für einen Fehler** - jeder Treffer muss manuell geprüft werden (Formeln mit Zwischenschritten, mehrdeutige Einheiten-Strings usw. erzeugen auch Falsch-Positive).

Geprüfte rechnung-Fragen: 97
Ohne erkennbaren Zahl-Kandidaten (Heuristik greift nicht): 29
Treffer (Differenz > Toleranz): 4

## Treffer

Alle 4 Treffer wurden manuell geprüft (Stand: P3d) - **alle Fehlalarme**.
Ursache jeweils: Erklärung/workedExample nennt mehrere Zahlen mit derselben
Einheit (Zwischenschritt oder verwandte Größe), die Heuristik nimmt aber
immer die *letzte* Zahl vor der Einheit im gesamten Text, nicht die
tatsächliche Antwort.

- **au-tp-003** (auftragsanalyse_toleranzen_passungen.json): loesungswert = 50.025 mm ± 0.0005, im Text gefunden: 0.025 mm (Differenz: 50.000).
  → Fehlalarm: `50,025 mm` (Höchstmaß, richtig) steht im Text, die Heuristik
  hat aber die spätere Erwähnung der *Toleranz* `T = 0,025 mm` im
  workedExample erwischt. Keine Änderung nötig.
- **au-tp-004** (auftragsanalyse_toleranzen_passungen.json): loesungswert = 50.0 µm ± 0.0, im Text gefunden: 9.0 µm (Differenz: 41.000).
  → Fehlalarm: Frage fragt nach dem *Höchstspiel* (50 µm, korrekt), die
  Erklärung nennt zusätzlich das *Mindestspiel* (9 µm) zur Einordnung -
  das war die zuletzt genannte Zahl. Keine Änderung nötig.
- **ft-cnc-017** (fertigungstechnik_cnc_grundlagen.json): loesungswert = 56.0 mm ± 1.0, im Text gefunden: 33.0 mm (Differenz: 23.000).
  → Fehlalarm: Frage fragt nach der *X*-Koordinate (56 mm, korrekt), die
  Erklärung nennt zusätzlich die *Y*-Koordinate (33 mm) zur Vollständigkeit.
  Keine Änderung nötig.
- **ft-ww-010** (fertigungstechnik_werkstoffe_waermebehandlung.json): loesungswert = 6.6 HRC ± 0.5, im Text gefunden: 58.0 HRC (Differenz: 51.400).
  → Fehlalarm: Frage fragt nach der *fehlenden* Härte (6,6 HRC, korrekt),
  das workedExample endet aber mit einer Erinnerung an die *Soll*-Härte
  ("... statt 58 HRC") - das war die zuletzt genannte Zahl. Keine Änderung
  nötig.
