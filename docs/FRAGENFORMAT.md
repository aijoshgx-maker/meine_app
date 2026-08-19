# Fragenformat

Dieses Dokument beschreibt das Datenformat für `assets/fragen/*.json`
(bzw. `assets/kurse/<kurs-id>/fragen/*.json` bei externen Kursen, siehe
P11). Es gibt zwei Varianten:

- **Vollformat**: alle Felder immer vorhanden (leere Felder als `[]`/`null`).
  So liegen die mitgelieferten Fragendateien vor. `Frage.fromJson()` in
  `lib/models/frage.dart` erwartet dieses Format nicht zwingend vollständig
  (fehlende Listen werden bereits als `[]` interpretiert), verlangt aber
  die als **Pflichtfeld** markierten Werte.
- **Minimalformat**: nur die für den jeweiligen Fragetyp nötigen Felder.
  Gedacht für handgeschriebene Fragensätze (siehe P11c). `dart run
  tool/normalize_fragen.dart <eingabe.json> <ausgabe.json>` expandiert
  Minimalformat auf Vollformat.

Nach jeder Änderung: `dart run tool/validate_fragen.dart` laufen lassen.

## Felder, die es immer gibt

| Feld | Pflicht | Bedeutung |
|---|---|---|
| `id` | ✅ | `<bereich-kürzel>-<kategorie-kürzel>-<laufnummer>`, z. B. `au-tz-001` |
| `bereich` | ✅ | Themenbereich, z. B. `auftragsanalyse` |
| `kategorie` | ✅ | Unterkategorie/Anzeigename, z. B. `Technisches Zeichnen` |
| `typ` | ✅ | einer von `single`, `multi`, `wahrfalsch`, `rechnung`, `kurzantwort`, `lueckentext`, `zuordnung`, `reihenfolge` |
| `frage` | ✅ | Fragetext |
| `erklaerung` | ✅ | Erklärung, wird nach der Antwort gezeigt |
| `schwierigkeit` | ✅ | `1`\|`2`\|`3` |
| `selfExplanationPrompt` | optional | Zusatzfrage zur Selbsterklärung |
| `bildAsset` | optional | `diag:<key>` (siehe `technische_illustration.dart`) oder Assetpfad |
| `workedExample` | optional | Schritt-für-Schritt-Lösungsweg (v. a. bei `rechnung` empfohlen) |
| `pruefung` | optional | `S17`\|`S18`\|`S19`\|`W22`, falls aus einer echten Prüfung |
| `pruefungReihenfolge` | optional | Position innerhalb der Prüfung |

Alle übrigen, typspezifischen Felder (`optionen`, `richtigeIndizes`,
`reihenfolge`, `paare`, `luecken`, `loesungswert`, `einheit`, `toleranz`,
`akzeptierteKurzantworten`, `wahr`) dürfen im Minimalformat weggelassen
werden, wenn der Fragetyp sie nicht braucht - `normalize_fragen.dart` füllt
sie mit `[]` bzw. `null` auf.

---

## `single` - Einfachauswahl

**Pflichtfelder zusätzlich:** `optionen` (≥2 Einträge), `richtigeIndizes`
(genau 1 Index).

```json
{
  "id": "au-tz-901",
  "bereich": "auftragsanalyse",
  "kategorie": "Technisches Zeichnen",
  "typ": "single",
  "frage": "Welche Linienart wird für sichtbare Kanten verwendet?",
  "optionen": ["Volllinie breit", "Strichlinie schmal", "Strichpunktlinie schmal"],
  "richtigeIndizes": [0],
  "reihenfolge": [],
  "paare": [],
  "luecken": [],
  "loesungswert": null,
  "einheit": null,
  "toleranz": null,
  "akzeptierteKurzantworten": [],
  "wahr": null,
  "erklaerung": "Sichtbare Kanten werden mit einer breiten Volllinie (0,7 mm) gezeichnet.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": null,
  "schwierigkeit": 1
}
```

## `multi` - Mehrfachauswahl

**Pflichtfelder zusätzlich:** `optionen` (≥2 Einträge), `richtigeIndizes`
(≥2 Einträge, < `optionen.length`).

