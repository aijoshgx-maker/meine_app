# Lernpaket-Format

Ein **Lernpaket** ist eine Datei, die einen kompletten Kurs beschreibt:
Bereiche, Fragen und optionale Zusatzmodi. Die App liest zwei Formate:

| Format | Wann | Bilder |
|---|---|---|
| **`.json`** | Der Normalfall. Alles in einer Datei. | nein |
| **`.zip`** | Wenn Bilder oder viele getrennte Fragendateien dabei sind. | ja |

Der Import prüft die Datei vollständig, **bevor** etwas installiert wird.
Ein kaputtes Paket hinterlässt also keinen halbfertigen Kurs.

> Für das Format einer einzelnen Frage siehe [FRAGENFORMAT.md](FRAGENFORMAT.md).
> Dort steht auch, wie sich einzelne Validator-Warnungen per `bewusstSo`
> gezielt abschalten lassen — das Feld übersteht Import und Export.
> Dieses Dokument beschreibt nur die Hülle drumherum.

---

## 1. Das JSON-Format

Ein Objekt mit fünf Pflichtfeldern: `schemaVersion`, `id`, `titel`,
`bereiche`, `fragen`.

```json
{
  "schemaVersion": 1,
  "id": "spanisch-a1",
  "titel": "Spanisch A1",
  "kurzbeschreibung": "Grundwortschatz und Basisgrammatik.",
  "sprache": "es",
  "version": "1.0.0",
  "autor": "Max Mustermann",

  "bereiche": [
    { "id": "vokabeln",  "titel": "Vokabeln",  "farbe": "#3F6FBF", "gewicht": 0.6, "icon": "language" },
    { "id": "grammatik", "titel": "Grammatik", "farbe": "#C4622D", "gewicht": 0.4, "icon": "book" }
  ],

  "begriffe": {
    "lernstand": "Sprachstand",
    "testlauf": "Übungstest",
    "dialog": "Gesprächsübung"
  },

  "features": {
    "fachgespraech": false,
    "pruefungssimulation": false,
    "zeichnungen": false
  },

  "fragen": [
    {
      "id": "vok-001",
      "bereich": "vokabeln",
      "kategorie": "Begrüßung",
      "typ": "kurzantwort",
      "frage": "Wie sagt man 'Guten Morgen' auf Spanisch?",
      "optionen": [], "richtigeIndizes": [], "reihenfolge": [],
      "paare": [], "luecken": [],
      "akzeptierteKurzantworten": ["buenos días", "buenos dias"],
      "erklaerung": "'Buenos días' wird bis etwa 12 Uhr verwendet.",
      "schwierigkeit": 1
    }
  ]
}
```

### Pflichtfelder

| Feld | Typ | Regeln |
|---|---|---|
| `schemaVersion` | Zahl | Aktuell `1`. Höhere Werte werden abgelehnt. |
| `id` | Text | Nur `a–z A–Z 0–9 - _`. Dient als Schlüssel für den Lernfortschritt und als Ordnername — deshalb keine Pfadtrenner. |
| `titel` | Text | Nicht leer. |
| `bereiche` | Liste | Mindestens einer, `id` je eindeutig. |
| `fragen` | Liste | Mindestens eine lesbare Frage. |

### Optionale Felder

| Feld | Bedeutung | Standard |
|---|---|---|
| `kurzbeschreibung` | Text unter dem Titel in der Kursliste | leer |
| `sprache` | ISO-Code, rein informativ | `"de"` |
| `version`, `autor` | Werden in der Kursliste angezeigt | – |
| `begriffe` | Überschreibt die drei Beschriftungen | siehe unten |
| `features` | Schaltet optionale Modi frei | alles `false` |
| `pruefungen` | Definiert Testläufe | leer |
| `fachgespraech` | Dialog-Szenarien (inline) | leer |

---

## 2. Bereiche

Ein Bereich gruppiert Kategorien und bildet einen Balken im Lernstand.

