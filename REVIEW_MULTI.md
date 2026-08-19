# Zu leichte Multi-Fragen - Durchsicht

Erzeugt von `tool/multi_bericht.py` aus den Warnungen von
`tool/validate_fragen.dart`. **35 Fragen** betroffen.

## Worum es geht

Bei diesen Fragen sind fast alle Optionen richtig. Die Bewertung
verlangt zwar die exakte Menge, ein blindes "alles ankreuzen" kostet
also den Punkt - trotzdem trennt so eine Frage kaum zwischen Koennen
und Raten. Wer die eine falsche Option kennt, hat sie geloest.

## Wie du damit arbeitest

Pro Frage gibt es zwei sinnvolle Wege:

1. **Eine richtige Option zu einer falschen umformulieren** - meist
   die beste Wahl, weil die Optionszahl gleich bleibt und die Frage
   ihren Zuschnitt behaelt.
2. **Eine plausible falsche Option ergaenzen** und dafuer eine
   richtige streichen.

Sag mir je Frage, was gelten soll - ich trage es ein und ziehe die
Erklaerung nach. Von allein aendere ich hier nichts: Welche Aussage
fachlich haltbar ist, entscheidest du.

---

## auftragsanalyse_form_lagetoleranzen

### `au-fl-009` - 4 von 5 richtig

> Welche Informationen enthält das Oberflächenzeichen (Rauheitssymbol) nach DIN EN ISO 1302?

- [x] Den Rauheitskennwert und seinen Grenzwert (z.B. Ra 1,6)
- [x] Das Fertigungsverfahren (z.B. Drehen, Schleifen)
- [x] Die Bearbeitungsrichtung (Rillenrichtung)
- [ ] Die Werkstoffhärte
- [x] Den Bearbeitungszugabe (Aufmaß)

*Erklaerung:* Das Oberflächenzeichen nach DIN EN ISO 1302 kann enthalten: Rauheitswert (Ra, Rz), Fertigungsverfahren, Rillenrichtung, Bearbeitungszugabe und weitere Rauheitskennwerte. Die Werkstoffhärte wird nicht im Oberflächenzeichen angegeben, sondern in Werkstoff- oder Wärmebehandlungsvorschriften.

### `au-fl-013` - 4 von 5 richtig

> Welche der folgenden Toleranzarten gehören zu den Lauftoleranzen nach DIN ISO 1101?

- [x] Rundlauf
- [x] Planlauf
- [x] Gesamtrundlauf
- [ ] Neigung
- [x] Gesamtplanlauf

*Erklaerung:* Lauftoleranzen umfassen Rundlauf (radial, eine Umdrehung), Planlauf (axial, eine Umdrehung), Gesamtrundlauf (radial, über gesamte Länge) und Gesamtplanlauf (axial, über gesamte Fläche). Neigung ist eine Richtungstoleranz (Lagetoleranz), keine Lauftoleranz.


## auftragsanalyse_funktionsanalyse

### `au-fa-004` - 4 von 5 richtig

> Welche der folgenden Betriebszustände müssen bei der Funktionsanalyse einer Maschine berücksichtigt werden?

- [x] Normalbetrieb
- [x] Anlauf/Hochfahren
- [x] Notabschaltung
- [x] Wartungszustand
- [ ] Idealbetrieb ohne Verluste

*Erklaerung:* Eine vollständige Funktionsanalyse betrachtet alle realen Betriebszustände: Normalbetrieb, Anlauf, Notabschaltung und Wartung. Der 'Idealbetrieb ohne Verluste' ist kein realer Zustand – jede Maschine hat Verluste durch Reibung, Wärme und Verschleiß.

### `au-fa-011` - 4 von 5 richtig

> Welche Informationen sollte eine vollständige Funktionsbeschreibung eines Bauteils enthalten?

- [x] Zweck/Aufgabe des Bauteils
- [x] Wirkprinzip (physikalischer Effekt)
- [ ] Herstellungskosten
- [x] Schnittstellen zu Nachbarbauteilen
- [x] Anforderungen (Kräfte, Temperaturen, Umgebung)

*Erklaerung:* Eine Funktionsbeschreibung klärt WARUM ein Bauteil vorhanden ist (Zweck), WIE es funktioniert (Wirkprinzip), WAS es mit Nachbarbauteilen verbindet (Schnittstellen) und unter WELCHEN Bedingungen es funktionieren muss (Anforderungen). Herstellungskosten gehören zur Kostenanalyse, nicht zur Funktionsbeschreibung.