```json
{
  "id": "au-tz-902",
  "bereich": "auftragsanalyse",
  "kategorie": "Technisches Zeichnen",
  "typ": "multi",
  "frage": "Welche Angaben gehören zu einer vollständigen Maßeintragung?",
  "optionen": ["Maßzahl", "Maßlinie", "Maßhilfslinien", "Schriftfeld-Nummer"],
  "richtigeIndizes": [0, 1, 2],
  "reihenfolge": [],
  "paare": [],
  "luecken": [],
  "loesungswert": null,
  "einheit": null,
  "toleranz": null,
  "akzeptierteKurzantworten": [],
  "wahr": null,
  "erklaerung": "Maßzahl, Maßlinie und Maßhilfslinien gehören zur Maßeintragung, die Schriftfeld-Nummer nicht.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": null,
  "schwierigkeit": 2
}
```

## `wahrfalsch` - Wahr/Falsch

**Pflichtfelder zusätzlich:** `wahr` (`true`/`false`). `optionen` muss leer bleiben.

```json
{
  "id": "au-tz-903",
  "bereich": "auftragsanalyse",
  "kategorie": "Technisches Zeichnen",
  "typ": "wahrfalsch",
  "frage": "Strichpunktlinien werden für Mittellinien verwendet.",
  "optionen": [],
  "richtigeIndizes": [],
  "reihenfolge": [],
  "paare": [],
  "luecken": [],
  "loesungswert": null,
  "einheit": null,
  "toleranz": null,
  "akzeptierteKurzantworten": [],
  "wahr": true,
  "erklaerung": "Schmale Strichpunktlinien kennzeichnen Mittellinien und Symmetrieachsen.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": null,
  "schwierigkeit": 1
}
```

## `rechnung` - Zahlenwert-Eingabe

**Pflichtfelder zusätzlich:** `loesungswert`, `einheit`, `toleranz`
(alle drei nicht `null`). `optionen`/`richtigeIndizes` müssen leer bleiben.
`workedExample` ist nicht Pflicht, aber dringend empfohlen (siehe P3).

```json
{
  "id": "ft-sd-901",
  "bereich": "fertigungstechnik",
  "kategorie": "Schnittdaten",
  "typ": "rechnung",
  "frage": "Berechne die Schnittgeschwindigkeit vc bei d = 50 mm, n = 800 min⁻¹.",
  "optionen": [],
  "richtigeIndizes": [],
  "reihenfolge": [],
  "paare": [],
  "luecken": [],
  "loesungswert": 125.7,
  "einheit": "m/min",
  "toleranz": 1.0,
  "akzeptierteKurzantworten": [],
  "wahr": null,
  "erklaerung": "vc = π · d · n / 1000 = π · 50 · 800 / 1000 ≈ 125,7 m/min.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": "vc = π · d · n / 1000\nvc = π · 50 mm · 800 min⁻¹ / 1000 ≈ 125,7 m/min",
  "schwierigkeit": 2
}
```

## `kurzantwort` - freie Texteingabe

**Pflichtfelder zusätzlich:** `akzeptierteKurzantworten` (≥1 Eintrag).
Nur fachlich unterschiedliche Varianten eintragen - Groß-/Kleinschreibung,
Umlaut- und Bindestrich-Schreibweisen deckt `AntwortMatcher` automatisch ab
(siehe P7, `lib/core/matching/antwort_matcher.dart`).

```json
{
  "id": "ft-ws-901",
  "bereich": "fertigungstechnik",
  "kategorie": "Werkzeuge & Schneidstoffe",
  "typ": "kurzantwort",
  "frage": "Wie heißt der Winkel zwischen Spanfläche und einer Bezugsebene?",
  "optionen": [],
  "richtigeIndizes": [],
  "reihenfolge": [],
  "paare": [],
  "luecken": [],
  "loesungswert": null,
  "einheit": null,
  "toleranz": null,
  "akzeptierteKurzantworten": ["Spanwinkel"],
  "wahr": null,
  "erklaerung": "Der Spanwinkel beeinflusst die Spanabnahme.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": null,
  "schwierigkeit": 1
}
```

## `lueckentext` - Lückentext

**Pflichtfelder zusätzlich:** `luecken` (Liste von Listen akzeptierter
Antworten). Die Anzahl `{{n}}`-Platzhalter im Fragetext muss
`luecken.length` entsprechen, durchnummeriert ab 1 ohne Lücke.

