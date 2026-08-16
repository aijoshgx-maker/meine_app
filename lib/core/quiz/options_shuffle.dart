import 'dart:math';

// Berechnet pro Frage-Anzeige eine neue Zufallsreihenfolge für Optionen
// (single/multi, Zuordnung rechte Spalte, reihenfolge-Startanordnung).
// Ziel: verhindert, dass Lernende die Position der richtigen Antwort statt
// des Inhalts lernen (siehe P6b in CLAUDE_CODE_PROMPTS.md).
//
// Wichtig: Der zugrunde liegende Frage-Zustand (richtigeIndizes, paare,
// reihenfolge) bleibt immer in Original-Index-Reihenfolge - nur die
// *Anzeige* wird gemischt. Aufrufer geben beim Auswählen weiterhin den
// Original-Index zurück, damit die Bewertungslogik unverändert bleibt.

/// Textmuster für Optionen, die sich inhaltlich auf "alle/keine der
/// übrigen Optionen" beziehen und deshalb nie durch Shuffle verschoben
/// werden dürfen - ihre Bedeutung hängt von den anderen Optionen ab, nicht
/// von ihrer Position, aber Nutzer erwarten sie an fester Stelle (meist am
/// Ende der Liste).
const _ankerMuster = [
  'keine der genannten',
  'keine der aufgeführten',
  'keine antwort ist richtig',
  'alle antworten sind richtig',
  'alle genannten antworten sind richtig',
];

bool istAnkerOptionstext(String text) {
  final normalisiert = text.trim().toLowerCase();
  return _ankerMuster.any(normalisiert.contains);
}

/// Berechnet eine Zufalls-Anzeigereihenfolge für [anzahl] Elemente
/// (Original-Indizes 0..anzahl-1). Elemente, für die [istAnker] true
/// liefert, bleiben an ihrer ursprünglichen Position stehen.
///
/// Rückgabe: Liste der Länge [anzahl], an Anzeigeposition i steht der
/// Original-Index des dort zu zeigenden Elements.
List<int> berechneAnzeigeReihenfolge(
  int anzahl,
  Random zufall, {
  bool Function(int originalIndex)? istAnker,
}) {
  if (anzahl <= 1) return List.generate(anzahl, (i) => i);

  final ankerPositionen = <int>{
    if (istAnker != null)
      for (var i = 0; i < anzahl; i++)
        if (istAnker(i)) i,
  };
  final bewegliche = [
    for (var i = 0; i < anzahl; i++)
      if (!ankerPositionen.contains(i)) i,
  ]..shuffle(zufall);

  final ergebnis = List<int>.filled(anzahl, -1);
  var zeiger = 0;
  for (var i = 0; i < anzahl; i++) {
    ergebnis[i] = ankerPositionen.contains(i) ? i : bewegliche[zeiger++];
  }
  return ergebnis;
}
