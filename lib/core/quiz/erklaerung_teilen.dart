/// Teilt eine Erklärung in eine knappe Kurzfassung und den Rest.
///
/// Hintergrund: Die Erklärungen im Bestand sind im Median 280 Zeichen lang,
/// 257 von 681 liegen über 300. Auf einem Handy ist das nach dem Aufdecken
/// eine Wand aus Text — genau in dem Moment, in dem man nur wissen will, ob
/// man richtig lag und warum.
///
/// Die Kurzfassung wird abgeleitet statt gepflegt: Ein zusätzliches
/// Pflichtfeld müsste für alle 681 Fragen von Hand geschrieben werden, die
/// Ableitung wirkt sofort im ganzen Bestand. Wer es genauer will, setzt
/// `kurzerklaerung` an der Frage — das gewinnt dann.
library;

/// Obergrenze für die Kurzfassung.
///
/// Es werden so viele ganze Sätze genommen, wie darunter passen - mindestens
/// aber einer. Eine Untergrenze wäre hier falsch: Endet der erste Satz schon
/// nach 70 Zeichen, ist das eine gute Kurzfassung. Sie zu verwerfen hieße,
/// mitten im zweiten Satz abzuschneiden.
const _maxLaenge = 180;

/// Nur für den Notfall (Text ganz ohne Satzzeichen): So weit wird
/// mindestens gegangen, bevor am Wort getrennt wird.
const _mindestLaenge = 80;

/// Ergebnis der Aufteilung.
class GeteilteErklaerung {
  /// Immer gefüllt (sofern der Text nicht leer ist).
  final String kurz;

  /// Der Rest, oder leer wenn die Erklärung ohnehin knapp war.
  final String rest;

  const GeteilteErklaerung({required this.kurz, required this.rest});

  /// Ob es überhaupt etwas aufzuklappen gibt.
  bool get hatMehr => rest.isNotEmpty;
}

/// Zerlegt [erklaerung] in Kurzfassung und Rest.
///
/// [kurzerklaerung] hat Vorrang: Ist sie gesetzt, bildet sie die
/// Kurzfassung und die vollständige Erklärung wandert in den Rest.
GeteilteErklaerung teileErklaerung(
  String erklaerung, {
  String? kurzerklaerung,
}) {
  final voll = erklaerung.trim();

  final vorgabe = kurzerklaerung?.trim();
  if (vorgabe != null && vorgabe.isNotEmpty) {
    // Der Rest entfällt, wenn die Vorgabe ohnehin schon alles sagt.
    return GeteilteErklaerung(kurz: vorgabe, rest: voll == vorgabe ? '' : voll);
  }

  if (voll.length <= _maxLaenge) {
    return GeteilteErklaerung(kurz: voll, rest: '');
  }

  final schnitt = _satzGrenze(voll);
  if (schnitt == null) {
    // Kein brauchbarer Satzabschluss in Reichweite: Lieber am Wort trennen
    // als mitten hinein.
    final wortSchnitt = _wortGrenze(voll, _maxLaenge);
    return GeteilteErklaerung(
      kurz: '${voll.substring(0, wortSchnitt).trimRight()}…',
      rest: voll,
    );
  }

  return GeteilteErklaerung(
    kurz: voll.substring(0, schnitt).trim(),
    rest: voll.substring(schnitt).trim(),
  );
}

/// Position hinter dem letzten Satzzeichen, das noch ins Fenster passt -
/// also so viele ganze Sätze wie möglich. Null, wenn es keines gibt.
int? _satzGrenze(String text) {
  final grenze = text.length < _maxLaenge ? text.length : _maxLaenge;
  int? letzte;

  for (var i = 0; i < grenze; i++) {
    if (!'.!?'.contains(text[i])) continue;

    // Auf ein Satzzeichen muss ein Leerzeichen folgen - sonst trifft es
    // Dezimalzahlen ("1,6 mm" ist kein Problem, aber "z.B." und "Ø32.5"
    // schon) und Abkürzungen mitten im Satz.
    if (i + 1 < text.length && text[i + 1] != ' ') continue;

    // Abkürzungen wie "z.B." oder "ca." enden nicht den Satz: Nach dem
    // Leerzeichen müsste ein Großbuchstabe folgen.
    if (i + 2 < text.length) {
      final naechstes = text[i + 2];
      if (naechstes != naechstes.toUpperCase()) continue;
    }

    letzte = i + 1;
  }
  return letzte;
}

/// Letzte Wortgrenze vor [maximum].
int _wortGrenze(String text, int maximum) {
  final grenze = text.length < maximum ? text.length : maximum;
  for (var i = grenze - 1; i > _mindestLaenge; i--) {
    if (text[i] == ' ') return i;
  }
  return grenze;
}