## auftragsanalyse_hydraulik

### `au-hy-013` - 4 von 5 richtig

> Welche Maßnahmen sind beim Umgang mit Hydrauliköl aus Sicherheits- und Umweltgründen zu beachten?

- [x] Schutzhandschuhe tragen (Hautreizung möglich)
- [x] Leckagen sofort abdichten und Öl fachgerecht entsorgen
- [ ] Hydrauliköl kann im Abfluss entsorgt werden
- [x] Bei Hautkontakt sofort mit Wasser abspülen
- [x] Druckprüfungen niemals ohne Druckbegrenzungsventil durchführen

*Erklaerung:* Hydrauliköl ist wassergefährdend (WGK 1-2) und darf nicht im Abfluss entsorgt werden – es muss als Altöl entsorgt werden. Druckprüfungen ohne Druckbegrenzungsventil können zu gefährlichem Druckaufbau führen. Sicherheitsmaßnahmen schützen Mensch und Umwelt.


## auftragsanalyse_instandhaltung

### `au-ih-004` - 4 von 5 richtig

> Welche Maßnahmen gehören zur vorbeugenden Instandhaltung (Wartung)?

- [x] Schmieren von Lagern nach Wartungsplan
- [x] Austauschen von Verschleißteilen zu festgelegten Intervallen
- [ ] Reparieren eines ausgefallenen Elektromotors
- [x] Prüfen von Sicherheitsventilen und deren Ansprechdruck
- [x] Reinigen von Kühlmittelfiltern

*Erklaerung:* Vorbeugende Instandhaltung findet statt, BEVOR ein Ausfall eintritt. Reparieren nach einem Ausfall (Option 3) ist Instandsetzung = korrektive Instandhaltung. Alle anderen genannten Maßnahmen reduzieren das Ausfallrisiko proaktiv.

### `au-ih-011` - 4 von 5 richtig

> Welche Informationen sollte ein vollständiger Instandhaltungsauftrag enthalten?

- [x] Anlage/Baugruppe und genaue Lokalisierung des Schadens
- [ ] Persönliche Meinung des Meldenden über den Fehlergrund
- [x] Sicherheitshinweise und Schutzmaßnahmen
- [x] Benötigte Ersatzteile und Werkzeuge
- [x] Rückmeldung über durchgeführte Arbeiten und Ergebnis

*Erklaerung:* Ein Instandhaltungsauftrag (Werkauftrag) enthält: genaue Objektbeschreibung, Schadensbild, Sicherheitsmaßnahmen (LOTO), benötigte Ressourcen (Teile/Werkzeug/Zeit/Qualifikation) und die Rückmeldung. Persönliche Vermutungen ohne Beleg gehören nicht in den formalen Auftrag.


## auftragsanalyse_technisches_zeichnen

### `au-tz-004` - 4 von 5 richtig

> Welche Angaben gehören zu einer vollständigen Maßeintragung nach DIN 406?

- [x] Maßzahl
- [x] Maßlinie mit Pfeilspitzen
- [x] Maßhilfslinien
- [ ] Schriftfeld-Nummer
- [x] Toleranzangabe (falls erforderlich)

*Erklaerung:* Eine vollständige Maßeintragung besteht nach DIN 406 aus Maßzahl (das Maß in mm), Maßlinie mit Begrenzungszeichen (Pfeile oder Schrägstriche) und Maßhilfslinien, die den Messbereich begrenzen. Toleranzangaben gehören dazu, wenn Genauigkeitsanforderungen bestehen. Die Schriftfeld-Nummer ist kein Bestandteil der Maßeintragung.

### `au-tz-014` - 4 von 5 richtig

> Welche der folgenden Schnittarten sind nach DIN ISO 128-44 genormt?

- [x] Vollschnitt
- [x] Halbschnitt
- [x] Teilschnitt (Ausbruch)
- [x] Profilschnitt
- [ ] Perspektivschnitt

*Erklaerung:* DIN ISO 128-44 normiert Vollschnitt (vollständiges Durchschneiden), Halbschnitt (symmetrische Bauteile, halb Ansicht/halb Schnitt), Teilschnitt/Ausbruch (lokale Einblicke mit Freihandlinie) und Profilschnitt (herausgeklappter Querschnitt). Der Perspektivschnitt ist keine genormte Schnittart.


