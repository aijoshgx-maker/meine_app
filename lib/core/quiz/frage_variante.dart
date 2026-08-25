// Macht aus einer Variantenbeschreibung eine gewöhnliche Frage.
//
// Der entscheidende Punkt: Das Ergebnis ist eine normale [Frage]. Bewertung,
// Aufdeckung, Lösungsweg, Statistik und FSRS laufen unverändert weiter, und
// der Lernfortschritt bleibt heil - die Karte hängt an der ID, und die
// ändert sich nicht.
library;

import 'dart:math';

import 'package:meine_app/core/formel/formel.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/frage_varianten.dart';

/// Fehler in einer Variantenbeschreibung aus den Fragendaten.
class VariantenException implements Exception {
  final String frageId;
  final String nachricht;

  const VariantenException(this.frageId, this.nachricht);

  @override
  String toString() => 'VariantenException [$frageId]: $nachricht';
}

/// Liefert [frage] mit gewürfelten Werten.
///
/// Ohne Variantenbeschreibung kommt die Frage unverändert zurück - das ist
/// der Normalfall und betrifft alle Fragen, die einen festen Merksatz
/// abfragen.
///
/// Mit [originalwerte] werden statt gewürfelter Zahlen die in `original`
/// hinterlegten eingesetzt. Der Testlauf nutzt das: Dort ist der
/// authentische Prüfungsbogen der Zweck.
Frage wuerfleVariante(
  Frage frage,
  Random zufall, {
  bool originalwerte = false,
}) {
  final varianten = frage.varianten;
  if (varianten == null) return frage;

  final werte = originalwerte ? varianten.original : varianten.ziehe(zufall);
  return baueVariante(frage, werte);
}

/// Baut die Variante zu einem konkreten Wertesatz.
///
/// Getrennt von [wuerfleVariante], damit der Validator jede Frage mit ihren
/// Originalwerten nachrechnen kann.
Frage baueVariante(Frage frage, Map<String, Object> werte) {
  final varianten = frage.varianten;
  if (varianten == null) return frage;

  final zahlen = <String, double>{
    for (final e in werte.entries)
      if (e.value is num) e.key: (e.value as num).toDouble(),
  };
  final texte = <String, String>{
    for (final e in werte.entries)
      e.key: e.value is num
          ? _deutsch(
              (e.value as num).toDouble(),
              varianten.stellen[e.key] ?? _maxZwischenstellen,
              nullenBehalten: varianten.stellen.containsKey(e.key),
            )
          : e.value.toString(),
  };

  // Zwischenergebnisse in der Reihenfolge, in der sie stehen - ein späterer
  // Schritt darf auf einen früheren zugreifen.
  for (final e in varianten.zwischen.entries) {
    final wert = _rechne(frage.id, e.value, zahlen);
    zahlen[e.key] = wert;
    texte[e.key] = _deutsch(wert, _maxZwischenstellen);
  }

  double? loesungswert;
  double? toleranz;
  if (varianten.loesung != null) {
    final roh = _rechne(frage.id, varianten.loesung!, zahlen);
    loesungswert = _runde(roh, varianten.rundung);
    zahlen['loesung'] = loesungswert;
    texte['loesung'] = _deutsch(loesungswert, varianten.rundung);
    toleranz = _toleranz(varianten, loesungswert, frage.toleranz);
  }

  String? ersetze(String? vorlage) =>
      vorlage == null ? null : _ersetze(frage.id, vorlage, texte);

  return frage.copyWith(
    frage: ersetze(varianten.frage),
    erklaerung: ersetze(varianten.erklaerung),
    workedExample: ersetze(varianten.workedExample),
    loesungswert: loesungswert,
    toleranz: toleranz,
    akzeptierteKurzantworten: varianten.akzeptierteKurzantworten.isEmpty
        ? null
        : [
            for (final a in varianten.akzeptierteKurzantworten)
              _ersetze(frage.id, a, texte),
          ],
    luecken: varianten.luecken.isEmpty
        ? null
        : [
            for (final luecke in varianten.luecken)
              [for (final a in luecke) _ersetze(frage.id, a, texte)],
          ],
  );
}

/// Nachkommastellen für Zwischenschritte und eingesetzte Werte.
///
/// Vier reichen für die Lösungswege im Bestand ("24,167", "151,84") und
/// halten Rundungsstaub aus der Anzeige. Wer es genauer braucht, rundet in
/// der Formel selbst - `round(x*100)/100`.
const _maxZwischenstellen = 4;

double _rechne(String frageId, String formel, Map<String, double> werte) {
  try {
    return werteAus(formel, werte);
  } on FormelException catch (e) {
    throw VariantenException(frageId, e.nachricht);
  }
}

double _runde(double wert, int stellen) {
  final faktor = pow(10, stellen);
  return (wert * faktor).round() / faktor;
}

/// Toleranz zum gerundeten Lösungswert.
///
/// Bei gewürfelten Zahlen ist eine feste Toleranz schief: 10 W sind bei
/// 5314 W großzügig und bei 200 W streng. Die Untergrenze fängt die
/// Rundung selbst ab - wer den auf zwei Stellen gerundeten Wert eintippt,
/// darf daran nicht scheitern.
double _toleranz(FrageVarianten varianten, double loesung, double? fallback) {
  final rundungsSpielraum = 0.5 / pow(10, varianten.rundung);
  final prozent = varianten.toleranzProzent;
  if (prozent == null) return fallback ?? rundungsSpielraum;
  final skaliert = max(loesung.abs() * prozent / 100, rundungsSpielraum);
  // Ohne das Nachrunden stünde in der Frage eine Toleranz von
  // 0,7059000000000001 - Gleitkommastaub, der nirgends hingehört.
  return _runde(skaliert, varianten.rundung + 4);
}

final _platzhalter = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}');

String _ersetze(String frageId, String vorlage, Map<String, String> werte) {
  return vorlage.replaceAllMapped(_platzhalter, (treffer) {
    final name = treffer.group(1)!;
    final wert = werte[name];
    if (wert == null) {
      throw VariantenException(frageId, 'Platzhalter {$name} ist nicht belegt');
    }
    return wert;
  });
}

/// Deutsche Zahlschreibweise, ohne nachlaufende Nullen.
///
/// 5.5 → "5,5", 40.0 → "40", 106.666… → "106,67".
String _deutsch(double wert, int maxStellen, {bool nullenBehalten = false}) {
  var text = wert.toStringAsFixed(maxStellen);
  if (!nullenBehalten && text.contains('.')) {
    text = text.replaceAll(RegExp(r'0+$'), '');
    text = text.replaceAll(RegExp(r'\.$'), '');
  }
  return text.replaceAll('.', ',');
}