```json
{
  "id": "au-tz-904",
  "bereich": "auftragsanalyse",
  "kategorie": "Technisches Zeichnen",
  "typ": "lueckentext",
  "frage": "Bei der {{1}} liegt das Bauteil zwischen Betrachter und Zeichenebene.",
  "optionen": [],
  "richtigeIndizes": [],
  "reihenfolge": [],
  "paare": [],
  "luecken": [["Erstwinkelprojektion", "Europäischen Projektion"]],
  "loesungswert": null,
  "einheit": null,
  "toleranz": null,
  "akzeptierteKurzantworten": [],
  "wahr": null,
  "erklaerung": "Erstwinkelprojektion = europäische Methode, Bauteil zwischen Betrachter und Ebene.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": null,
  "schwierigkeit": 2
}
```

## `zuordnung` - Zuordnung

**Pflichtfelder zusätzlich:** `paare` (≥2 Einträge, je `{"links": ..., "rechts": ...}`).

```json
{
  "id": "au-tz-905",
  "bereich": "auftragsanalyse",
  "kategorie": "Technisches Zeichnen",
  "typ": "zuordnung",
  "frage": "Ordne die Linienart ihrer Verwendung zu.",
  "optionen": [],
  "richtigeIndizes": [],
  "reihenfolge": [],
  "paare": [
    { "links": "Volllinie breit", "rechts": "Sichtbare Kanten" },
    { "links": "Strichlinie schmal", "rechts": "Verdeckte Kanten" }
  ],
  "luecken": [],
  "loesungswert": null,
  "einheit": null,
  "toleranz": null,
  "akzeptierteKurzantworten": [],
  "wahr": null,
  "erklaerung": "Linienarten nach DIN ISO 128.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": null,
  "schwierigkeit": 1
}
```

## `reihenfolge` - Sortieren

**Pflichtfelder zusätzlich:** `optionen` (die zu sortierenden Elemente),
`reihenfolge` (gültige Permutation der Options-Indizes in der richtigen
Reihenfolge). Sollte **keine** Identitätspermutation `[0,1,2,…]` sein -
sonst verrät die Anzeigereihenfolge bereits die Lösung (siehe P6c).

```json
{
  "id": "ft-zg-901",
  "bereich": "fertigungstechnik",
  "kategorie": "Zerspanung Grundlagen",
  "typ": "reihenfolge",
  "frage": "Bringe die Arbeitsschritte in die richtige Reihenfolge.",
  "optionen": ["Bohren", "Vorbohren", "Reiben"],
  "richtigeIndizes": [],
  "reihenfolge": [1, 0, 2],
  "paare": [],
  "luecken": [],
  "loesungswert": null,
  "einheit": null,
  "toleranz": null,
  "akzeptierteKurzantworten": [],
  "wahr": null,
  "erklaerung": "Reihenfolge: Vorbohren -> Bohren -> Reiben.",
  "selfExplanationPrompt": null,
  "bildAsset": null,
  "workedExample": null,
  "schwierigkeit": 2
}
```

---

## Minimalformat-Beispiel

Das Minimalformat lässt alle nicht benötigten Felder weg. Beispiel für
eine `single`-Frage:

```json
{
  "id": "au-tz-901",
  "bereich": "auftragsanalyse",
  "kategorie": "Technisches Zeichnen",
  "typ": "single",
  "frage": "Welche Linienart wird für sichtbare Kanten verwendet?",
  "optionen": ["Volllinie breit", "Strichlinie schmal", "Strichpunktlinie schmal"],
  "richtigeIndizes": [0],
  "erklaerung": "Sichtbare Kanten werden mit einer breiten Volllinie (0,7 mm) gezeichnet.",
  "schwierigkeit": 1
}
```

`dart run tool/normalize_fragen.dart eingabe.json ausgabe.json` expandiert
das auf das Vollformat oben (füllt `reihenfolge`, `paare`, `luecken`,
`loesungswert`, `einheit`, `toleranz`, `akzeptierteKurzantworten`, `wahr`,
`selfExplanationPrompt`, `bildAsset`, `workedExample`, `pruefung`,
`pruefungReihenfolge` mit `[]`/`null` auf). Anschließend
`dart run tool/validate_fragen.dart` laufen lassen.

