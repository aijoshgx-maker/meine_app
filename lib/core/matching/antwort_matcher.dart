// Zentrale Textnormalisierung/-Vergleich für Kurzantwort, Lückentext und
// Fachgespräch-Schlüsselwörter. Ziel: Der Nutzer weiß es richtig, tippt es
// richtig, und die App sagt trotzdem falsch - siehe P7 in
// CLAUDE_CODE_PROMPTS.md.
class AntwortMatcher {
  const AntwortMatcher._();

  /// Normalisiert einen Text für den Vergleich:
  /// - Groß-/Kleinschreibung ignorieren
  /// - Umlaute äöü→aeoeue, ß→ss (beidseitig: "Hoechstmass" und "Höchstmaß"
  ///   landen auf demselben normalisierten String)
  /// - führende/folgende Leerzeichen weg, Mehrfach-Leerzeichen auf eines
  /// - Bindestriche und Schrägstriche als Leerzeichen behandeln
  ///   ("Lockout Tagout" == "Lockout-Tagout" == "Lockout/Tagout")
  /// - Dezimaltrennzeichen , und . zwischen Ziffern vereinheitlicht
  static String normalisieren(String text) {
    var t = text.trim().toLowerCase();
    t = t
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    t = t.replaceAll(RegExp(r'[-/]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAllMapped(RegExp(r'(\d)[.,](\d)'), (m) => '${m[1]},${m[2]}');
    return t;
  }

  /// Exakter Vergleich nach Normalisierung.
  static bool passtGenau(String eingabe, String akzeptiert) =>
      normalisieren(eingabe) == normalisieren(akzeptiert);

  /// Prüft [eingabe] gegen eine Liste akzeptierter Varianten.
  static bool passtGegenListe(String eingabe, List<String> akzeptiert) =>
      akzeptiert.any((a) => passtGenau(eingabe, a));

  /// Tippfehler-tolerantes Matching: nur für Wörter länger als 6 Zeichen
  /// (nach Normalisierung), Levenshtein-Distanz höchstens 1. Bewusst nicht
  /// als Standard aktiviert (siehe antwort_matcher_test.dart für die
  /// Kollisions-Prüfung gegen den gesamten Fragenpool) - nur nutzen, wo
  /// vorher geprüft wurde, dass keine zwei fachlich unterschiedlichen
  /// Begriffe im selben Kontext eine Distanz <= 1 haben (z.B. "Festlager"/
  /// "Loslager" wäre bei zu laxer Anwendung fatal).
  static bool passtMitTippfehlertoleranz(String eingabe, String akzeptiert) {
    final e = normalisieren(eingabe);
    final a = normalisieren(akzeptiert);
    if (e == a) return true;
    if (e.length <= 6 || a.length <= 6) return false;
    return levenshtein(e, a) <= 1;
  }

  /// Klassische Editierdistanz (Einfügen/Löschen/Ersetzen je 1).
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var vorherige = List<int>.generate(b.length + 1, (i) => i);
    var aktuelle = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      aktuelle[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final kosten = a[i] == b[j] ? 0 : 1;
        aktuelle[j + 1] = [
          aktuelle[j] + 1, // Einfügen
          vorherige[j + 1] + 1, // Löschen
          vorherige[j] + kosten, // Ersetzen
        ].reduce((x, y) => x < y ? x : y);
      }
      final tausch = vorherige;
      vorherige = aktuelle;
      aktuelle = tausch;
    }
    return vorherige[b.length];
  }

  /// Zerlegt einen Text nach Normalisierung in Wort-Tokens (für
  /// Mehrwort-Schlüsselwort-Matching). Satzzeichen (auch Kommas aus
  /// normalem Fließtext, z.B. "dämpfen,") trennen Tokens; da beide Seiten
  /// eines Vergleichs denselben Tokenizer durchlaufen, bleibt ein
  /// Dezimalkomma wie in "0,02" trotzdem konsistent vergleichbar (wird auf
  /// beiden Seiten gleich in "0"/"02" aufgeteilt).
  static Set<String> tokenisieren(String text) => normalisieren(
    text,
  ).split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toSet();

  /// Prüft, ob [schluesselwort] in [text] gefunden wird - tokenweise: alle
  /// Wörter des Schlüsselworts müssen als eigene Tokens in [text] vorkommen
  /// (Reihenfolge egal), statt als reiner Teilstring. Verhindert sowohl
  /// Falsch-Negative bei Mehrwort-Phrasen mit anderer Wortstellung als auch
  /// zufällige Teilstring-Treffer in unrelated Wörtern.
  static bool keywordGefunden(String text, String schluesselwort) {
    final keywordTokens = tokenisieren(schluesselwort);
    if (keywordTokens.isEmpty) return false;
    final textTokens = tokenisieren(text);
    return keywordTokens.every(textTokens.contains);
  }
}
