// Beschreibung einer Aufgabe, die bei jedem Durchgang mit anderen Zahlen
// erscheint.
//
// Der Anlass: Wer eine Rechenaufgabe zum dritten Mal sieht, erinnert sich an
// "5,06" statt an den Rechenweg. Die Karte gilt dann als sicher, das
// Verfahren sitzt aber nicht. Dasselbe gilt fürs Nachschlagen im
// Tabellenbuch - geübt werden soll das Nachschlagen, nicht die Zahl.
//
// Zwei Quellen, dieselbe Vorlagensyntax - einzeln oder zusammen:
//
//   variablen  gewürfelte Zahlen, Lösung aus einer Formel
//   zeilen     feste Wertegruppen aus einer Tabelle, damit nur echte
//              Normwerte vorkommen
//
// Zusammen sind sie der Regelfall bei Werkzeugaufgaben: Steigung und
// Flankendurchmesser gehören zum Gewinde und müssen zueinander passen, die
// Drehzahl wählt der Bearbeiter frei.
//
// Fragen ohne dieses Feld bleiben unverändert - Fristen, Paragrafen und
// Definitionen dürfen nicht variieren, dort IST der Wert der Lernstoff.
library;

import 'dart:math';

/// Woher der Wert einer einzelnen Variablen kommt.
class VariablenQuelle {
  /// Feste Auswahlliste - für Werte, die nicht beliebig sein dürfen
  /// (Wirkungsgrade, Zähnezahlen, Normspannungen).
  final List<double> werte;

  /// Bereich mit Schrittweite. Nur gesetzt, wenn [werte] leer ist.
  final double? von;
  final double? bis;
  final double? schritt;

  const VariablenQuelle({
    this.werte = const [],
    this.von,
    this.bis,
    this.schritt,
  });

