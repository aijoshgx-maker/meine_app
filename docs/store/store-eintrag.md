# Play-Store-Eintrag — Entwürfe

> **Der App-Name steht noch aus.** Überall dort, wo `{{NAME}}` steht, kommt er
> später hinein. Die Zeichenzahlen sind jeweils ohne den Namen gerechnet, es
> bleibt also Luft.

## Kurzbeschreibung (max. 80 Zeichen)

```
Karteikarten mit Wiederholungsplanung — eigene Lernthemen importierbar.
```
*70 Zeichen*

Alternative, stärker auf den mitgelieferten Kurs bezogen:

```
AP2 Industriemechaniker lernen — mit Wiederholungsplanung, komplett offline.
```
*75 Zeichen*

## Vollbeschreibung (max. 4000 Zeichen)

```
{{NAME}} ist ein Lernkarten-Trainer, der sich merkt, wann du was wiederholen
solltest — und der nicht auf ein einziges Thema festgelegt ist.

MITGELIEFERT: ABSCHLUSSPRÜFUNG TEIL 2 INDUSTRIEMECHANIKER

681 Fragen aus Auftrags- und Funktionsanalyse, Fertigungstechnik sowie
Wirtschafts- und Sozialkunde. Dazu Fragen aus vier echten IHK-Prüfungen und
38 Szenarien fürs Fachgespräch.

ACHT FRAGETYPEN

Single- und Mehrfachauswahl, Wahr/Falsch, Rechenaufgaben mit Toleranz,
Kurzantworten, Lückentexte, Zuordnungen und Reihenfolgen. Rechenaufgaben
zeigen auf Wunsch den kompletten Lösungsweg.

WIEDERHOLUNG, DIE MITDENKT

Die App nutzt FSRS — ein Verfahren, das den Wiederholungszeitpunkt aus deinem
tatsächlichen Antwortverhalten berechnet. Was sitzt, kommt seltener. Was
wackelt, kommt früher wieder.

Eine Besonderheit: Wenn du dir bei einer Antwort sicher warst und trotzdem
falsch lagst, verkürzt die App das Intervall zusätzlich. Genau solche
Irrtümer bleiben sonst am hartnäckigsten hängen.

SIEH, WO DU STEHST

Behaltensquote mit 30-Tage-Verlauf, Lernstand je Themenbereich, deine
schwächsten Themen — und eine Kalibrierung, die zeigt, wie gut deine
Selbsteinschätzung zur tatsächlichen Trefferquote passt.

PRÜFUNG AUF ZEIT

Testläufe mit echtem Zeitlimit, Pausenfunktion und Zugriff auf die
zugehörigen Zeichnungen. Ohne Bewertung und ohne Einfluss auf die
Wiederholungsplanung — reine Standortbestimmung.

EIGENE THEMEN LADEN

Du bist nicht auf den mitgelieferten Kurs angewiesen. Lernpakete lassen sich
als Datei importieren: Vokabeln, Fachbegriffe, Prüfungsstoff — was du
brauchst. Jeder Kurs führt seinen Lernfortschritt getrennt, du kannst also
zwischen Themen wechseln, ohne dass sich etwas vermischt.

Das Format ist dokumentiert und bewusst schlicht gehalten, damit sich Pakete
auch selbst erstellen lassen.

KOMPLETT OFFLINE

Kein Konto, keine Registrierung, keine Werbung, kein Tracking. Die App
fordert nicht einmal die Berechtigung für Internetzugriff an. Dein
Lernfortschritt bleibt auf deinem Gerät — und lässt sich als Datei sichern
und auf ein neues Gerät übertragen.
```
*ca. 1950 Zeichen*

## Grafiken

| Element | Vorgabe | Stand |
|---|---|---|
| App-Icon | 512×512, PNG, ohne Alpha | `assets/branding/play_store_icon_512.png` |
| Feature-Grafik | 1024×500 | `assets/branding/play_feature_graphic.png` |
| Screenshots Handy | mind. 2, 16:9 bis 2:1 | **fehlen** |
| Screenshots Tablet | optional | **fehlen** |

Vorschlag für die Screenshots, in dieser Reihenfolge: Dashboard mit den
Auswertungen · eine Frage in der Aufdeckung mit Erklärung · die
Themenauswahl · die Kursverwaltung mit zwei Kursen · ein Testlauf mit
laufendem Timer.

## Data Safety — Antworten für den Fragebogen

| Frage | Antwort |
|---|---|
| Werden Daten erhoben oder geteilt? | **Nein** |
| Verschlüsselung bei Übertragung? | entfällt — keine Übertragung |
| Können Nutzer Löschung verlangen? | Daten liegen nur lokal; Deinstallation löscht alles |
| Zielgruppe | Erwachsene und Auszubildende |
| Enthält Werbung? | Nein |
| In-App-Käufe? | Nein |

Belege dafür, falls nachgefragt wird: Es gibt keine `INTERNET`-Berechtigung im
Manifest, und die einzigen Abhängigkeiten mit Netzwerkbezug sind keine
vorhanden — die App nutzt Hive (lokal), share_plus und file_selector (beide
nur auf Nutzeraktion).

## Inhaltsbewertung

Reine Lern-App ohne Gewalt, ohne Nutzerinteraktion untereinander, ohne
Standortbezug, ohne Käufe. Der Fragebogen sollte auf die niedrigste
Altersfreigabe hinauslaufen.
