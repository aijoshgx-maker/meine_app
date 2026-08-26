# Changelog

Alle inhaltlichen und technischen Änderungen aus der Überarbeitung nach
`CLAUDE_CODE_PROMPTS.md` (P0–P12). Format lose an
[Keep a Changelog](https://keepachangelog.com) angelehnt.

## [Unveröffentlicht]

### Hinzugefügt

- **Fragen wachsen mit (Erprobung).** Eine Frage, die man dreimal sicher
  richtig beantwortet hat, ist als Auswahlfrage keine Prüfung mehr — man
  erkennt die richtige Option wieder, statt die Antwort abzurufen. Der
  Lernstand steigt, das Können nicht zwingend mit.

  Solche Fragen werden jetzt **schrittweise härter gestellt**, und die harte
  Fassung **ersetzt** die leichte:

  - **ab 2× sicher richtig:** der Tipp-Knopf unter der Frage verschwindet.
    Er erklärt Formelzeichen und Begriffe *vor* dem Antworten — genau die
    Stütze, die man irgendwann nicht mehr braucht.
  - **ab 4× sicher richtig:** die Frage selbst wird härter. Bei 31
    Auswahlfragen fallen die Optionen weg und man tippt frei; bei
    Rechenaufgaben nennt der Eingabehinweis die Einheit nicht mehr.

  Gezählt wird nur **sicher und richtig** — wer richtig rät, hat es nicht
  gekonnt. Ein Fehler nimmt **genau eine Stufe** zurück, nicht den ganzen
  Weg: Wer an der freien Antwort einmal scheitert, sieht sie wieder mit
  Auswahl, muss aber nicht von vorn anfangen. Der Testlauf bleibt unberührt
  — dort zählt der authentische Prüfungsbogen.

  **Welche Frage frei abgefragt werden kann, steht in den Daten und wird
  nicht geraten.** Von den 171 Auswahlfragen haben 34 eine kurze richtige
  Option, aber nur ein Teil davon taugt als freie Antwort: „Reed-Kontakt"
  und „Aufsichtsrat" schon, „Er fällt exponentiell." oder „Ja, für 9 Monate"
  nicht — das sind Antworten auf eine Auswahl und ohne sie unlösbar. Eine
  automatische Ableitung hätte Fragen erzeugt, an denen man zu Unrecht
  scheitert. Hinterlegt sind daher **31 von Hand geprüfte Fragen** im neuen
  Feld `freieAntwort`; alle übrigen bleiben auf der mittleren Stufe.

  Abgesichert durch einen Gurt über den Bestand: Jede hinterlegte Antwort
  muss von der Bewertung als richtig erkannt werden, und kein Ablenker
  derselben Frage darf durchgehen — sonst wäre die harte Fassung leichter
  als die leichte.

  **Das Ganze hängt an einem Schalter** (Einstellungen → Erprobung,
  standardmäßig an). Ausgeschaltet verhält sich die App exakt wie vorher;
  der Zähler läuft trotzdem weiter, damit ein späteres Einschalten nicht bei
  null beginnt. **Keine Datenmigration** — Karten ohne den Zähler starten
  auf 0.

  Format und Aufnahmekriterien stehen in `docs/FRAGENFORMAT.md`.

- **Lerntempo statt Dauerstau.** Der Zähler auf dem Dashboard klebte bei
  „30 Karten fällig" und bewegte sich nie — egal, wie viel gelernt war.
  Ursache: Jede noch nie gesehene Frage galt als fällig, und bei 681
  ungesehenen Fragen war die Obergrenze von 30 dauerhaft erreicht. Die Zahl
  sagte damit weder etwas über den Fortschritt noch darüber, was einen in
  der Session erwartet.

  Der Tag hat jetzt ein **Pensum aus zwei Töpfen**: Wiederholungen, deren
  Termin erreicht ist, plus ein einstellbares Kontingent neuer Karten
  (**Einstellungen → Lerntempo**, Standard 20 pro Tag, Regler bis 50). Das
  Dashboard nennt beide getrennt — „Heute 27 Karten · 7 Wiederholungen ·
  20 neu" —, weil eine Summe nicht verrät, ob die Session anstrengend wird.

  **Wiederholungen sind gedeckelt, aber nicht gestrichen.** Höchstens das
  Dreifache des Tempos (mindestens 20) kommt an einem Tag dran; der Rest
  bleibt fällig und wird als „… weitere warten auf die nächsten Tage"
  ausgewiesen. Wer eine Woche aussetzt, steht so nicht vor dreihundert
  Karten und fängt gar nicht erst an. Der Deckel hängt am Tempo-Regler und
  braucht deshalb keinen zweiten.

  **Eine zweite Session am selben Tag tischt nicht erneut auf.** Gezählt
  wird je Frage der früheste Versuch überhaupt; liegt der heute, war die
  Karte heute neu und geht vom Kontingent ab. Bei Tempo 0 wird nur noch
  wiederholt — brauchbar in der Woche vor der Prüfung.

  Dashboard und „Heute fällig" ziehen aus derselben Quelle, die angezeigte
  Zahl ist also genau die, die man vorgesetzt bekommt. Frei üben, Thema
  vertiefen, Fehlerquellen und der Testlauf bleiben unberührt — sie haben
  mit dem Lerntempo nichts zu tun. **Keine Datenmigration:** Ein Gerät ohne
  gespeicherten Wert startet auf 20.

- **Variierende Aufgaben.** Wer eine Rechenaufgabe zum dritten Mal sieht,
  erinnert sich an „5,06" statt an den Rechenweg. Die Karte gilt dann als
  sicher, das Verfahren sitzt aber nicht. **86 der 97 Rechenaufgaben**
  erscheinen jetzt bei jedem Durchgang mit anderen Zahlen.

  Fragen ohne das neue Feld `varianten` bleiben unverändert — Fristen,
  Paragrafen und Definitionen dürfen nicht variieren, dort *ist* der Wert
  der Lernstoff.

  **Im Testlauf stehen die Originalwerte.** Dort ist der authentische
  Prüfungsbogen der Zweck; gewürfelt wird in freier Übung und Wiederholung.
  Eine zurückgestellte Frage („Nochmal") zeigt dieselbe Aufgabe noch einmal —
  man bekommt die, an der man gescheitert ist.

  **Der Lernfortschritt bleibt heil.** Die Variante ist eine gewöhnliche
  Frage mit derselben ID; Bewertung, Aufdeckung, Statistik und FSRS laufen
  unverändert weiter. Keine Datenmigration.

  Wo Werte zusammengehören, kommen sie aus einer Tabellenzeile statt aus dem
  Zufallsgenerator: Steigung und Flankendurchmesser eines Gewindes, Nennmaß
  und Grundabmaß einer Passung, Nennleistung und Nenndrehzahl eines Motors.

  **Elf Aufgaben variieren nicht**, jede mit Begründung in
  `tool/varianten_*.py`: sieben zeigen eine Zeichnung (die Zahlen stehen im
  Bild), bei zwei ist jede gegebene Größe eine Eigenschaft der benannten
  Baugruppe, und zwei müssten Normtabellen bzw. Gesetzestext nachbilden —
  eine falsche Passungstabelle wäre schlimmer als eine Aufgabe, die sich
  nicht ändert.

  Abgesichert durch den Validator: Setzt man die hinterlegten Originalwerte
  ein, muss wieder genau der gespeicherte Fragetext und genau der
  gespeicherte Lösungswert herauskommen. Dazu 200 Ziehungen je Aufgabe gegen
  unlösbare Ergebnisse. Der Gurt hat während der Umstellung **elf Fehler
  gefunden** — darunter eine Spannweiten-Aufgabe, bei der alle fünf
  Messwerte zusammenfallen konnten.

  Format und Regeln stehen in `docs/FRAGENFORMAT.md`.

- **Neun Datenkorrekturen**, alle vom Validator ausgelöst: acht
  Ziffernguppierungen mit Leerzeichen bzw. ein Tausenderpunkt in Fragetexten
  (sonst nirgends im Bestand) und zwei Lösungswerte, die aus dem eigenen
  Lösungsweg gerundet abgelesen waren — 5314 statt 5314,5 W und 1404 statt
  1401,5 N. Beide lagen innerhalb der Aufgabentoleranz, waren also nie
  spürbar.

### Behoben

- **Kein Komma auf der Zahlentastatur.** Zahlenfragen öffneten auf dem
  Telefon den reinen Ziffernblock, „5,06" ließ sich dort gar nicht
  eintippen. Die Bewertung nahm Kommas seit jeher an — es fehlte nur die
  Taste. Jetzt mit Dezimaltrennzeichen und Vorzeichen, letzteres für die
  Aufgaben mit negativem Ergebnis.

- **Richtig gewusst, trotzdem „Falsch".** Die Freitextbewertung verglich
  Zeichenketten, wo sie Bedeutung vergleichen musste. Vier gemeldete Fälle,
  eine Ursache — behoben für alle 172 Freitextfragen:

  - `Arbeitslosengeld 2` galt nicht für `Arbeitslosengeld II`
  - `Gewerkschaften, Arbeitgeber` galt nicht für `Gewerkschaft und
    Arbeitgeber` — Komma statt „und", Plural statt Singular
  - ausgeschriebene Zahlen (`vierzehn Tage`) mussten je Frage von Hand
    hinterlegt werden und fehlten oft
  - `2 Wochen` fehlte bei der Widerrufsfrist (`wi-vs-001`)

  Der Vergleich läuft jetzt in drei Stufen: normalisierte Zeichenkette,
  dann die Aufzählung als ungeordnete Menge, zuletzt mit gestrichenen
  Pluralendungen. Die Grenzen sind eng gezogen — die Pluralregel greift
  erst ab neun Zeichen, damit Härte (Eigenschaft) und Härten (Verfahren)
  zwei Antworten bleiben, und nur I bis IV zählen als römische Ziffern,
  weil V, C und M im Bestand Einheiten sind.

  Abgesichert durch `test/antwort_kollisionen_test.dart`: Der Test prüft
  den gesamten Bestand gegen den früheren, strengen Vergleich und schlägt
  an, sobald die Lockerung zwei Fragen derselben Kategorie dieselbe Antwort
  gelten lässt. Derzeit: keine einzige neue Verwechslung.

- **„Ausführlich" zeigte denselben Absatz ein zweites Mal.** Bei 78 der 603
  langen Erklärungen fand die Aufteilung keine Satzgrenze und legte
  deshalb den vollständigen Text unter die Kurzfassung. Aufgeklappt ersetzt
  der volle Text die Kurzfassung jetzt, statt sie zu ergänzen; der Knopf
  heißt dann „Weniger".

  Dazu zwei Änderungen an der Aufteilung selbst: Doppelpunkt und Semikolon
  gelten als Ersatz-Satzgrenze (greift bei 14 Erklärungen), und wo das
  Aufklappen weniger als 60 Zeichen nachliefert, entfällt es ganz — das
  betrifft 34 Fragen, darunter genau den gemeldeten Fall, bei dem 40
  Zeichen Gewinn 177 Zeichen Wiederholung gegenüberstanden.

- **Abgeschnittene Beschriftung** am Selbsterklärungs-Feld: `labelText` ist
  in Material einzeilig, „(optional, wird nicht bewertet)" fiel auf dem
  Handy weg. Der Hinweis steht jetzt als `helperText` darunter.

### Hinzugefügt

- **Tipp-Funktion für Formelzeichen und Begriffe.** Unter dem Fragetext
  erscheint ein Knopf, wenn im Text erklärbare Begriffe vorkommen — `ω`,
  `Ø`, `vc`, Passung, GRAFCET. Ein Tippen öffnet kurze Erklärungen, bei
  Bedarf mit Vertiefung (Formel, Einheit, Abgrenzung).

  Der Gedanke dahinter: Wer an einer Aufgabe hängt, weil ihm `ω` nichts
  sagt, hat keine Wissenslücke im Thema — er kann die Frage nur nicht
  lesen. Das eine löst Üben, das andere ein Nachschlagewerk.

  Das Glossar gehört zum Lernpaket (`glossarDatei` bzw. `glossar` inline),
  nicht zur App. Wo ein Tipp die Antwort verriete, blendet `tippsAus` ihn
  aus. Auch im Testlauf verfügbar — in der echten AP2 ist ein Tabellenbuch
  zugelassen.

  Im AP2-Kurs greift er bei 80 von 681 Fragen, höchstens 3 Begriffe je
  Frage.

- **Modus „Fehlerquellen"** — übt gezielt die Karten, bei denen man sich
  sicher war und trotzdem falsch lag. Genau diese Irrtümer sitzen laut
  Hypercorrection-Effekt am hartnäckigsten; bisher wurden sie nur gezählt.
  Die Menge leert sich von selbst: Das Flag wird bei jeder Bewertung neu
  gesetzt, eine richtig beantwortete Frage fällt also wieder heraus. Der
  Knopf erscheint nur, wenn es etwas zu korrigieren gibt.
- **Automatische Wochensicherung** — legt still eine Kopie des Lernstands im
  App-Verzeichnis an und behält die letzten vier. Läuft nach `runApp` und
  ohne `await`, schluckt Fehler selbst: Der App-Start darf daran nie
  scheitern. Auf Web passiert nichts, dort gibt es kein Dateisystem.

### Geändert

- **Play-Store-Vorbereitung**: Release-Signatur verdrahtet (der Build war
  mit dem Debug-Key signiert), R8 samt Proguard-Regeln aktiviert, eigenes
  Launcher- und adaptives Icon statt des Flutter-Standardlogos.
- Datenschutzerklärung, Store-Texte und eine Release-Checkliste mit den
  Play-Anforderungen unter `docs/`.
- README und `docs/product-spec.md` geschrieben — beides war seit dem ersten
  Commit unverändertes Gerüst.
- App-Version steht jetzt an einer Stelle (`main.dart`) statt zweimal.

### Behoben

- **Zuordnungsaufgaben waren auf dem Handy abgeschnitten.** Begriff und
  Auswahl lagen nebeneinander in einer Row, dem Dropdown blieb die halbe
  Breite und sein Popup wurde am Bildschirmrand beschnitten. Jetzt volle
  Breite mit Auswahlblatt, in dem langer Text umbricht.
- Bei Lückentexten mit mehreren Lücken verdeckte die Tastatur das letzte
  Feld und den Weiter-Knopf.
- Die Kurskarte zeigte „2 Testlauf" statt „2× Testlauf".

### Technisch

- Tests von 134 auf **164**: Fachgespräch-Session (bis dahin 543 Zeilen ohne
  jeden Test), Kursverwaltung, Zuordnung auf kleinen Bildschirmen,
  automatische Sicherung.

## [1.2.0] – 2026-08-17

Die App wird vom AP2-Trainer zum **allgemeinen Lernwerkzeug**: Lernthemen
kommen jetzt als importierbare Pakete, statt fest im Code zu stehen.

### Hinzugefügt

- **Lernpakete importieren** (`.json` oder `.zip`) über den neuen Reiter
  *Kurse*. Vor dem Installieren zeigt eine Vorschau Umfang und alle beim
  Einlesen aufgefallenen Auffälligkeiten. Format: [docs/PAKETFORMAT.md](docs/PAKETFORMAT.md).
- **Kursverwaltung**: zwischen Kursen wechseln, importierte Kurse samt
  Lernfortschritt entfernen. Der mitgelieferte AP2-Kurs bleibt erhalten.
- ZIP-Pakete können eigene **Bilder** mitbringen; sie landen im
  App-Verzeichnis und werden in Fragen und Testläufen angezeigt.
- Themenauswahl zeigt jetzt die **Fragenzahl je Kategorie**.

### Geändert

- **Lernfortschritt wird je Kurs getrennt geführt.** FSRS-Karten liegen unter
  `kursId::frageId`, Verlaufseinträge tragen eine `kursId`. Bestandsdaten
  werden beim ersten Start automatisch migriert - der bisherige Fortschritt
  bleibt vollständig erhalten.
- **Alles Kursspezifische kommt aus `kurs.json`** statt aus dem Dart-Code:
  Bereiche samt Farben, Icons und Gewichten, Testläufe samt Zeitlimit,
  Zeichnungen und Stücklisten sowie die Beschriftungen für Lernstand,
  Testlauf und Dialog.
- **Prüfungsreife → Lernstand**: Bereiche, Beschriftungen und Gewichte
  richten sich nach dem Kurs. Ohne Angabe zählen alle Bereiche gleich.
- Testlauf und Dialog erscheinen nur, wenn der Kurs sie mitbringt **und**
  Inhalt dafür hat.
- Backups sichern den Lernstand **aller** Kurse (Schema 2). Backups im alten
  Format lassen sich weiterhin einlesen und werden dem AP2-Kurs zugeordnet.
  Dateiname jetzt `lernstand-backup-<datum>.json`.
- Alle Dashboard-Auswertungen beziehen sich auf den aktiven Kurs.

### Behoben

- **Web-Version blieb lauffähig.** Der Umbau hätte sie sonst beim Start
  zerlegt: `getApplicationDocumentsDirectory()` läuft vor `runApp` und wirft
  auf Web, und `flutter_local_notifications` hat dort gar keine
  Implementierung. Datei-Zugriffe laufen jetzt über
  `lib/core/plattform/datei_ablage.dart` mit bedingtem Import (io/web),
  Benachrichtigungen steigen auf nicht unterstützten Plattformen selbst früh
  aus. Vier Tests wachen darüber, dass beide Varianten der Naht synchron
  bleiben — dieser Fehlertyp fällt weder beim Testen noch beim Analysieren
  auf, sondern erst im Browser.
- **21 Fragen waren über "Thema vertiefen" nicht erreichbar.** Die Kategorien
  standen fest im Screen und wichen von den Daten ab (`Steuerung & Regelung`
  vs. `Steuerung und Regelung`, `Kaufvertrag` vs. `Kaufvertragsrecht`,
  `Elektrotechnik` vs. `Elektrotechnik & Sensorik`). Die Liste wird jetzt
  aus den Fragen abgeleitet.
- **Dashboard aktualisierte sich innerhalb einer Session nicht.** Nach
  beantworteten Fragen zeigten die Auswertungen alte Werte bis zum Neustart.
- **`/quiz` stürzte ohne Modus ab** (Deep-Link, Web-Reload, Browser-Zurück) -
  ungeprüfter Cast, jetzt mit Hinweisseite.
- Einen Kurs zu entfernen scheiterte nicht mehr, wenn seine Bilddateien
  nicht löschbar waren.

### Plattformen

Die Web-Version kann jetzt fast alles. Was dort fehlt, fehlt aus
Plattformgründen und wird gar nicht erst angeboten:

| Funktion | Web |
|---|---|
| Lernen, alle 8 Fragetypen, FSRS, Dashboard | vollständig |
| Kurse wechseln, JSON-Paket importieren | vollständig |
| Backup exportieren und importieren | über den Browser-Dialog |
| ZIP-Paket importieren | Fragen ja, Bilder zeigen einen Platzhalter |
| Erinnerungen | ausgeblendet (kein Web-Support im Plugin) |

### Technisch

- Tests von 76 auf **134** erhöht; neu abgedeckt: Paket-Parser (26),
  Migration (6), Kursspeicher (6), Web-Tauglichkeit (4), der bisher
  ungetestete **Testlauf-Countdown** inklusive Pause und Zeitablauf, sowie
  das Dashboard mit echten Daten statt nur im Leerzustand.
- `flutter analyze`: 0 Fehler, 0 Warnungen, 0 Infos.
- `FrageRepository` und `PruefungsMetadaten` entfallen; ersetzt durch
  `KursRepository`, `KursStore` und `kurs.json`.
- Neue Abhängigkeit: `archive` (entpackt ZIP-Pakete).

### Nicht umgesetzt

- Ein Editor zum Anlegen von Fragen in der App.
- Export eines installierten Kurses als Paketdatei.
- Die Zeichnungen der vier IHK-Prüfungen fehlen weiterhin; W22 und S19 haben
  auch keine Stückliste als Textersatz.

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