  factory VariablenQuelle.fromJson(Map<String, dynamic> json) {
    final werte = (json['werte'] as List?)
        ?.map((w) => (w as num).toDouble())
        .toList();
    return VariablenQuelle(
      werte: werte ?? const [],
      von: (json['von'] as num?)?.toDouble(),
      bis: (json['bis'] as num?)?.toDouble(),
      schritt: (json['schritt'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (werte.isNotEmpty) 'werte': werte,
    if (von != null) 'von': von,
    if (bis != null) 'bis': bis,
    if (schritt != null) 'schritt': schritt,
  };

  /// Ob die Angaben überhaupt eine Ziehung erlauben.
  String? get fehler {
    if (werte.isNotEmpty) return null;
    if (von == null || bis == null || schritt == null) {
      return 'braucht entweder "werte" oder "von"/"bis"/"schritt"';
    }
    if (schritt! <= 0) return '"schritt" muss größer als 0 sein';
    if (bis! < von!) return '"bis" liegt unter "von"';
    return null;
  }

  double ziehe(Random zufall) {
    if (werte.isNotEmpty) return werte[zufall.nextInt(werte.length)];

    final stufen = ((bis! - von!) / schritt!).round();
    final roh = von! + zufall.nextInt(stufen + 1) * schritt!;
    // Ohne das Nachrunden käme aus 2,2 + 3 · 0,1 die Zahl 2,5000000000000004
    // heraus - und die stünde so in der Aufgabe.
    return _aufSchrittGerundet(roh, schritt!);
  }
}

double _aufSchrittGerundet(double wert, double schritt) {
  final stellen = _nachkommastellen(schritt);
  final faktor = pow(10, stellen);
  return (wert * faktor).round() / faktor;
}

int _nachkommastellen(double wert) {
  final text = wert.toString();
  final punkt = text.indexOf('.');
  if (punkt < 0) return 0;
  final rest = text.substring(punkt + 1);
  return rest == '0' ? 0 : rest.length;
}

/// Die Variantenbeschreibung einer Frage.
class FrageVarianten {
  /// Gewürfelte Variablen (Formel-Quelle).
  final Map<String, VariablenQuelle> variablen;

  /// Spaltennamen der Tabellen-Quelle.
  final List<String> spalten;

  /// Wertezeilen der Tabellen-Quelle; je Zeile ein vollständiger Satz.
  final List<List<Object>> zeilen;

  /// Die Werte, mit denen die Frage ursprünglich dastand.
  ///
  /// Pflichtfeld, und zwar aus zwei Gründen: Der Testlauf zeigt damit den
  /// originalen Prüfungsbogen, und der Validator rechnet damit nach, ob die
  /// hinterlegte Formel den seit jeher gespeicherten Lösungswert trifft.
  final Map<String, Object> original;

  /// Zwischenergebnisse für den Lösungsweg, in Reihenfolge auswertbar.
  ///
  /// Ohne sie wären die Lösungswege ärmer als die bestehenden - die zeigen
  /// bei jeder Aufgabe ihre Schritte.
  final Map<String, String> zwischen;

  /// Vorlagen. Was hier null ist, bleibt aus der Frage unverändert stehen.
  final String? frage;
  final String? loesung;
  final String? workedExample;
  final String? erklaerung;
  final List<String> akzeptierteKurzantworten;
  final List<List<String>> luecken;

  /// Nachkommastellen des Lösungswerts.
  final int rundung;

  /// Feste Nachkommastellen einzelner Werte in der Anzeige.
  ///
  /// Normalerweise fallen nachlaufende Nullen weg - "0,50" liest sich als
  /// "0,5". Bei Messgrößen ist die Null aber die Aussage: Eine Aufweitung
  /// von "0,090 mm" ist auf ein Tausendstel angegeben, "0,09 mm" nur auf
  /// ein Hundertstel.
  final Map<String, int> stellen;

  /// Toleranz in Prozent des Lösungswerts.
  ///
  /// Bei variierenden Zahlen ist eine feste Toleranz schief: 10 W sind bei
  /// 5314 W großzügig und bei 200 W streng. Ohne Angabe bleibt die an der
  /// Frage hinterlegte absolute Toleranz gültig.
  final double? toleranzProzent;

  const FrageVarianten({
    this.variablen = const {},
    this.spalten = const [],
    this.zeilen = const [],
    this.original = const {},
    this.zwischen = const {},
    this.frage,
    this.loesung,
    this.workedExample,
    this.erklaerung,
    this.akzeptierteKurzantworten = const [],
    this.luecken = const [],
    this.rundung = 2,
    this.stellen = const {},
    this.toleranzProzent,
  });

  /// Ob die Werte aus einer Tabelle statt aus dem Zufallsgenerator kommen.
  bool get istTabelle => zeilen.isNotEmpty;

  /// Alle Namen, die eine Vorlage einsetzen darf (ohne `loesung`).
  Set<String> get bekannteNamen => {
    ...variablen.keys,
    ...spalten,
    ...zwischen.keys,
  };

  factory FrageVarianten.fromJson(Map<String, dynamic> json) {
    List<String> strListe(dynamic v) =>
        (v as List? ?? []).map((e) => e as String).toList();

    return FrageVarianten(
      variablen: {
        for (final e in (json['variablen'] as Map? ?? {}).entries)
          e.key as String: VariablenQuelle.fromJson(
            (e.value as Map).cast<String, dynamic>(),
          ),
      },
      spalten: strListe(json['spalten']),
      zeilen: (json['zeilen'] as List? ?? [])
          .map((z) => (z as List).map((w) => w as Object).toList())
          .toList(),
      original: (json['original'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, v as Object),
      ),
      zwischen: (json['zwischen'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, v as String),
      ),
      frage: json['frage'] as String?,
      loesung: json['loesung'] as String?,
      workedExample: json['workedExample'] as String?,
      erklaerung: json['erklaerung'] as String?,
      akzeptierteKurzantworten: strListe(json['akzeptierteKurzantworten']),
      luecken: (json['luecken'] as List? ?? [])
          .map((l) => strListe(l))
          .toList(),
      rundung: json['rundung'] as int? ?? 2,
      stellen: (json['stellen'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, v as int),
      ),
      toleranzProzent: (json['toleranzProzent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (variablen.isNotEmpty)
      'variablen': variablen.map((k, v) => MapEntry(k, v.toJson())),
    if (spalten.isNotEmpty) 'spalten': spalten,
    if (zeilen.isNotEmpty) 'zeilen': zeilen,
    'original': original,
    if (zwischen.isNotEmpty) 'zwischen': zwischen,
    if (frage != null) 'frage': frage,
    if (loesung != null) 'loesung': loesung,
    if (workedExample != null) 'workedExample': workedExample,
    if (erklaerung != null) 'erklaerung': erklaerung,
    if (akzeptierteKurzantworten.isNotEmpty)
      'akzeptierteKurzantworten': akzeptierteKurzantworten,
    if (luecken.isNotEmpty) 'luecken': luecken,
    'rundung': rundung,
    if (stellen.isNotEmpty) 'stellen': stellen,
    if (toleranzProzent != null) 'toleranzProzent': toleranzProzent,
  };

  /// Zieht einen Satz Werte: eine ganze Tabellenzeile, dazu je Variable
  /// einen gewürfelten Wert.
  ///
  /// Beides zusammen ist der Regelfall bei Werkzeugaufgaben: Steigung und
  /// Flankendurchmesser gehören zum Gewinde und müssen zusammenpassen, die
  /// Drehzahl wählt der Bearbeiter frei.
  Map<String, Object> ziehe(Random zufall) {
    final werte = <String, Object>{};
    if (istTabelle) {
      final zeile = zeilen[zufall.nextInt(zeilen.length)];
      for (var i = 0; i < spalten.length && i < zeile.length; i++) {
        werte[spalten[i]] = zeile[i];
      }
    }
    for (final e in variablen.entries) {
      werte[e.key] = e.value.ziehe(zufall);
    }
    return werte;
  }
}