## auftragsanalyse_toleranzen_passungen

### `au-tp-014` - 4 von 5 richtig

> Welche Aussagen zum ISO-Toleranzsystem sind korrekt?

- [x] Großbuchstaben (A–ZC) bezeichnen Bohrungstoleranzen
- [x] Kleinbuchstaben (a–zc) bezeichnen Wellentoleranzen
- [ ] Höhere IT-Grade bedeuten engere Toleranzen
- [x] Das Toleranzfeld H hat immer EI = 0
- [x] Das Toleranzfeld h hat immer es = 0

*Erklaerung:* Im ISO-Toleranzsystem: Großbuchstaben = Bohrungen, Kleinbuchstaben = Wellen. H (EI = 0) und h (es = 0) sind die Grundlagen des Einheitssystems. Höhere IT-Grade bedeuten jedoch WEITERE (nicht engere) Toleranzen: IT1 ist enger als IT16.


## fertigungstechnik_cnc_grundlagen

### `ft-cnc-013` - 4 von 5 richtig

> Welche Prüfschritte sind vor dem ersten Einsatz eines neuen CNC-Programms an der Maschine durchzuführen?

- [x] Grafische Simulation / DNC-Probelauf mit zurückgezogener Spindel
- [x] Überprüfung der Werkzeugkorrekturen (Länge und Radius) in der Steuerung
- [x] Prüfung der Spannmittelpositionierung gegen Kollision mit Werkzeugbahn
- [ ] Erstbearbeitung sofort mit vollem Vorschub und maximaler Zustellung
- [x] Nullpunkt-Kontrolle (G54 auf korrekte Position gesetzt)

*Erklaerung:* Vor dem Erstlauf: Simulation (zeigt Kollisionen), Werkzeugkorrekturen prüfen (falscher Radius/Länge → Ausschuss), Spannmittel auf Kollision prüfen, Nullpunkt verifizieren. Erstbearbeitung immer mit reduziertem Vorschub (Override auf 10-20%) und Hand am NOT-HALT – niemals sofort mit Vollgas!


## fertigungstechnik_fertigungs_arbeitsplanung

### `ft-ap-006` - 4 von 5 richtig

> Welche Angaben enthält ein vollständiger Arbeitsplan?

- [x] Arbeitsgang-Nummer und Beschreibung
- [ ] Persönliche Gehaltsabrechnung des Maschinenführers
- [x] Maschinen- und Arbeitsplatzkennzeichen
- [x] Schnittdaten (Drehzahl, Vorschub, Tiefe)
- [x] Prüfmerkmale und Prüfmittel

*Erklaerung:* Arbeitsplan-Inhalte: Arbeitsgangnummer, -bezeichnung, Maschinen-ID, Werkzeug- und Vorrichtungsliste, Schnittdaten, Zeiten (t_h, t_n) und Prüfanweisungen. Lohnabrechnung gehört zur Buchhaltung, nicht in den Fertigungsplan.

### `ft-ap-013` - 4 von 5 richtig

> Welche Dokumente gehören zur technischen Dokumentation einer Fertigungsaufgabe?

- [x] Zeichnung mit Maßen, Toleranzen und Oberflächenangaben
- [x] Stückliste der verbauten Teile
- [ ] Urlaubsplan der Fertigungsmannschaft
- [x] NC-Programm für CNC-Bearbeitungen
- [x] Prüfplan mit Prüfmerkmalen und -mitteln

*Erklaerung:* Technische Fertigungsdokumentation: Zeichnung (Sollgeometrie), Stückliste (Materialbedarfsplanung), NC-Programm (CNC-Fertigung), Prüfplan (Qualitätssicherung), Arbeitsplan (Arbeitsgangreihenfolge). Personalplanung (Urlaubsplan) gehört zur Personalverwaltung, nicht zur Fertigungsdokumentation.


## fertigungstechnik_fuegeverfahren

### `ft-fv-004` - 4 von 5 richtig

> Welche Aussagen zu Schweißnahtvorbereitung und -qualität sind richtig?

