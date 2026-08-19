# Produktbeschreibung

## Ziel

Prüfungsstoff so wiederholen, dass er bis zur Prüfung sitzt — statt ihn
kurz vorher einmal durchzulesen.

Der Unterschied zu einer Karteikarten-App liegt in zwei Punkten:

1. **Der Zeitpunkt der Wiederholung folgt aus dem Antwortverhalten**, nicht
   aus festen Stufen. Was sitzt, kommt seltener; was wackelt, früher.
2. **Selbsteinschätzung wird mitgeführt.** Wer sich sicher war und trotzdem
   falsch lag, hat nicht eine Wissenslücke, sondern einen *falschen*
   Wissensstand — und der ist gefährlicher, weil man ihn nicht bemerkt.

## Zielgruppe

Auszubildende, die auf eine Abschlussprüfung lernen — zunächst
Industriemechaniker, durch das Paketformat aber offen für andere Berufe und
Themen.

Angenommen wird: lernt in kurzen Einheiten, oft unterwegs, ohne verlässliche
Internetverbindung, auf dem eigenen Handy.

## Im Umfang

- Acht Fragetypen, die den Aufgabenformen einer IHK-Prüfung entsprechen
- Wiederholungsplanung nach FSRS 4.5
- Konfidenzabfrage vor dem Aufdecken, samt Kalibrierungs-Auswertung
- Verkürztes Intervall bei hochkonfident falschen Antworten
- Gezielter Modus für genau diese Fehlerquellen
- Testläufe auf Zeit, ohne Einfluss auf die Wiederholungsplanung
- Freitext-Dialog fürs Fachgespräch, Bewertung über Schlüsselbegriffe
- Import eigener Lernpakete, Lernfortschritt je Kurs getrennt
- Sicherung und Wiederherstellung des Lernstands als Datei
- Vollständig offline

## Nicht im Umfang

Bewusst weggelassen, mit Begründung:

| Nicht enthalten | Warum |
|---|---|
| Konto und Cloud-Sync | Erzwingt Serverbetrieb, Datenschutzfragen und Internetzwang für eine App, die keins davon braucht. Übertragung läuft über die Backup-Datei. |
| Bestenlisten, Punkte, Serien | Belohnt tägliches Antippen statt Behalten — und kollidiert mit einem Verfahren, das bewusst Pausen einplant. |
| Fragen-Editor in der App | Pakete entstehen am Rechner, wo sich Text bequemer schreiben lässt. Das Format ist schlicht genug, dass eine KI ein Paket erzeugen kann. |
| Automatische Korrektur von Freitext per KI | Bräuchte eine Internetverbindung und würde Fehlurteile fällen, die der Lernende nicht überprüfen kann. Schlüsselbegriffe sind nachvollziehbar. |
| Werbung, In-App-Käufe | Kein Geschäftsmodell nötig. |

## Release-Kriterien

**Technisch**

- `flutter analyze` ohne Befund
- Alle Tests grün
- `dart run tool/validate_fragen.dart` ohne Fehler
- Release-Build mit dem Upload-Keystore signiert und auf einem echten Gerät
  durchgespielt — R8-Fehler zeigen sich nur dort

**Inhaltlich**

- Keine Frage im Bestand, die sich nicht beantworten lässt. Fehlende
  Prüfungszeichnungen brauchen mindestens eine Stückliste als Textersatz.
- Keine offene Frage aus `REVIEW_OFFEN.md`, bei der ein *falscher* Wert
  gelernt werden könnte.
- Keine `multi`-Frage, bei der fast alle Optionen richtig sind — die
  trainiert Raten statt Wissen.

**Für den Store**

- Datenschutzerklärung öffentlich erreichbar
- Data-Safety-Formular ausgefüllt
- Eigenes Icon, Screenshots, Beschreibungen

Vollständige Liste in [`release-checklist.md`](release-checklist.md).