## Bewusst abgeschaltete Prüfungen (`bewusstSo`)

`tool/validate_fragen.dart` meldet unter anderem, wenn bei einer
`multi`-Frage fast alle Optionen richtig sind — dann lässt sie sich leicht
erraten.

Das ist eine Heuristik, und sie trifft eine ganze Klasse **legitimer** Fragen
mit. Beispiel:

> Welche der folgenden Toleranzarten gehören zu den Lauftoleranzen nach
> DIN ISO 1101?
> Rundlauf ✓ · Planlauf ✓ · Gesamtrundlauf ✓ · **Neigung ✗** · Gesamtplanlauf ✓

Es *gibt* genau vier Lauftoleranzen. Hier ist die Abgrenzung selbst der
Lernstoff — eine richtige Option umzuformulieren, nur damit die Warnung
verstummt, würde die Frage fachlich schlechter machen.

Für solche Fälle:

```json
"bewusstSo": ["multi-anteil"]
```

| Prüfungs-ID | Schaltet ab |
|---|---|
| `multi-anteil` | „multi: n von m Optionen richtig (zu leicht erratbar)" |

**Zwei Sicherungen verhindern, dass sich der Marker verselbstständigt:**

- Eine **unbekannte Prüfungs-ID** ist ein *Fehler*, kein stiller No-op — ein
  Tippfehler würde sonst nichts abschalten und niemand wüsste warum.
- Ein Marker, der **nichts mehr abschaltet**, wird gemeldet. Wird eine Frage
  später umgebaut, verdeckt der alte Marker sonst irgendwann ein echtes
  Problem.

Mehrere Fragen auf einmal markieren:

```bash
python tool/bewusst_markieren.py multi-anteil au-fl-013 au-fl-009
python tool/bewusst_markieren.py --entfernen multi-anteil au-fl-013
```

Das Werkzeug fügt genau eine Zeile je Frage ein und lässt die übrige
Formatierung in Ruhe.

## Kurzfassung der Erklärung (`kurzerklaerung`)

Nach dem Aufdecken zeigt die App zuerst die **Lösung**, dann einen knappen
Satz zum Warum. Wer mehr will, klappt „Ausführlich" auf — dort stehen die
vollständige Erklärung, der Lösungsweg und ein etwaiges Bild.

Die Kurzfassung wird **automatisch abgeleitet**: Es werden so viele ganze
Sätze genommen, wie in rund 180 Zeichen passen. Für die 681 Bestandsfragen
funktioniert das ohne Zutun.

Wenn die Ableitung im Einzelfall unglücklich trennt oder du es genauer
willst:

```json
"kurzerklaerung": "Neigung ist eine Richtungstoleranz, keine Lauftoleranz."
```

Dann bildet dieser Text die Kurzfassung, und die vollständige `erklaerung`
wandert in den Aufklapper.

**Faustregel:** ein Satz, der die Frage beantwortet — nicht der Anfang einer
Herleitung.

## Bilder (`bildAsset`)

Zwei Formen:

| Wert | Bedeutung |
|---|---|
| `"diag:schnittdaten"` | eines der 9 fest eingebauten Diagramme |
| `"bilder/skizze.png"` | Datei aus einem ZIP-Paket |

Verfügbare Diagramme: `grafcet_basis` · `hydraulik_kolben` ·
`kraeftedreieck` · `passungsdiagramm` · `pneumatik_52_ventil` ·
`schnittdaten` · `toleranzfeld` · `werkzeugwinkel` · `zahnrad_geometrie`

Das Bild erscheint bei der Frage **und** im Aufklapper der Aufdeckung.

> **Ein Diagramm soll die Antwort stützen, nicht die Seite füllen.** Eine
> Hydraulik-Frage nach Ölviskosität neben einem Kolbenschnitt ist
> bestenfalls Dekoration, schlimmstenfalls irreführend. Im Zweifel weglassen.

Kandidaten finden und zuweisen:

```bash
python tool/bild_kandidaten.py                       # schreibt REVIEW_BILDER.md
python tool/bild_zuweisen.py schnittdaten ft-zg-004
python tool/bild_zuweisen.py --entfernen ft-zg-004
```

Ein unbekannter Diagrammname wird abgewiesen — die App würde ihn sonst
kommentarlos ignorieren.