- [x] V-Naht wird bei Blechdicken > 3 mm eingesetzt, um vollständige Durchschweißung zu ermöglichen
- [x] Verunreinigungen (Öl, Rost, Feuchtigkeit) können Poren und Risse verursachen
- [ ] Die Wärmeeinflusszone (WEZ) ist immer maßlos und hat keinen Einfluss auf die Bauteilfestigkeit
- [x] Ein Vorwärmen reduziert Härterspitzen und Kaltrissrisiko bei unlegierten Stählen
- [x] Schweißpositionen (PA, PB...) beschreiben die Lage der Naht beim Schweißen

*Erklaerung:* WEZ (Wärmeeinflusszone): Durch Wärme veränderte Zone NEBEN der Naht. Bei härtbaren Stählen: höhere Härtewerte in der WEZ → Sprödbruchgefahr. Vorwärmen (Tp = 100-300°C) verlangsamt Abkühlung → reduziert Härteanstieg. Schweißpositionen nach ISO 6947: PA = Wannenlage, PB = Horizontalkehlnaht, PC = Querposition, PD = Überkopf.

### `ft-fv-011` - 4 von 5 richtig

> Welche Schutzmaßnahmen sind beim Lichtbogenschweißen zwingend einzuhalten?

- [x] Schweißschutzschild/Helm mit passender Schutzstufe (DIN EN 169)
- [x] Schutzkleidung (Leder/Baumwolle, flammhemmend) – kein Kunstfaser
- [ ] Schweißen in ungelüfteten Räumen ist unbedenklich bei Kleinmengen
- [x] Feuerlöscher und Brandwache bei Brand gefährdeten Bereichen
- [x] Schutz vor UV-Strahlung für alle Personen in der Nähe

*Erklaerung:* Schweißschutz: Helm mit Schutzstufe 9-13 (abhängig vom Schweißstrom), Lederhandschuhe, flammhemmende Kleidung (Kunstfaser schmilzt!), Absaugung von Schweißrauch (toxisch!), UV-Schutzvorhänge. In engen Räumen: Belüftung / Absaugung Pflicht. Brandwache nach DIN VDE 0105 bei feuergefährdeten Bereichen.


## fertigungstechnik_qualitaetssicherung

### `ft-qs-006` - 4 von 5 richtig

> Welche Prüfmerkmale werden im Rahmen der Wareneingangsprüfung typischerweise kontrolliert?

- [x] Maßhaltigkeitsprüfung nach Zeichnungsvorgaben
- [x] Sichtprüfung auf Beschädigungen und Korrosion
- [ ] Preis- und Lieferantenvergleich mit anderen Anbietern
- [x] Überprüfung der Begleitdokumente (Lieferschein, Prüfzertifikat)
- [x] Werkstoffprüfung (z.B. Härte, chemische Zusammensetzung) bei kritischen Teilen

*Erklaerung:* Wareneingangsprüfung: Sicht- und Maßprüfung, Dokumentenprüfung (Prüfzeugnis nach EN 10204: 2.1 Konformitätsbescheinigung, 3.1 Abnahmeprüfzeugnis). Bei sicherheitsrelevanten Teilen: Werkstoffnachweis, Härteprüfung, ggf. ZfP. Preisvergleich ist Einkaufsaufgabe, keine Prüfaufgabe.


## fertigungstechnik_schnittdaten

### `ft-sd-011` - 4 von 5 richtig

> Welche Aussagen zur Schnittkraftberechnung Fc ≈ kc · A sind korrekt? (Mehrfachauswahl)

- [x] kc ist die spezifische Schnittkraft mit der Einheit N/mm².
- [x] A ist der Spanungsquerschnitt in mm².
- [x] Fc steigt linear mit zunehmendem Vorschub f.
- [ ] kc hängt nicht vom Werkstoff ab.
- [x] Fc wird in Newton angegeben.

*Erklaerung:* kc [N/mm²] ist werkstoffabhängig (Stahl höher als Alu), A = ap · f [mm²], Fc = kc · A [N]. Da A = ap · f linear in f ist, steigt Fc linear mit f. kc hängt stark vom Werkstoff ab.


## fertigungstechnik_werkstoffe_waermebehandlung

### `ft-ww-007` - 4 von 5 richtig

> Welche Aussagen zu Aluminium-Knetlegierungen sind richtig?

- [x] Die Bezeichnung EN AW-6082 steht für Aluminium-Magnesium-Silizium-Legierung
- [x] Alu-Knetlegierungen der 7000er-Serie (Al-Zn-Mg-Cu) erreichen die höchsten Festigkeiten
- [ ] Aluminiumlegierungen sind immer schlechter schweißbar als Stahl
- [x] Naturharte Legierungen (3000er, 5000er) werden durch Kaltumformung verfestigt
- [x] Ausscheidungshärtbare Legierungen (2000er, 6000er, 7000er) können durch Wärmebehandlung gehärtet werden

