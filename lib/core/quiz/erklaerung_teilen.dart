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

/// Ab wie vielen Zeichen sich das Aufklappen überhaupt lohnt.
///
/// Liefert "Ausführlich" nur noch einen halben Satz nach, ist der Knopf
/// Beschäftigung ohne Ertrag. Und wo gar keine Satzgrenze gefunden wird,
/// verdoppelt ein Schnitt kurz vor Schluss den Text praktisch - genau das
/// war in der App zu sehen: Der Aufklapper lieferte 40 Zeichen nach und
/// wiederholte dafür 177.
const _mindestGewinn = 60;

/// Ergebnis der Aufteilung.
class GeteilteErklaerung {
  /// Immer gefüllt (sofern der Text nicht leer ist).
  final String kurz;

  /// Der Rest, oder leer wenn die Erklärung ohnehin knapp war.
  final String rest;

  /// Der ungeteilte Text - das, was beim Aufklappen zu lesen ist.
  ///
  /// Bewusst ein eigenes Feld und nicht "kurz + rest": Wo am Wort getrennt
  /// wurde, endet [kurz] mit einem Auslassungszeichen und [rest] trägt
  /// bereits den ganzen Text.
  final String vollstaendig;

  const GeteilteErklaerung({
    required this.kurz,
    required this.rest,
    required this.vollstaendig,
  });

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
    return GeteilteErklaerung(
      kurz: vorgabe,
      rest: voll == vorgabe ? '' : voll,
      vollstaendig: voll,
    );
  }

  if (voll.length <= _maxLaenge) {
    return GeteilteErklaerung(kurz: voll, rest: '', vollstaendig: voll);
  }

  // Erst der echte Satzabschluss, dann Doppelpunkt und Semikolon. Der
  // Bestand ist voller Aufzählungen der Form "FMEA: Fehler, Ursache,
  // Wirkung." - ohne die zweite Stufe fänden die gar keine Grenze.
  final schnitt =
      _grenze(voll, '.!?', verlangeGrossbuchstabe: true) ??
      _grenze(voll, ':;', verlangeGrossbuchstabe: false, mindestens: _mindestLaenge);

  if (schnitt != null) {
    if (voll.length - schnitt < _mindestGewinn) {
      return GeteilteErklaerung(kurz: voll, rest: '', vollstaendig: voll);
    }
    return GeteilteErklaerung(
      kurz: voll.substring(0, schnitt).trim(),
      rest: voll.substring(schnitt).trim(),
      vollstaendig: voll,
    );
  }

  // Kein brauchbarer Satzabschluss in Reichweite: Lieber am Wort trennen
  // als mitten hinein.
  final wortSchnitt = _wortGrenze(voll, _maxLaenge);
  if (voll.length - wortSchnitt < _mindestGewinn) {
    return GeteilteErklaerung(kurz: voll, rest: '', vollstaendig: voll);
  }
  return GeteilteErklaerung(
    kurz: '${voll.substring(0, wortSchnitt).trimRight()}…',
    rest: voll,
    vollstaendig: voll,
  );
}

/// Position hinter dem letzten Trennzeichen aus [zeichen], das noch ins
/// Fenster passt - also so viel ganzer Text wie möglich. Null, wenn es
/// keines gibt.
int? _grenze(
  String text,
  String zeichen, {
  required bool verlangeGrossbuchstabe,
  int mindestens = 0,
}) {
  final grenze = text.length < _maxLaenge ? text.length : _maxLaenge;
  int? letzte;

  for (var i = mindestens; i < grenze; i++) {
    if (!zeichen.contains(text[i])) continue;

    // Auf ein Satzzeichen muss ein Leerzeichen folgen - sonst trifft es
    // Dezimalzahlen ("1,6 mm" ist kein Problem, aber "z.B." und "Ø32.5"
    // schon) und Abkürzungen mitten im Satz.
    if (i + 1 < text.length && text[i + 1] != ' ') continue;

    // Abkürzungen wie "z.B." oder "ca." enden nicht den Satz: Nach dem
    // Leerzeichen müsste ein Großbuchstabe folgen. Nach einem Doppelpunkt
    // gilt das nicht - dort geht es im Deutschen klein weiter.
    if (verlangeGrossbuchstabe && i + 2 < text.length) {
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
