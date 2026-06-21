// Eine einzelne Prüfungsfrage. Inhalt kommt aus assets/fragen.json, der
// Lernfortschritt (FsrsCard) wird getrennt davon in Hive gespeichert.
class Frage {
  final String id;
  final String bereich;
  final String kategorie;
  final String typ;
  final String frage;
  final List<String> optionen;
  final List<int> richtigeIndizes;
  final double? loesungswert;
  final double? toleranz;
  final List<String> akzeptierteKurzantworten;
  final String erklaerung;
  final String? bildAsset;
  final String? workedExample;
  final int schwierigkeit;

  const Frage({
    required this.id,
    required this.bereich,
    required this.kategorie,
    required this.typ,
    required this.frage,
    required this.optionen,
    required this.richtigeIndizes,
    this.loesungswert,
    this.toleranz,
    required this.akzeptierteKurzantworten,
    required this.erklaerung,
    this.bildAsset,
    this.workedExample,
    required this.schwierigkeit,
  });

  factory Frage.fromJson(Map<String, dynamic> json) {
    return Frage(
      id: json['id'] as String,
      bereich: json['bereich'] as String,
      kategorie: json['kategorie'] as String,
      typ: json['typ'] as String,
      frage: json['frage'] as String,
      optionen: (json['optionen'] as List).map((o) => o as String).toList(),
      richtigeIndizes: (json['richtigeIndizes'] as List)
          .map((i) => i as int)
          .toList(),
      loesungswert: (json['loesungswert'] as num?)?.toDouble(),
      toleranz: (json['toleranz'] as num?)?.toDouble(),
      akzeptierteKurzantworten: (json['akzeptierteKurzantworten'] as List)
          .map((a) => a as String)
          .toList(),
      erklaerung: json['erklaerung'] as String,
      bildAsset: json['bildAsset'] as String?,
      workedExample: json['workedExample'] as String?,
      schwierigkeit: json['schwierigkeit'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bereich': bereich,
    'kategorie': kategorie,
    'typ': typ,
    'frage': frage,
    'optionen': optionen,
    'richtigeIndizes': richtigeIndizes,
    'loesungswert': loesungswert,
    'toleranz': toleranz,
    'akzeptierteKurzantworten': akzeptierteKurzantworten,
    'erklaerung': erklaerung,
    'bildAsset': bildAsset,
    'workedExample': workedExample,
    'schwierigkeit': schwierigkeit,
  };
}

// Die sechs Fragetypen aus PROMPT.md, als sicherer Aufzählungstyp für die
// UI-Schicht (das `typ`-Feld im Modell bleibt ein String, passend zum JSON).
enum FrageTyp { single, multi, rechnung, wahrfalsch, zuordnung, kurzantwort }

FrageTyp frageTypVon(String typ) =>
    FrageTyp.values.firstWhere((t) => t.name == typ);