*Erklaerung:* EN AW-6082 (AlSi1MgMn): häufigste Konstruktionslegierung, gut schweißbar. 7075 (Al-Zn-Mg-Cu): höchste Festigkeit (~570 MPa), schlechter schweißbar. 5xxx (Al-Mg): naturharte, meerschweißgeeignet (Schiffbau). 2xxx (Al-Cu): ausscheidungshärtbar, Luftfahrt. Manche Alu-Legierungen sind sehr gut schweißbar (5xxx, 6xxx).

### `ft-ww-013` - 4 von 5 richtig

> Welche Faktoren beeinflussen die Einhärtetiefe (EHT) beim Randschichthärten?

- [x] Kohlenstoffgehalt und Legierungszusammensetzung des Stahls
- [x] Abkühlmittel (Wasser kühlt schneller als Öl)
- [ ] Bauteilfarbe (helle Bauteile reflektieren mehr Wärme)
- [x] Bauteilgröße und Querschnittsverhältnis (Abkühlrate im Kern)
- [x] Austenitisiertemperatur und Haltezeit

*Erklaerung:* Einhärtetiefe hängt ab von: Einhärtbarkeit (Legierung, C-Gehalt), Abkühlrate (Abschreckmittel: Wasser > Öl > Luft), Bauteilgröße (dicker → Kern kühlt langsamer → geringere Kernhärte), Austenitisierparameter. Bauteilfarbe hat keinen Einfluss beim Tauchhärten. Induktionshärten: Frequenz bestimmt Eindringtiefe (höher = flacher).


## fertigungstechnik_werkzeuge_schneidstoffe

### `ft-ws-006` - 4 von 5 richtig

> Welche Verschleißarten treten an Zerspanwerkzeugen auf? (Mehrfachauswahl)

- [x] Freiflächenverschleiß VB (an der Freifläche)
- [x] Kolkverschleiß KT (an der Spanfläche)
- [x] Schneidkantenverrundung
- [ ] Thermische Ausdehnung des Werkzeughalters
- [x] Plastische Deformation der Schneidkante

*Erklaerung:* Freiflächenverschleiß VB, Kolkverschleiß KT, Schneidkantenverrundung und plastische Deformation sind typische Verschleißformen. Die Ausdehnung des Halters ist kein Werkzeugverschleiß.


## fertigungstechnik_wirtschaftliche_fertigung

### `ft-wf-013` - 4 von 5 richtig

> Welche Faktoren sprechen für eine Eigenfertigung (Make) im Vergleich zum Fremdbezug (Buy)?

- [x] Know-how-Schutz bei kritischen Kernprozessen
- [x] Bessere Kapazitätsauslastung eigener Maschinen
- [ ] Lieferant hat deutlich niedrigere Stückkosten durch Skaleneffekte
- [x] Höhere Flexibilität und Qualitätskontrolle
- [x] Deutlich kürzere Lieferzeiten durch eigene Produktion

*Erklaerung:* Make vs. Buy: Eigenfertigung wenn: Know-how-Schutz wichtig, freie Kapazitäten vorhanden, Qualitätskontrolle kritisch, kurze Lieferzeiten nötig. Fremdbezug wenn: Lieferant billiger (Skaleneffekte), Eigenfertigung bindet zu viel Kapital, Kernkompetenz liegt woanders. Meist Mischstrategie für verschiedene Komponenten.


## wiso_arbeitsvertrag

### `wi-av-003` - 4 von 5 richtig

> Welche Angaben muss der Arbeitgeber dem Arbeitnehmer laut Nachweisgesetz (NachwG) schriftlich mitteilen?

- [x] Name und Anschrift der Vertragsparteien
- [x] Beginn des Arbeitsverhältnisses
- [x] Vereinbarte Arbeitszeit und Entgelt
- [x] Dauer des jährlichen Erholungsurlaubs
- [ ] Lichtbild des Arbeitnehmers

*Erklaerung:* Das NachwG (novelliert 2022) verpflichtet Arbeitgeber, die wesentlichen Vertragsbedingungen schriftlich niederzulegen: Parteien, Beginn, Arbeitszeit, Entgelt, Urlaub, Kündigungsfristen u.a. Ein Lichtbild gehört nicht dazu.

