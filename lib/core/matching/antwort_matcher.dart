// Zentrale Textnormalisierung/-Vergleich für Kurzantwort, Lückentext und
// Fachgespräch-Schlüsselwörter. Ziel: Der Nutzer weiß es richtig, tippt es
// richtig, und die App sagt trotzdem falsch - siehe P7 in
// CLAUDE_CODE_PROMPTS.md.
//
// Der Vergleich läuft in drei Stufen, von streng nach nachsichtig. Jede
// Stufe greift erst, wenn die vorige nicht gepasst hat:
//
//   1. normalisierte Zeichenkette   "Höchstmaß" == "hoechstmass"
//   2. Menge der Teilantworten      "A, B" == "B und A"
//   3. dieselbe Menge, gestammt     "Gewerkschaften" == "Gewerkschaft"
//
// Stufe 3 ist bewusst eng gefasst (siehe [_wortStamm]): In einer Lern-App ist
// ein zu Unrecht anerkanntes "richtig" schädlicher als ein zu strenges
// "falsch", weil es einen Irrtum bestätigt.
class AntwortMatcher {
  const AntwortMatcher._();

  /// Ausgeschriebene Zahlen. Ohne sie müsste jede Frage ihre Zahlwort-
  /// Variante von Hand mitführen - im Bestand geschieht das 17-mal, und
  /// überall dort, wo es jemand vergessen hat, gilt eine richtige Antwort
  /// als falsch.
  ///
  /// "ein"/"eine" fehlen absichtlich: Das sind weit häufiger Artikel als
  /// Zahlwörter ("ein Festlager"), und aus ihnen eine 1 zu machen würde
  /// Antworten verstümmeln statt vereinheitlichen.
  static const _zahlwoerter = <String, String>{
    'null': '0',
    'eins': '1',
    'zwei': '2',
    'drei': '3',
    'vier': '4',
    'fuenf': '5',
    'sechs': '6',
    'sieben': '7',
    'acht': '8',
    'neun': '9',
    'zehn': '10',
    'elf': '11',
    'zwoelf': '12',
    'dreizehn': '13',
    'vierzehn': '14',
    'fuenfzehn': '15',
    'sechzehn': '16',
    'siebzehn': '17',
    'achtzehn': '18',
    'neunzehn': '19',
    'zwanzig': '20',
    'dreissig': '30',
    'vierzig': '40',
    'fuenfzig': '50',
    'sechzig': '60',
    'siebzig': '70',
    'achtzig': '80',
    'neunzig': '90',
    'hundert': '100',
  };

  /// Römische Ziffern - "Arbeitslosengeld II" und "Arbeitslosengeld 2"
  /// meinen dasselbe.
  ///
  /// Nur I bis IV. V, X, L, C, D und M sind im Fachbestand Einheiten und
  /// Kurzzeichen (230 V, °C, M8, 5 m) - sie in Zahlen zu verwandeln würde
  /// Antworten zerstören, statt sie zu vereinheitlichen.
  static const _roemisch = <String, String>{
    'i': '1',
    'ii': '2',
    'iii': '3',
    'iv': '4',
  };

  /// Trennt Aufzählungen in einer Antwort.
  ///
  /// Zwei Feinheiten, die beide aus dem Bestand stammen:
  /// - Das Komma trennt nur ohne folgende Ziffer, sonst zerfiele "38,0".
  /// - Das Plus braucht Leerzeichen ringsum, sonst zerfiele der
  ///   Wärmebehandlungs-Zusatz "+A" in ft-ww-011.
  static final _trenner = RegExp(
    r'\s+und\s+|\s+sowie\s+|\s*&\s*|\s+\+\s+|,(?!\d)',
  );

  /// Normalisiert einen Text für den Vergleich:
  /// - Groß-/Kleinschreibung ignorieren
  /// - Umlaute äöü→aeoeue, ß→ss (beidseitig: "Hoechstmass" und "Höchstmaß"
  ///   landen auf demselben normalisierten String)
  /// - führende/folgende Leerzeichen weg, Mehrfach-Leerzeichen auf eines
  /// - Bindestriche und Schrägstriche als Leerzeichen behandeln
  ///   ("Lockout Tagout" == "Lockout-Tagout" == "Lockout/Tagout")
  /// - Malzeichen ebenso: "v · A" == "v * A" == "v A". Das Zeichen · steht
  ///   auf keiner Handytastatur; wer es nicht findet, soll nicht an der
  ///   Schreibweise scheitern statt an der Formel.
  /// - Dezimaltrennzeichen , und . zwischen Ziffern vereinheitlicht
  /// - ausgeschriebene und römische Zahlen als Ziffern
  static String normalisieren(String text) {
    var t = text.trim().toLowerCase();
    t = t
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    t = t.replaceAll(RegExp(r'[-/·⋅×*]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAllMapped(RegExp(r'(\d)[.,](\d)'), (m) => '${m[1]},${m[2]}');
    // Wortweise, damit nur ganze Tokens ersetzt werden: "sieben" wird zur 7,
    // "siebenmal" bleibt unangetastet.
    t = t.replaceAllMapped(RegExp(r'[a-z]+'), (m) {
      final wort = m[0]!;
      return _zahlwoerter[wort] ?? _roemisch[wort] ?? wort;
    });
    return t;
  }

  /// Vergleich nach Normalisierung, Mengenvergleich und Wortstamm.
  ///
  /// Der Mengenvergleich macht Reihenfolge und Bindewort belanglos:
  /// "Gewerkschaften, Arbeitgeber" trifft "Gewerkschaft und Arbeitgeber".
  static bool passtGenau(String eingabe, String akzeptiert) {
    if (normalisieren(eingabe) == normalisieren(akzeptiert)) return true;

    final e = teileAntwort(eingabe);
    final a = teileAntwort(akzeptiert);
    if (e.isEmpty || a.isEmpty) return false;
    if (_mengeGleich(e, a)) return true;
    return _mengeGleich(e.map(_teilStamm).toSet(), a.map(_teilStamm).toSet());
  }

  /// Zerlegt eine Antwort in ihre Teilantworten (siehe [_trenner]).
  static Set<String> teileAntwort(String text) => normalisieren(text)
      .split(_trenner)
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet();

  static bool _mengeGleich(Set<String> a, Set<String> b) =>
      a.length == b.length && a.every(b.contains);

  static String _teilStamm(String teil) =>
      teil.split(' ').map(_wortStamm).join(' ');

  /// Streicht deutsche Pluralendungen - aber nur bei langen Wörtern.
  ///
  /// Die Längenschwelle ist der eigentliche Schutz: "gewerkschaften" (14)
  /// wird auf "gewerkschaft" zurückgeführt, "haerten" (7) dagegen gar nicht.
  /// Damit bleiben Härte (Eigenschaft) und Härten (Verfahren) zwei
  /// verschiedene Antworten - eine Verwechslung, die eine Lern-App nicht
  /// durchgehen lassen darf.
  ///
  /// Immer die längste passende Endung, sonst würde "schleifen" über den
  /// Umweg -n zu "schleife" und fiele mit dem Bauteil zusammen.
  static String _wortStamm(String wort) {
    if (wort.length < 9) return wort;
    for (final endung in const ['en', 'n', 'e', 's']) {
      if (wort.endsWith(endung)) {
        return wort.substring(0, wort.length - endung.length);
      }
    }
    return wort;
  }

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
