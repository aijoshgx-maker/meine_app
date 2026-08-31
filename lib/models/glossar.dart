import '../core/matching/antwort_matcher.dart';

/// Ein erklärter Begriff oder Formelzeichen.
///
/// Zweck: Wer an einer Aufgabe hängt, weil ihm `ω` nichts sagt, hat keine
/// Wissenslücke im Thema — er kann die Frage nur nicht lesen. Diese
/// Unterscheidung ist wichtig, denn das eine löst Üben, das andere ein
/// Nachschlagewerk.
class GlossarEintrag {
  /// Wie der Begriff angezeigt wird, z.B. "ω (Winkelgeschwindigkeit)".
  final String begriff;

  /// Schreibweisen, unter denen er im Fragetext gefunden wird.
  ///
  /// Getrennt vom Anzeigenamen, weil beides selten übereinstimmt: Angezeigt
  /// wird "ω (Winkelgeschwindigkeit)", gefunden werden muss aber auch
  /// "omega" oder "Winkelgeschwindigkeit".
  final List<String> alias;

  /// Ein Satz, der erklärt, was gemeint ist.
  final String kurz;

  /// Die Formeln zu diesem Begriff - in Rohform, nicht umgestellt.
  ///
  /// Bewusst ein eigenes Feld und kein Fliesstext: So lassen sie sich in der
  /// Tippfunktion sammeln und als Liste zeigen, statt dass man sie sich aus
  /// einem Absatz heraussuchen muss.
  ///
  /// **Rohform heisst: die definierende Beziehung, nicht nach der gesuchten
  /// Groesse aufgeloest.** Bei einer Frage nach der Drehzahl steht hier
  /// `vc = π · d · n / 1000` - das Umstellen ist der Lernstoff und wird
  /// nicht abgenommen.
  final List<String> formeln;

  /// Optionale Vertiefung: Einheit, Abgrenzung zu Nachbarbegriffen.
  final String? mehr;

  const GlossarEintrag({
    required this.begriff,
    this.alias = const [],
    required this.kurz,
    this.formeln = const [],
    this.mehr,
  });

  factory GlossarEintrag.fromJson(Map<String, dynamic> json) => GlossarEintrag(
    begriff: json['begriff'] as String,
    alias: ((json['alias'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    kurz: json['kurz'] as String,
    formeln: ((json['formeln'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    mehr: json['mehr'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'begriff': begriff,
    if (alias.isNotEmpty) 'alias': alias,
    'kurz': kurz,
    if (formeln.isNotEmpty) 'formeln': formeln,
    if (mehr != null) 'mehr': mehr,
  };

  /// Alle Schreibweisen, unter denen dieser Eintrag zu finden ist.
  Iterable<String> get suchbegriffe => [begriff, ...alias];
}

/// Nachschlagewerk eines Kurses.
class Glossar {
  final List<GlossarEintrag> eintraege;

  const Glossar(this.eintraege);

  static const leer = Glossar([]);

  bool get istLeer => eintraege.isEmpty;

  factory Glossar.fromJson(List<dynamic> liste) => Glossar(
    liste
        .whereType<Map>()
        .map((e) => GlossarEintrag.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  List<Map<String, dynamic>> toJson() =>
      eintraege.map((e) => e.toJson()).toList();

  /// Einträge, deren Begriff in [text] vorkommt — in der Reihenfolge ihres
  /// ersten Auftretens im Text, damit die Liste der Leserichtung folgt.
  ///
  /// [ausnahmen] blendet einzelne Einträge aus. Das braucht es, wenn ein
  /// Hinweis die Frage verraten würde: Bei „Welche Einheit hat die
  /// Winkelgeschwindigkeit?" wäre der Eintrag dazu die Antwort.
  List<GlossarEintrag> findeIn(
    String text, {
    Set<String> ausnahmen = const {},
  }) {
    if (eintraege.isEmpty || text.trim().isEmpty) return const [];

    final normal = AntwortMatcher.normalisieren(text);
    final treffer = <(int, GlossarEintrag)>[];

    for (final eintrag in eintraege) {
      if (ausnahmen.contains(eintrag.begriff)) continue;

      int? frueheste;
      for (final suche in eintrag.suchbegriffe) {
        final pos = _findePosition(text, normal, suche);
        if (pos != null && (frueheste == null || pos < frueheste)) {
          frueheste = pos;
        }
      }
      if (frueheste != null) treffer.add((frueheste, eintrag));
    }

    treffer.sort((a, b) => a.$1.compareTo(b.$1));
    return treffer.map((t) => t.$2).toList();
  }

  /// Position des ersten Vorkommens, oder null.
  ///
  /// Formelzeichen wie `ω` oder `Ø` werden direkt gesucht — sie stehen oft
  /// an Zahlen und Klammern, eine Wortgrenze gibt es dort nicht. Wörter
  /// dagegen nur an Wortgrenzen, sonst würde „Kraft" auch in
  /// „Kraftstoffpumpe" anschlagen und die Liste zumüllen.
  int? _findePosition(String original, String normal, String suche) {
    if (suche.isEmpty) return null;

    if (_istZeichen(suche)) {
      final pos = original.indexOf(suche);
      return pos < 0 ? null : pos;
    }

    final gesucht = AntwortMatcher.normalisieren(suche);
    if (gesucht.isEmpty) return null;

    var ab = 0;
    while (true) {
      final pos = normal.indexOf(gesucht, ab);
      if (pos < 0) return null;
      if (_anWortgrenze(normal, pos, gesucht.length)) return pos;
      ab = pos + 1;
    }
  }

  /// Ob es sich um ein Symbol handelt statt um ein Wort.
  ///
  /// Symbole überleben die Normalisierung nicht unbedingt (sie kennt nur
  /// Umlaute und Trennzeichen) und stehen ohne Wortgrenzen im Text.
  bool _istZeichen(String s) =>
      s.length <= 3 && !RegExp(r'^[a-zA-ZäöüÄÖÜß]+$').hasMatch(s);

  bool _anWortgrenze(String text, int pos, int laenge) {
    final davor = pos == 0 ? ' ' : text[pos - 1];
    final ende = pos + laenge;
    final danach = ende >= text.length ? ' ' : text[ende];
    return !_istWortzeichen(davor) && !_istWortzeichen(danach);
  }

  bool _istWortzeichen(String c) => RegExp(r'[a-zA-Z0-9]').hasMatch(c);
}