### `wi-av-010` - 4 von 5 richtig

> Welche Sachgründe rechtfertigen laut § 14 Abs. 1 TzBfG eine Befristung des Arbeitsvertrages?

- [x] Der betriebliche Bedarf an der Arbeitsleistung ist nur vorübergehend
- [x] Die Befristung erfolgt im Anschluss an eine Ausbildung oder ein Studium
- [x] Der Arbeitnehmer wird zur Vertretung eines anderen beschäftigt
- [x] Der Arbeitgeber möchte den Arbeitnehmer zunächst erproben
- [ ] Das Unternehmen hat weniger als 10 Mitarbeiter

*Erklaerung:* § 14 Abs. 1 TzBfG nennt u.a. folgende Sachgründe: vorübergehender Bedarf, Anschluss an Ausbildung/Studium, Vertretung, Erprobung, Eigenart der Leistung, gerichtlicher Vergleich, personenbezogene Gründe. Die Betriebsgröße ist kein Sachgrund.


## wiso_berufsausbildung

### `wi-ba-003` - 4 von 5 richtig

> Welche der folgenden Punkte gehören zu den Pflichten des Ausbildenden gemäß § 14 BBiG?

- [x] Die Ausbildung planmäßig, zeitlich und sachlich gegliedert durchführen
- [x] Den Auszubildenden kostenlos die Ausbildungsmittel zur Verfügung stellen
- [x] Die Vergütung des Auszubildenden auf Verlangen auf ein Konto überweisen
- [x] Den Auszubildenden zum Besuch der Berufsschule anhalten
- [ ] Dem Auszubildenden Urlaub gemäß dem Wunschtermin gewähren

*Erklaerung:* § 14 BBiG regelt die Pflichten des Ausbildenden: planmäßige Durchführung, kostenlose Ausbildungsmittel, Freistellung für die Berufsschule, Vergütungszahlung per Überweisung. Den Urlaubstermin bestimmt der Auszubildende nicht allein.

### `wi-ba-014` - 4 von 5 richtig

> Welche Pflichten hat der Auszubildende gemäß § 13 BBiG?

- [x] Sorgfältige Ausführung der übertragenen Aufgaben
- [x] Teilnahme am Berufsschulunterricht
- [x] Führen des Berichtshefts (schriftliche Ausbildungsnachweise)
- [x] Den Ausbildenden über längere Krankheit informieren
- [ ] Entgelt pünktlich einfordern

*Erklaerung:* § 13 BBiG verpflichtet Auszubildende zur sorgfältigen Aufgabenerfüllung, Berufsschulbesuch, Führen von Ausbildungsnachweisen und Mitteilung bei Fehlzeiten. Das Einfordern von Entgelt ist kein Pflicht aus § 13, sondern ein Recht.


## wiso_betriebsorganisation

### `wi-bo-011` - 4 von 5 richtig

> Welche Rechtsformen können Industrieunternehmen in Deutschland annehmen?

- [x] GmbH (Gesellschaft mit beschränkter Haftung)
- [x] AG (Aktiengesellschaft)
- [x] KG (Kommanditgesellschaft)
- [ ] BÜRGERGELD (staatliche Unternehmensform)
- [x] GbR (Gesellschaft bürgerlichen Rechts)

*Erklaerung:* Rechtsformen: GmbH (häufigste Kapitalgesellschaft, Haftung auf Gesellschaftsvermögen), AG (Aktionäre haften nur mit Einlage), KG (Komplementär haftet unbeschränkt, Kommanditist beschränkt), GbR (einfachste Form, alle haften unbeschränkt), OHG (Vollhafter). Bürgergeld ist eine Sozialleistung, keine Unternehmensrechtsform.


## wiso_entgelt

### `wi-ent-007` - 4 von 5 richtig

> Welche Angaben muss eine Lohnabrechnung nach § 108 GewO enthalten?

- [x] Zusammensetzung und Berechnung des Arbeitsentgelts
- [x] Art und Höhe der Abzüge (Steuern, SV-Beiträge)
- [x] Betriebliche Zulagen und Prämien
- [ ] Privatadresse des Abteilungsleiters
- [x] Abrechnungszeitraum

