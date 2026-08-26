// Laesst eine Frage mit dem Koennen mitwachsen.
//
// Eine Frage, die man dreimal sicher richtig beantwortet hat, ist als
// Auswahlfrage keine Pruefung mehr - man erkennt die richtige Option wieder,
// statt die Antwort abzurufen. Ab einem gewissen Zaehlerstand wird deshalb
// eine haertere Fassung gestellt, und zwar STATT der leichten.
//
// Wie bei den Varianten gilt: Das Ergebnis ist eine gewoehnliche [Frage] mit
// derselben ID. Bewertung, Aufdeckung, Statistik und FSRS laufen unveraendert
// weiter, der Lernfortschritt bleibt heil.
//
// Erprobung - haengt am Schalter "Steigende Schwierigkeit" in den
// Einstellungen und laesst sich mit dieser Datei wieder entfernen.
library;

import 'package:meine_app/models/frage.dart';

/// Wie hart eine Frage gestellt wird.
enum Haertegrad {
  /// Wie im Fragenbestand hinterlegt.
  normal,

  /// Ohne den Tipp-Knopf. Er erklaert Formelzeichen und Begriffe vor dem
  /// Antworten - genau die Stuetze, die man irgendwann nicht mehr braucht.
  ohneTipps,

  /// Abrufen statt Wiedererkennen: Die Frage selbst wird haerter, soweit ihr
  /// Typ das hergibt (siehe [haerteFrage]).
  freierAbruf,
}

/// Ab wann Stufe 1 gilt.
const int schwelleOhneTipps = 2;

/// Ab wann Stufe 2 gilt.
const int schwelleFreierAbruf = 4;

/// Der Haertegrad zu einem Zaehlerstand.
Haertegrad haertegradVon(int sicherRichtigInFolge) {
  if (sicherRichtigInFolge >= schwelleFreierAbruf) return Haertegrad.freierAbruf;
  if (sicherRichtigInFolge >= schwelleOhneTipps) return Haertegrad.ohneTipps;
  return Haertegrad.normal;
}

/// Schreibt den Zaehler nach einer Antwort fort.
///
/// Nur sicher UND richtig zaehlt hoch. Eine richtige, aber unsichere Antwort
/// laesst den Stand stehen: Sie beweist nicht, dass die leichte Fassung schon
/// zu leicht ist.
///
/// Eine falsche Antwort stuft um genau eine Stufe zurueck, nicht auf null.
/// Wer an der freien Antwort einmal scheitert, soll sie in der Auswahlform
/// wiedersehen - aber nicht bei jedem Patzer den ganzen Weg neu gehen.
int naechsterZaehler(
  int bisher, {
  required bool korrekt,
  required bool sicher,
}) {
  if (!korrekt) {
    if (bisher >= schwelleFreierAbruf) return schwelleOhneTipps;
    return 0;
  }
  if (!sicher) return bisher;
  return bisher + 1;
}

/// Ob sich [frage] ohne ihre Optionen stellen laesst.
///
/// Verlangt das gepflegte Feld `freieAntwort` und laesst sich bewusst nicht
/// aus dem Optionstext ableiten: "Reed-Kontakt" taugt als freie Antwort,
/// "Ja, fuer 9 Monate" nicht. Geraten waere die harte Fassung an manchen
/// Fragen schlicht unloesbar.
bool kannFreierAbruf(Frage frage) =>
    frage.typ == 'single' && frage.freieAntwort.isNotEmpty;

/// Liefert [frage] in der zu [grad] passenden Fassung.
///
/// Aendert nur den Inhalt der Frage. Was allein die Darstellung betrifft -
/// Tipp-Knopf, Einheitshinweis, Stufenabzeichen - steuert der Haertegrad in
/// der Oberflaeche; so bleibt [Frage] ein reines Datenmodell.
///
/// Fuer `wahrfalsch`, `multi`, `zuordnung`, `reihenfolge`, `lueckentext` und
/// `kurzantwort` gibt es hier (noch) keine haertere Fassung: Die einen sind
/// bereits Abrufaufgaben, die anderen liessen sich ohne neue Inhalte nicht
/// verschaerfen. Sie kommen unveraendert zurueck.
Frage haerteFrage(Frage frage, Haertegrad grad) {
  if (grad != Haertegrad.freierAbruf) return frage;
  if (!kannFreierAbruf(frage)) return frage;

  // Aus der Auswahlfrage wird eine Kurzantwort-Frage. Die Optionen fallen
  // weg, damit die Oberflaeche gar nicht erst in Versuchung kommt, sie zu
  // zeigen - der Fragetyp allein entscheidet ueber die Eingabe.
  //
  // Der Wortlaut der richtigen Option gilt immer mit, ohne dass er in den
  // Daten wiederholt werden muss: Wer sich an ihn erinnert, hat die Frage
  // beantwortet. `freieAntwort` traegt nur die kuerzeren und die
  // gleichwertigen Formulierungen nach.
  return frage.copyWith(
    typ: 'kurzantwort',
    optionen: const [],
    akzeptierteKurzantworten: [
      ...frage.freieAntwort,
      for (final i in frage.richtigeIndizes)
        if (i >= 0 && i < frage.optionen.length) frage.optionen[i],
    ],
  );
}
