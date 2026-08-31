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

### Freie Antwort auf der höchsten Stufe (`freieAntwort`)

Wer eine Frage viermal in Folge **sicher und richtig** beantwortet hat,
bekommt sie ohne ihre Optionen gestellt — aus Wiedererkennen wird Abrufen
(siehe `lib/core/quiz/frage_haerte.dart`). Was dann als richtig gilt, steht
in `freieAntwort`:

```json
"freieAntwort": ["Reed-Kontakt", "Reedschalter"]
```

Der **Wortlaut der richtigen Option gilt immer mit** und muss hier nicht
wiederholt werden. `freieAntwort` trägt nur die kürzeren und die
gleichwertigen Formulierungen nach — bei „Rockwell-Härteprüfung (HRC/HRB)"
also `["Rockwell", "Rockwell-Härteprüfung", "HRC"]`.

**Nur bei `typ: "single"`.** An jedem anderen Typ wäre das Feld wirkungslos;
der Validator meldet es als Fehler.

**Wann eine Frage das Feld bekommt:** Sie fragt nach genau einem Begriff,
Kennwert oder Verfahren, und der ist ohne Blick auf die Optionen benennbar.

**Wann nicht:**

- Ja/Nein-Antworten („Ja, für 9 Monate") — ohne die Auswahl unlösbar
- ganze Sätze („Er fällt exponentiell.")
- Antworten, die nur eine von mehreren angebotenen Formulierungen sind
- Antworten, die einen Schaltplan voraussetzen („-RM1")

Ohne das Feld bleibt die Frage auf der mittleren Stufe stehen — das ist der
Normalfall und kostet nichts.

Gepflegt wird die Liste in `tool/freie_antwort_setzen.py`; ein erneuter Lauf
schreibt sie in die Fragendateien. Abgesichert durch
`test/frage_haerte_bestand_test.dart`: Jede hinterlegte Antwort muss von der
Bewertung als richtig erkannt werden, und **kein Ablenker derselben Frage
darf durchgehen** — sonst wäre die harte Fassung leichter als die leichte.

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

## Mehrstufige Aufgaben (`komplex`)

Eine Aufgabe ist nicht schwerer, weil die Zahlen größer sind, sondern weil
zwischen Angabe und Ergebnis Schritte liegen, die sie nicht nennt. Bei der
Hauptzeit am Drehteil steht die Vorschubgeschwindigkeit nirgends — sie
entsteht erst aus Drehzahl und Vorschub, und die Drehzahl erst aus
Schnittgeschwindigkeit und Durchmesser. Genau diese Kette ist der Lernstoff.

```json
"komplex": true
```

**Wirkung:** Solche Aufgaben laufen nicht im normalen Tagespensum mit,
sondern über ein eigenes Fach — **genau eine pro Tag**. Zwischen neunzehn
Karteikarten würde eine Aufgabe, die zehn Minuten Rechnen kostet, entweder
übersprungen oder als Störung empfunden. Der Platz zählt gegen das
Tagesbudget, kommt also nicht obendrauf.

Ausgewählt wird die fällige mit dem ältesten Termin; ist keine fällig, eine
noch ungesehene. Wurde heute schon eine bearbeitet, kommt keine zweite, und
der Platz fällt an die übrigen Karten zurück.

**Voraussetzungen** (der Validator besteht darauf):

- `typ: "rechnung"` — an einem anderen Typ wäre die Markierung wirkungslos
- ein `varianten`-Block — ohne ihn wäre die Aufgabe des Tages beim zweiten
  Mal auswendig gewusst statt gerechnet
- ein `workedExample` — wer an Schritt drei von fünf scheitert, braucht den
  ganzen Weg, nicht nur das Ergebnis

Dazu prüft `test/komplexaufgaben_test.dart`, dass mindestens **zwei
Zwischenschritte** hinterlegt sind. Weniger heißt: eine Formel einsetzen, und
das kann der übrige Bestand schon.

**Gepflegt wird nicht die JSON-Datei**, sondern
`tool/komplex_daten.py`; `tool/komplex_setzen.py` erzeugt daraus
`assets/fragen/komplexaufgaben.json`. Grund: Fragetext, Lösungswert,
Erklärung und Lösungsweg entstehen aus denselben Formeln, aus denen später
gewürfelt wird — getrennt gepflegt liefen sie früher oder später
auseinander.

## Variierende Aufgaben (`varianten`)

Wer eine Rechenaufgabe zum dritten Mal sieht, erinnert sich an „5,06" statt
an den Rechenweg. Die Karte gilt dann als sicher, das Verfahren sitzt aber
nicht. Mit `varianten` erscheint die Aufgabe bei jedem Durchgang mit anderen
Zahlen.

**Das Feld ist optional und die Ausnahme.** Fragen nach einer Frist, einem
Paragrafen, einer Werkstoffbezeichnung bekommen es nie — dort *ist* der
konkrete Wert der Lernstoff.

```json
{
  "id": "au-at-003",
  "typ": "rechnung",
  "frage": "Ein Motor liefert P₁ = 5,5 kW bei η = 0,92. Berechnen Sie P₂.",
  "loesungswert": 5.06,
  "einheit": "kW",
  "toleranz": 0.05,
  "varianten": {
    "variablen": {
      "P1": { "von": 1.5, "bis": 22.0, "schritt": 0.1 },
      "eta": { "werte": [0.8, 0.85, 0.9, 0.92, 0.95] }
    },
    "original": { "P1": 5.5, "eta": 0.92 },
    "frage": "Ein Motor liefert P₁ = {P1} kW bei η = {eta}. Berechnen Sie P₂.",
    "loesung": "eta * P1",
    "rundung": 2,
    "toleranzProzent": 1.0,
    "workedExample": "P₂ = η · P₁ = {eta} · {P1} kW = {loesung} kW"
  }
}
```

### Woher die Werte kommen

**`variablen`** würfelt: entweder aus einer festen Liste (`werte`) oder aus
einem Bereich (`von`/`bis`/`schritt`). Listen sind für alles, was nicht
beliebig sein darf — Wirkungsgrade, Zähnezahlen, Normspannungen.

**`zeilen`** + **`spalten`** ziehen eine ganze Tabellenzeile. Nötig überall
dort, wo Werte zusammengehören: Steigung und Flankendurchmesser eines
Gewindes, Nennmaß und Grundabmaß einer Passung, Nennleistung und Nenndrehzahl
eines Motors.

Beides lässt sich **kombinieren** — Gewinde aus der Tabelle, Drehzahl
gewürfelt.

### `original` ist Pflicht

Es hält fest, mit welchen Werten die Frage ursprünglich dastand. Zwei Dinge
hängen daran:

- Der **Testlauf** zeigt damit den authentischen Prüfungsbogen. Gewürfelt
  wird nur in freier Übung und Wiederholung.
- Der **Validator** rechnet damit nach: Setzt man `original` ein, muss wieder
  genau der gespeicherte Fragetext und genau der gespeicherte `loesungswert`
  herauskommen. Eine falsch abgeschriebene Formel fällt so sofort auf.

### Formeln

`loesung` und die Einträge unter `zwischen` sind Rechenausdrücke:
`+ - * / ^`, Klammern, die Konstante `pi` und die Funktionen
`sqrt abs round floor ceil min max sin cos tan ln log`.

**Winkelfunktionen rechnen in Grad**, nicht im Bogenmaß — technische
Aufgaben geben Winkel so an.

`zwischen` wird der Reihe nach ausgewertet; ein späterer Schritt darf auf
einen früheren zugreifen. Zwei Aufgaben:

1. **Zwischenergebnisse für den Lösungsweg.** Ohne sie wäre der Weg ärmer
   als vorher.
2. **Abhängige Größen erzeugen**, statt sie unabhängig zu würfeln. Beispiel:
   Die Endtemperatur entsteht als `T1 + dT`, damit sie nie unter der
   Anfangstemperatur liegt. Nach demselben Muster: die verbesserte
   Bearbeitungszeit, der Istwert eines Regelkreises, der Verkaufspreis über
   den variablen Kosten.

### Vorlagen

`frage`, `erklaerung`, `workedExample`, `akzeptierteKurzantworten` und
`luecken` dürfen `{name}` enthalten — jede gewürfelte Variable, jede
Tabellenspalte, jedes `zwischen` und `{loesung}`. Was nicht als Vorlage
angegeben ist, bleibt aus der Frage unverändert stehen.

Zahlen werden deutsch geschrieben und ohne nachlaufende Nullen: `5,5`, `40`,
`106,67`. Wo die Null die Aussage ist — eine Lagerpassung von `0,090 mm` ist
auf ein Tausendstel angegeben — hält `stellen` sie fest:

```json
"stellen": { "dd": 3 }
```

### Toleranz

`toleranzProzent` skaliert mit dem Lösungswert. Bei gewürfelten Zahlen ist
eine feste Toleranz schief: 10 W sind bei 5314 W großzügig und bei 200 W
streng. Ohne Angabe bleibt die absolute `toleranz` der Frage gültig. Die
eigene Rundung ist immer abgedeckt — wer den angezeigten Wert eintippt, darf
daran nicht scheitern.

### Wann eine Aufgabe **nicht** variieren darf

- **Sie zeigt eine Zeichnung.** Die Zahlen stehen im Bild; im Text stünde
  sonst etwas anderes als in der Zeichnung.
- **Sie behauptet etwas über ein benanntes Bauteil.** Bei Prüfungsaufgaben
  variiert nur, was die Aufgabe als gewählte Betriebsgröße einführt — der
  Druck an einem Spannzylinder, der Volumenstrom in einem Rohr. Nie eine
  Abmessung, Nennleistung oder Zähnezahl der genannten Baugruppe.
- **Der Wert ist Rechtsstand.** Beitragssätze, Fristen, Staffeln aus einem
  Gesetz. Variabel ist das Entgelt, nie der Satz.
- **Die Zahlen kämen aus einer Normtabelle, die man nachbilden müsste.**
  Eine falsche Passungstabelle ist schlimmer als eine Aufgabe, die sich
  nicht ändert.

### Werkzeug

Die Beschreibungen stehen nach Fachgebiet getrennt in `tool/varianten_*.py`
und werden mit

```
python tool/varianten_setzen.py
```

in die Fragendateien eingetragen. Das Skript ist wiederholt aufrufbar: Ein
vorhandener `varianten`-Block wird ersetzt. Danach `dart run
tool/validate_fragen.dart` — er prüft jede Formel, setzt `original` ein und
zieht 200 Varianten je Aufgabe gegen unlösbare Ergebnisse.

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

## Tipps zu Begriffen und Formelzeichen (`_glossar.json`)

Wer an einer Aufgabe hängt, weil ihm `ω` nichts sagt, hat keine Wissenslücke
im Thema — er kann die Frage nur nicht lesen. Dafür gibt es den Tipp-Knopf
unter dem Fragetext.

Das Glossar gehört zum **Kurs**, nicht zur App — ein Sprachkurs hätte sonst
die Formelzeichen der Zerspanung. In `kurs.json`:

```json
"glossarDatei": "_glossar.json"
```

Aufbau der Datei — ein Array:

```json
[
  {
    "begriff": "ω (Winkelgeschwindigkeit)",
    "alias": ["ω", "omega", "Winkelgeschwindigkeit"],
    "kurz": "Wie schnell sich etwas dreht — im Bogenmaß, Einheit rad/s.",
    "mehr": "ω = 2 · π · n, wobei n in 1/s einzusetzen ist."
  }
]
```

| Feld | Pflicht | Bedeutung |
|---|---|---|
| `begriff` | ja | Anzeigename, dient zugleich als Kennung |
| `kurz` | ja | ein Satz, höchstens rund 160 Zeichen |
| `alias` | nein | weitere Schreibweisen für die Suche im Fragetext |
| `mehr` | nein | Vertiefung hinter „Mehr": Formel, Einheit, Abgrenzung |

`alias` ist wichtiger als es aussieht: Angezeigt wird
„ω (Winkelgeschwindigkeit)", im Fragetext steht aber mal `ω`, mal
„Winkelgeschwindigkeit". Ohne Alias findet die Suche nichts.

**Wie erkannt wird:** Symbole wie `ω` oder `Ø` werden überall gefunden, auch
direkt an Zahlen („Ø32"). Wörter dagegen nur an Wortgrenzen — sonst würde
„Kraft" auch in „Kraftstoffpumpe" anschlagen und die Tippliste unbrauchbar
machen.

### Formeln (`formeln`)

Ein Glossareintrag kann seine Formeln in einem eigenen Feld führen. Die
Tippfunktion sammelt sie über alle gefundenen Begriffe, entfernt Doppelungen
und stellt sie oben ins Blatt — wer rechnet, braucht sie zusammen und muss
sie nicht aus drei aufgeklappten Absätzen zusammensuchen.

```json
"formeln": ["vc = π · d · n / 1000"]
```

**In Rohform, nicht umgestellt.** Bei einer Frage nach der Drehzahl steht
dort `vc = π · d · n / 1000` und *nicht* `n = vc · 1000 / (π · d)`. Das
Umstellen ist der Lernstoff; wer es abnimmt, nimmt die Aufgabe weg. Das Blatt
schreibt das auch dazu.

Jeder Eintrag muss ein `=` enthalten — sonst ist es keine Formel, sondern ein
Satz, und der gehört nach `mehr`. Der Validator besteht darauf.

Gepflegt wird die Liste in `tool/glossar_formeln_setzen.py`; ein erneuter Lauf
schreibt sie ins Glossar.

### Wenn der Tipp die Antwort verrät

Bei „Welche Einheit hat die Winkelgeschwindigkeit?" wäre der Eintrag die
Lösung. An der Frage:

```json
"tippsAus": ["ω (Winkelgeschwindigkeit)"]
```

Der Wert ist der `begriff`, nicht das Alias.

### Was ein guter Eintrag leistet

- **Er erklärt, was gemeint ist — nicht, wie man rechnet.** Die Herleitung
  gehört in die `erklaerung` der Frage.
- **Er grenzt gegen Nachbarbegriffe ab.** „Nicht mit der Drehzahl
  verwechseln" hilft mehr als eine Definition.
- **Er nennt die Einheit.** Die Hälfte der Verwirrung kommt daher.

Im mitgelieferten AP2-Kurs greift das Glossar bei **80 von 681 Fragen**
(rund 12 %), höchstens 3 Begriffe je Frage. Deutlich mehr wäre Lärm — der
Knopf würde dann überall stehen und niemand drückt ihn noch.