*Erklaerung:* § 108 GewO: Lohnabrechnung muss enthalten: Zusammensetzung des Entgelts (Grundlohn, Zulagen, Zuschläge), alle Abzüge (Steuer, SV), Abrechnungszeitraum, persönliche Angaben (Name, SV-Nummer). Privatadresse des Vorgesetzten ist datenschutzrechtlich unzulässig und nicht erforderlich.

### `wi-ent-015` - 4 von 5 richtig

> Welche Angaben sind für die Berechnung der Lohnsteuer relevant?

- [x] Bruttoarbeitsentgelt
- [x] Steuerklasse des Arbeitnehmers
- [x] Kirchensteuer (falls Mitglied einer Kirche)
- [x] Zahl der Kinder (Kinderfreibeträge / Kindergeld-Verrechnung)
- [ ] Bankverbindung des Arbeitnehmers

*Erklaerung:* Lohnsteuerberechnung: Bruttolohn (Bemessungsgrundlage), Steuerklasse (bestimmt Freibeträge und Tarif), Kinderfreibetrag (Zahl der Kinder auf Lohnsteuerkarte), Kirchensteuer (8 oder 9% der Lohnsteuer je nach Bundesland). Bankverbindung: für Auszahlung, aber kein Berechnungsfaktor für die Steuer.


## wiso_kaufvertrag

### `wi-kv-013` - 4 von 5 richtig

> Welche Bestandteile müssen in einem gewerblichen Angebot enthalten sein?

- [x] Genaue Warenbezeichnung und Menge
- [x] Preis (ggf. netto und mit MwSt.) und Zahlungsbedingungen
- [x] Lieferfrist und Lieferbedingungen
- [ ] Persönliche Meinung des Verkäufers über die Qualität
- [x] Angebotsgültigkeitsdauer

*Erklaerung:* Pflichtinhalt eines Angebots (wesentliche Vertragsbestandteile): Vertragsparteien, Ware (Art, Menge, Qualität), Preis, Liefertermin/-ort, Zahlungsbedingungen (Frist, Skonto), Angebotsgültigkeitsdauer. Persönliche Meinungsäußerungen sind keine rechtsverbindlichen Bestandteile des Angebots.


## wiso_markt_preisbildung

### `wi-mp-012` - 4 von 5 richtig

> Welche Aussagen zur sozialen Marktwirtschaft in Deutschland sind richtig?

- [x] Freie Preisbildung durch Angebot und Nachfrage (Marktmechanismus)
- [x] Sozialer Ausgleich durch staatliche Umverteilung (Steuern, Sozialleistungen)
- [ ] Der Staat legt alle Preise fest (Planwirtschaft)
- [x] Wettbewerbsrecht verhindert Monopole und Kartelle
- [x] Privateigentum an Produktionsmitteln ist garantiert

*Erklaerung:* Soziale Marktwirtschaft (Alfred Müller-Armack, Ludwig Erhard): Verbindet Marktwirtschaft (freie Preise, Wettbewerb, Privateigentum) mit sozialem Ausgleich (Sozialversicherung, Umverteilung, Verbraucherschutz). Kein Laissez-faire, aber auch keine Planwirtschaft. Ordnungspolitik: Staat setzt Regeln, greift aber nicht direkt in die Preisbildung ein.


## wiso_sozialversicherung

### `wi-sv-005` - 4 von 5 richtig

> Welche Leistungen erbringt die gesetzliche Rentenversicherung?

- [x] Altersrente (nach Erreichen des Rentenalters und Mindestversicherungszeit)
- [x] Erwerbsminderungsrente (bei dauerhafter Berufsunfähigkeit)
- [ ] Krankengeld für bis zu 78 Wochen
- [x] Hinterbliebenenrente (Witwen-/Witwerrente, Waisenrente)
- [x] Rehabilitation (medizinische und berufliche Maßnahmen)

*Erklaerung:* RV-Leistungen: Altersrente, Erwerbsminderungsrente, Hinterbliebenenrenten, Rehabilitation (Reha vor Rente-Prinzip). Krankengeld zahlt die gesetzliche Krankenversicherung (KV), nicht die RV. KV zahlt Krankengeld ab 7. Woche (nach 6 Wochen Lohnfortzahlung durch AG) für bis zu 78 Wochen.


## wiso_tarifrecht

### `wi-tr-011` - 4 von 5 richtig

> Welche Aussagen zum Streikrecht in Deutschland sind korrekt?

