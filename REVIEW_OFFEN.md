# Offene fachliche Review-Punkte

Diese Datei sammelt Stellen, an denen laut den globalen Arbeitsregeln aus
`CLAUDE_CODE_PROMPTS.md` **nicht geraten**, sondern zur fachlichen Prüfung
markiert wird (`// TODO-FACHPRÜFUNG`-Äquivalent für JSON-Daten).

---

## P3a — `ft-ws-012`: widersprüchliche Taylor-Konstante entfernt

**Datei:** `assets/fragen/fertigungstechnik_werkzeuge_schneidstoffe.json`

Die Frage nannte ursprünglich `C = 380` zusätzlich zu `m = 0,3` und den
Eckdaten `T = 30 min bei vc = 100 m/min`. Das ist intern widersprüchlich:
Mit der Taylor-Geradengleichung `T = (C/vc)^(1/m)` und C = 380, m = 0,3 ergäbe
sich bei vc = 100 m/min eine Standzeit von `(380/100)^(1/0,3) ≈ 85,6 min`,
nicht die in der Frage vorausgesetzten 30 min.

**Entscheidung für diesen Commit:** `C = 380` ersatzlos aus dem Fragetext
gestrichen, da die reine Verhältnisformel `T2 = T1 · (vc1/vc2)^(1/m)` sie
nicht benötigt (P3-Vorgabe: „C und m aus der Frage streichen, die
Verhältnisformel braucht sie nicht"). `loesungswert`/`toleranz` auf
`9.8`/`0.3` korrigiert (nachgerechnet: `30 · (100/140)^(1/0,3) ≈ 9,77 min`).

**Offen:** Ob `C = 380` ursprünglich mit einem *anderen* Vergleichspunkt
konsistent gemeint war (z. B. anderer vc-Wert), lässt sich ohne die
ursprüngliche Quelle der Frage nicht rekonstruieren. Fachliche Prüfung
erwünscht, falls die Konstante an anderer Stelle noch referenziert wird.

---

## P5c — `au-wk-025`: `CuSnB` durch `CuSn8` ersetzt, Blei-Aussage entfernt

**Datei:** `assets/fragen/auftragsanalyse_werkstoffkunde.json`

`CuSnB` ist keine genormte Werkstoffbezeichnung. Zwei plausible Lesarten:

1. Tippfehler für `CuSn8` (passt zu `au-wk-018`, das korrekt `CuSn8P`
   verwendet) - **so umgesetzt**, wie in P5 vorgegeben.
2. Absichtlich gemeinte verbleite Zinnbronze (Rotguss-Lagerwerkstoff, z. B.
   `CuSn7ZnPb`/Rg7 oder `CuSn5Pb5Zn5`/Rg5), worauf der ursprüngliche Satz
   „Der Zusatz B (Blei) verbessert Gleiteigenschaften und Zerspanbarkeit"
   in der `erklaerung` hindeutete - typisch für Hydraulikkolben-Lager­buchsen.

**Entscheidung für diesen Commit:** Lesart 1 umgesetzt (Konsistenz mit
`au-wk-018`, wie im Prompt vorgegeben). Der Blei-Satz wurde aus der
`erklaerung` entfernt, da `CuSn8`/`CuSn8P` bleifrei sind und der Satz sonst
sachlich falsch wäre.

**Offen:** Falls tatsächlich ein verbleiter Lagerbronze-Werkstoff (Lesart 2)
gemeint war, wäre die fachlich korrekte Bezeichnung eine andere (z. B.
`CuSn7ZnPb`) und die Blei-Begründung sollte wieder rein. Bitte von
Fachseite gegenprüfen, welche Legierung im realen Bauteil (Schaltkolben,
Pos. 16, S18) tatsächlich verbaut ist.

---

## P5d — Werkstoffbezeichnungen-Sammelprüfung: keine Fehler gefunden

Alle in P5d genannten Kürzel gegen die einschlägigen Normen geprüft:
`17Cr3`, `16MnCr5`, `20MnCr5`, `11SMn30+C` (EN 10084/10087 Einsatzstähle
bzw. Automatenstahl), `CuSn8P`, `CuSn12`, `CuZn31Si1` (EN 1982/12163
Kupferlegierungen), `42CrMo4` (EN 10083 Vergütungsstahl), `S235JR`
(EN 10025 Baustahl), `DC01` (EN 10130 Kaltband), `GJL-200` (EN 1561
Grauguss), `AlMgSi1` (Aluminiumknetlegierung, DIN-1725-Bezeichnung für
EN AW-6082), `PE-HD` (Hochdichtes Polyethylen). Alle sind gültige,
korrekt geschriebene Bezeichnungen. Keine Änderung nötig.

---

## P5e — `ft-cnc-025`: unrealistischer Kegeldurchmesser nicht geändert

**Datei:** `assets/fragen/fertigungstechnik_cnc_grundlagen.json`

Rechnerisch ist die Frage stimmig (D = d + C·L = 128 + 1 = 129 mm), aber
128 mm kleiner Kegeldurchmesser für eine "Schaltstange" (Pos. 2) ist für
ein Bauteil dieses Namens ungewöhnlich groß - Schaltstangen sind typisch
schlanke Rundstäbe im Bereich von wenigen Zentimetern, nicht 128 mm.
Naheliegende Vermutung: gemeint war `d = 28 mm` (→ `loesungswert` müsste
dann auf `29.0` mitgezogen werden), ein Tippfehler durch die verlorene
führende Ziffer wäre auch plausibel (28 → 128 als Zahlendreher/Zusatzziffer
ist allerdings ungewöhnlich; wahrscheinlicher ein einfacher Tippfehler
"1" + "28").

**Nicht geändert**, weil ohne die (in `assets/zeichnungen/S18/` fehlende,
siehe P8) Originalzeichnung nicht sicher rekonstruierbar ist, welcher Wert
tatsächlich korrekt ist - reine Vermutung wäre hier ein Raten i. S. der
Regel „Fachliche Änderungen nie raten". Bitte von Fachseite mit der
Originalzeichnung S18 gegenprüfen; danach `d`, die Fragestellung und
`loesungswert` (aktuell `129.0`, bei d=28 → `29.0`) konsistent anpassen.

---

## P6a — `au-tb-030` (vormals Duplikat von `au-ih-025`): `pruefung`-Tag entfernt statt geraten

**Datei:** `assets/fragen/auftragsanalyse_technische_berechnungen.json`

Beide Duplikate (`au-ih-025` und `au-tb-030`) trugen `"pruefung": "S18"` mit
**unterschiedlichem** `pruefungReihenfolge` (13 bzw. 24) - beide behaupteten
also, an zwei verschiedenen Positionen derselben echten IHK-Prüfung S18
vorzukommen, mit praktisch identischem Rechenweg. Das ist für eine reale,
einmalige Prüfung unplausibel; mindestens einer der beiden `pruefung`-Tags
war vermutlich von Anfang an falsch gesetzt (evtl. beim Duplizieren
mitkopiert).

**Entscheidung für diesen Commit:** `au-ih-025` unverändert gelassen
(existierender Zustand, keine neue Behauptung). `au-tb-030` wurde durch
eine neue, andere Kapazitätsrechnung ersetzt (P6a-Vorgabe) - die
`pruefung`/`pruefungReihenfolge`-Felder wurden dabei entfernt (`null`),
weil für eine neu erstellte Frage keine Grundlage besteht, sie als Teil der
echten S18-Prüfung auszugeben.

**Offen:** Ob `au-ih-025` tatsächlich Position 13 der echten S18-Prüfung
ist, oder ob der Tag ebenfalls fehlerhaft war, lässt sich ohne die
Originalprüfung nicht verifizieren. Bei Gelegenheit (z. B. im Rahmen von
P8, wo die S18-Prüfungssimulation ohnehin geprüft wird) gegen die reale
Prüfung abgleichen.

---

## P6d — `multi` mit 4-von-5 richtig: nur 3 von 37 bearbeitet

3 Beispiele exemplarisch entschärft (Strategie: einen zusätzlichen,
plausiblen aber nachweisbar falschen Distraktor ergänzt, statt eine der
bestehenden richtigen Aussagen fachlich zu verfälschen - das Risiko einer
falschen Umformulierung schien höher als der Nutzen):

- `au-et-013` (Reihenschaltung Widerstände): + "Der Gesamtwiderstand hängt
  von der Reihenfolge der Widerstände ab" (falsch, Addition ist kommutativ)
- `wi-kv-004` (§ 437 BGB Käuferrechte): + "Sofortiger Rücktritt bei jedem
  noch so kleinen Mangel ohne Fristsetzung" (falsch, Vorrang der
  Nacherfüllung nach § 323 BGB)