```json
{ "id": "grammatik", "titel": "Grammatik", "farbe": "#C4622D", "gewicht": 0.4, "icon": "book" }
```

- **`gewicht`** steuert, wie stark der Bereich in den Gesamt-Lernstand eingeht.
  Die Werte werden **automatisch auf 1 normalisiert** — `3` und `1` ergeben
  dasselbe wie `0.75` und `0.25`. Lässt du `gewicht` überall weg, zählen alle
  Bereiche gleich viel.
- **`farbe`** als Hex mit oder ohne `#`, 6- oder 8-stellig.
- **`icon`** aus dieser festen Liste (alles andere wird zum Standard-Ordnersymbol):

  `engineering` · `manufacturing` · `business` · `school` · `language` ·
  `science` · `calculate` · `code` · `health` · `law` · `nature` ·
  `history` · `geography` · `art` · `music` · `book`

> **Wichtig:** Das `bereich`-Feld jeder Frage muss auf eine dieser `id`s
> zeigen. Passt es nicht, erscheint die Frage zwar im freien Üben, aber
> nicht in der Themenauswahl und nicht im Lernstand. Der Import warnt davor.

---

## 3. Begriffe

Die App ist themenneutral formuliert. Wenn dein Kurs eigene Worte braucht:

```json
"begriffe": {
  "lernstand": "Prüfungsreife",
  "testlauf":  "Prüfungssimulation",
  "dialog":    "Fachgespräch"
}
```

| Schlüssel | Wo sichtbar | Standard |
|---|---|---|
| `lernstand` | Überschrift der gewichteten Fortschrittskarte | `Lernstand` |
| `testlauf` | Knopf und Titel des Testlauf-Modus | `Testlauf` |
| `dialog` | Knopf und Titel des Freitext-Dialogs | `Dialog` |

---

## 4. Features

Ein Modus erscheint nur, wenn er **freigeschaltet ist und Inhalt hat**.
Ist ein Feature aktiv, aber leer, warnt der Import und blendet den Modus aus.

```json
"features": { "fachgespraech": true, "pruefungssimulation": true, "zeichnungen": true }
```

### Testläufe (`pruefungssimulation`)

Ein Testlauf ist eine Fragenmenge auf Zeit, ohne Wiederholungsplanung.
Die Zuordnung läuft über `pruefung` an der Frage:

```json
"pruefungen": [
  {
    "code": "test-1",
    "titel": "Übungstest 1",
    "zeitlimitMinuten": 45,
    "beschreibung": "Alle Themen aus Kapitel 1–3.",
    "zeichnungen": [
      { "pfad": "bilder/uebersicht.png", "label": "Übersichtsplan" }
    ],
    "diagrammKeys": [],
    "stueckliste": { "1": "Bauteil A" },
    "aufgabenAnzahl": 40
  }
]
```

An der Frage dann:

```json
"pruefung": "test-1",
"pruefungReihenfolge": 1
```

- `zeichnungen` sind über einen Knopf während des Testlaufs einsehbar.
  Fehlt eine Bilddatei, zeigt die App einen Platzhalter mit der `stueckliste`
  als Textliste.
- `aufgabenAnzahl` ist **optional** und nennt die Sollzahl: Wie viele
  Aufgaben dieser Testlauf haben soll. Werden es weniger, meldet die Auswahl
  „unvollständiger Datensatz". Ohne die Angabe gibt es keinen Maßstab, und
  die Karte nennt schlicht die vorhandene Anzahl — setze sie also nur, wenn
  du die Sollzahl wirklich kennst.
- `stueckliste` ordnet Positionsnummern Bezeichnungen zu — nützlich, wenn
  Fragen sich auf „Pos. X" einer Abbildung beziehen.
- `diagrammKeys` verweisen auf fest eingebaute Zeichnungen und sind für
  eigene Pakete normalerweise leer.

### Dialog (`fachgespraech`)

Freitext-Antworten, die gegen Schlüsselwörter geprüft werden:

```json
"fachgespraech": [
  {
    "id": "dlg-001",
    "titel": "Im Restaurant",
    "kontext": "Du bestellst in einem Café in Madrid.",
    "fertigungsauftrag": "Bestelle einen Kaffee und frage nach der Rechnung.",
    "kategorien": ["Alltag", "Höflichkeitsformen"],
    "fragen": [
      {
        "id": "dlg-001-f1",
        "pruefer": "¿Qué desea tomar?",
        "musterloesung": "Un café con leche, por favor.",
        "schluesselwoerter": ["café", "por favor"],
        "erklaerung": "'Por favor' gehört in jede Bestellung.",
        "schwierigkeit": 1
      }
    ]
  }
]
```

Eine Antwort gilt als getroffen, wenn die genannten `schluesselwoerter`
vorkommen. Umlaute, ß, Bindestriche und Dezimaltrenner werden dabei
normalisiert.

---

## 5. Das ZIP-Format

```
spanisch-a1.zip
├─ kurs.json            ← Pflicht, im Wurzelverzeichnis
├─ fragen/
│   ├─ vokabeln.json    ← je eine JSON-Liste von Fragen
│   └─ grammatik.json
└─ bilder/
    └─ konjugation.png
```

In der `kurs.json` stehen dann statt `fragen` die Dateinamen:

```json
"fragenDateien": ["fragen/vokabeln.json", "fragen/grammatik.json"]
```

Beides lässt sich mischen: `fragen` (inline) und `fragenDateien` werden
zusammengeführt.

**Gut zu wissen:**
- Ein umschließender Ordner (`mein-paket/kurs.json`) wird automatisch
  entpackt — du kannst also einfach den Ordner zippen.
- Alle Nicht-JSON-Dateien gelten als Bilder und werden mitinstalliert.
  `bildAsset` an einer Frage und `pfad` einer Zeichnung beziehen sich auf
  den Pfad **innerhalb** des Archivs.
- Eine in `fragenDateien` genannte, aber fehlende Datei blockiert den Import
  nicht — sie wird als Hinweis gemeldet.

---

## 6. Was der Import verzeiht — und was nicht

**Abbruch mit Meldung:**
- Kein gültiges JSON, oder kein JSON-Objekt an der Wurzel
- `schemaVersion` fehlt, ist keine Zahl oder ist zu neu
- `id` fehlt, ist leer oder enthält unerlaubte Zeichen
- `titel` fehlt oder ist leer
- `bereiche` fehlt, ist leer, oder eine `id` kommt doppelt vor
- `fragen` fehlt, oder **keine einzige** Frage ist lesbar
- ZIP ohne `kurs.json`, oder beschädigtes Archiv

**Hinweis, aber Import läuft weiter:**
- Einzelne unvollständige oder unlesbare Fragen → werden übersprungen
- Unbekannter `typ` → Frage wird übersprungen
- Doppelte Frage-`id` → nur die erste zählt
- Frage zeigt auf einen unbekannten Bereich → bleibt drin, wird gemeldet
- Feature aktiv, aber ohne Inhalt → Modus bleibt ausgeblendet
- In `fragenDateien` genannte Datei fehlt im Archiv

Alle Hinweise siehst du **vor** dem Installieren in der Import-Vorschau.

---

## 7. Lernfortschritt und Aktualisierungen

Der Lernfortschritt hängt an `kursId` + `frageId` und liegt getrennt vom
Kursinhalt. Daraus folgt:

- **Ein Paket mit derselben `id` erneut importieren** aktualisiert den Inhalt
  und **behält den Lernfortschritt**. So verteilst du Korrekturen und neue
  Fragen, ohne dass jemand von vorn anfangen muss.
- **Frage-`id`s stabil halten.** Wird eine `id` geändert, gilt die Frage als
  neu und ihr bisheriger Fortschritt verfällt.
- **Kurs entfernen** löscht den zugehörigen Fortschritt endgültig.
- Ein **Backup** (Einstellungen → Backup) sichert den Fortschritt aller
  Kurse, aber **keine Kursinhalte**. Pakete verteilst du als Paketdatei.