- [x] Ein Streik muss tariflich zulässige Ziele verfolgen (kein politischer Streik)
- [x] Beamte haben kein Streikrecht
- [ ] Streikende Arbeitnehmer behalten ihren vollen Lohnanspruch während des Streiks
- [x] Eine Urabstimmung mit mindestens 75% Ja-Stimmen ist in vielen Gewerkschaften Voraussetzung
- [x] Wildcat-Streiks ohne Gewerkschaftsbeschluss sind in Deutschland generell verboten

*Erklaerung:* Streikrecht: Nur für tarifliche Ziele, nicht politisch. Beamte: Streikverbot (BVerfG). Streikende: KEIN Lohnanspruch – Gewerkschaft zahlt Streikgeld aus Streikfonds. Urabstimmung: nicht gesetzlich vorgeschrieben, aber Gewerkschaftssatzung. Wildcat-Streiks: rechtswidrig (Gewerkschaft haftet für entstehende Schäden nicht, aber Arbeitnehmer verlieren Schutz).


## wiso_verbraucherschutz

### `wi-vs-010` - 4 von 5 richtig

> Welche Angaben muss eine Produktetikette nach EU-Recht für Lebensmittel enthalten?

- [x] Bezeichnung des Lebensmittels
- [x] Zutatenverzeichnis (in absteigender Reihenfolge)
- [x] Mindesthaltbarkeitsdatum (MHD) oder Verbrauchsdatum
- [ ] Name und Adresse des Herstellers des Verpackungsmaterials
- [x] Nährwertinformation (Brennwert, Fette, Kohlenhydrate, Eiweiß)

*Erklaerung:* LMIV-Pflichtangaben: Bezeichnung, Zutaten, Allergene (hervorgehoben), Nettofüllmenge, MHD/Verbrauchsdatum, besondere Aufbewahrungs-/Verwendungsbedingungen, Name/Adresse des Lebensmittelunternehmers (nicht Verpackungshersteller), Ursprungsland (bei Fleisch etc.), Nährwertinformation. Zutaten: absteigend nach Gewichtsanteil (schwerste Zutat zuerst).

### `wi-vs-014` - 4 von 5 richtig

> Welche Institutionen und Organisationen setzen Verbraucherschutz in Deutschland um?

- [x] Verbraucherzentralen (bundesweit, beraten und klagen)
- [x] Bundeskartellamt (verhindert Preisabsprachen und Monopole)
- [x] Stiftung Warentest (unabhängige Produkttests und Veröffentlichungen)
- [ ] Industrie- und Handelskammer (IHK)
- [x] Bundesamt für Verbraucherschutz und Lebensmittelsicherheit (BVL)

*Erklaerung:* Verbraucherschutzakteure: Verbraucherzentralen (Beratung, Abmahnungen, Verbandsklagen), Bundeskartellamt (Wettbewerb), Stiftung Warentest (finanziert durch Bundesmittel, unabhängige Tests), BVL (Lebensmittelsicherheit, Produktsicherheit). IHK vertritt Unternehmensinteressen, nicht Verbraucherinteressen. Europäisch: BEUC (Dachverband der Verbraucherorganisationen).


## wiso_wirtschaftskreislauf

### `wi-wk-006` - 4 von 5 richtig

> Welche Aussagen zum erweiterten Wirtschaftskreislauf (mit Staat) sind richtig?

- [x] Der Staat entnimmt dem Kreislauf Geld durch Steuern und Abgaben
- [x] Der Staat speist Geld durch Staatsausgaben (Renten, Subventionen, Investitionen) in den Kreislauf
- [ ] Staatseinnahmen erhöhen immer das BIP direkt
- [x] Staatliche Transfers (z.B. Kindergeld) sind keine Gegenleistung für eine Produktion
- [x] Staatsschulden entstehen, wenn Staatsausgaben die Einnahmen übersteigen (Budgetdefizit)

*Erklaerung:* Staatlicher Sektor im Kreislauf: Steuern/Abgaben = Entnahmen aus dem Kreislauf. Staatsausgaben (Investitionen, Transfers, Gehälter) = Einspeisung. Transfers (Kindergeld, Renten): zählen nicht als BIP-Beitrag (keine Produktion dahinter). BIP-Komponente: Staatsnachfrage (staatliche Käufe von Gütern/Diensten, z.B. Bau von Straßen). Defizit = Staatsausgaben > Einnahmen.