- `wi-vs-004` (DSGVO-Rechte): + "Recht auf Datenminimierung durch den
  Verantwortlichen" (falsch als Betroffenenrecht - das ist ein Grundsatz
  für den Verantwortlichen, Art. 5 DSGVO, kein Art.-12-22-Recht)

Alle drei jetzt 4-von-6 statt 4-von-5 (Validator-Warnung verschwunden).

**Nicht bearbeitet** (P6d-Vorgabe „lieber weniger, dafür gute
Distraktoren"), verbleibende 34 Kandidaten aus dem Validator-Report:
`au-fl-009`, `au-fl-013`, `au-fa-004`, `au-fa-011`, `au-hy-013`,
`au-ih-004`, `au-ih-011`, `au-tz-004`, `au-tz-014`, `au-tp-014`,
`ft-cnc-013`, `ft-ap-006`, `ft-ap-013`, `ft-fv-004`, `ft-fv-011`,
`ft-qs-006`, `ft-sd-011`, `ft-ww-007`, `ft-ww-013`, `ft-ws-006`,
`ft-wf-013`, `wiso-av-003`, `wiso-av-010`, `wiso-ba-003`, `wiso-ba-014`,
`wi-bo-011`, `wi-ent-007`, `wi-ent-015`, `wi-kv-013`, `wi-mp-012`,
`wi-sv-005`, `wi-tr-011`, `wi-vs-010`, `wi-vs-014`, `wi-wk-006`.
Für jede dieser Fragen müsste geprüft werden, ob sich - wie in den drei
Beispielen oben - ein zusätzlicher, fachlich einwandfreier Distraktor
ergänzen lässt, ohne die Aufgabe zu verfälschen. `dart run
tool/validate_fragen.dart` findet diese Liste jederzeit wieder
(`multi: 4 von 5 Optionen richtig`).

---

## P7a — Tippfehlertoleranz (Levenshtein) bewusst NICHT aktiviert

`AntwortMatcher.passtMitTippfehlertoleranz()` ist implementiert, aber
nirgends im Bewertungspfad verdrahtet - genau wie in P7a gefordert, wurde
das vorher gegen den gesamten Pool getestet (alle `akzeptierteKurzantworten`,
`luecken` und Fachgespräch-`schluesselwoerter`, >6 Zeichen normalisiert,
667 einzigartige Einträge, alle Paare mit Distanz <= 1 geprüft).

Ergebnis: 16 Kollisionen gefunden, die meisten harmlos (Wortzusammen-
setzungsvarianten wie "Datum System"/"Datumsystem" oder Synonyme wie
"Differenzialregler"/"Differentialregler" - für die wäre Toleranz sogar
nützlich). **Eine Kollision ist aber ein echtes Risiko:**
„24 Tage" ↔ „14 Tage" liegen bei Distanz 1 (eine Ziffer). Zwei
verschiedene Fragen mit unterschiedlichen Zahlenantworten würden bei
aktivierter Tippfehlertoleranz gegenseitig als „nur vertippt" durchgehen -
falsche Zahl würde als richtig gewertet. Damit bestätigt sich exakt die
im Prompt genannte Sorge (analog „Festlager"/„Loslager").

**Empfehlung:** Tippfehlertoleranz nicht global aktivieren. Falls
gewünscht, müsste sie pro Feld/Fragetyp opt-in sein und rein numerische
Werte (Ziffernfolgen) grundsätzlich ausschließen, da dort jede
Abweichung inhaltlich relevant ist, nie ein „Tippfehler".

---

## P10a — Package-Name: bewusst zurückgestellt (Nutzerentscheidung)

`android/app/build.gradle` (`namespace`/`applicationId`), der Kotlin-Package-
Pfad, `ios/Runner.xcodeproj` (`PRODUCT_BUNDLE_IDENTIFIER`) und `pubspec.yaml`
(`name:`) sind **weiterhin** `joshai.meine_app` / `meine_app`. Auf Nachfrage
hat der Nutzer entschieden, nur das App-Label (P10b) jetzt zu ändern und die
Package-Name-Entscheidung (Reverse-Domain, z. B. `de.joshai.ap2trainer`) zu
vertagen.

**Wichtig, unverändert gültig:** Der Package-Name ist nach dem ersten
Play-Store-Upload unwiderruflich. Vor jeder Veröffentlichung muss diese
Entscheidung nachgeholt werden - am saubersten mit `rename` oder
`change_app_package_name`, danach `flutter clean` und Vollbuild.

---

## P9 — automatischer wöchentlicher Export nicht umgesetzt

P9 markiert diesen Punkt selbst als "Optional, aber sinnvoll". Aus
Zeitgründen zurückgestellt: automatischer Export in den
App-Dokumentenordner einmal pro Woche, Rotation der letzten 4 Dateien.
Die Grundlage (`BackupStore.erstellen()`/`alsDateiSchreiben()`) ist
vorhanden - fehlt nur die Scheduling-Logik (z. B. beim App-Start prüfen,
ob der letzte Auto-Export > 7 Tage her ist, Zeitstempel in
`SettingsStore` ablegen) und das Aufräumen alter Dateien.

---
