// Eine einzelne Prüfungsfrage. Inhalt kommt aus assets/fragen/, der
// Lernfortschritt (FsrsCard) wird getrennt davon in Hive gespeichert.

class Paar {
  final String links;
  final String rechts;

  const Paar({required this.links, required this.rechts});

  factory Paar.fromJson(Map<String, dynamic> json) =>
      Paar(links: json['links'] as String, rechts: json['rechts'] as String);

  Map<String, dynamic> toJson() => {'links': links, 'rechts': rechts};
}

class Frage {
  final String id;
  final String bereich;
  final String kategorie;
  final String typ;
  final String frage;

  // single / multi / wahrfalsch (als Buttons): Auswahloptionen
  final List<String> optionen;
  // single / multi: Indizes der richtigen Optionen (auch wahrfalsch-Fallback)
  final List<int> richtigeIndizes;
  // reihenfolge: korrekte Sortierung als Optionen-Indexliste
  final List<int> reihenfolge;
  // zuordnung: Paare aus linker und rechter Seite
  final List<Paar> paare;
  // lueckentext: pro {{n}}-Lücke eine Liste akzeptierter Antworten
  final List<List<String>> luecken;

  final double? loesungswert; // rechnung
  final String? einheit; // rechnung, z.B. "1/min"
  final double? toleranz; // rechnung

  final List<String> akzeptierteKurzantworten; // kurzantwort

  final bool? wahr; // wahrfalsch

  final String erklaerung;
  final String? selfExplanationPrompt;
  final String? bildAsset;
  final String? workedExample;
  final int schwierigkeit; // 1=leicht, 2=mittel, 3=schwer

  // Kennzeichnet Fragen, die direkt aus einer echten IHK-Prüfung stammen.
  // Wert: "W22", "S17", "S19" oder "S18" – null für allgemeine Übungsfragen.
  final String? pruefung;
  // Reihenfolge innerhalb der Prüfung für die Prüfungssimulation.
  final int? pruefungReihenfolge;

  const Frage({
    required this.id,
    required this.bereich,
    required this.kategorie,
    required this.typ,
    required this.frage,
    required this.optionen,
    required this.richtigeIndizes,
    required this.reihenfolge,
    required this.paare,
    required this.luecken,
    this.loesungswert,
    this.einheit,
    this.toleranz,
    required this.akzeptierteKurzantworten,
    this.wahr,
    required this.erklaerung,
    this.selfExplanationPrompt,
    this.bildAsset,
    this.workedExample,
    required this.schwierigkeit,
    this.pruefung,
    this.pruefungReihenfolge,
  });

  factory Frage.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        (v as List? ?? []).map((e) => e as String).toList();
    List<int> intList(dynamic v) =>
        (v as List? ?? []).map((e) => e as int).toList();

    return Frage(
      id: json['id'] as String,
      bereich: json['bereich'] as String,
      kategorie: json['kategorie'] as String,
      typ: json['typ'] as String,
      frage: json['frage'] as String,
      optionen: strList(json['optionen']),
      richtigeIndizes: intList(json['richtigeIndizes']),
      reihenfolge: intList(json['reihenfolge']),
      paare: (json['paare'] as List? ?? [])
          .map((p) => Paar.fromJson(p as Map<String, dynamic>))
          .toList(),
      luecken: (json['luecken'] as List? ?? []).map((l) => strList(l)).toList(),
      loesungswert: (json['loesungswert'] as num?)?.toDouble(),
      einheit: json['einheit'] as String?,
      toleranz: (json['toleranz'] as num?)?.toDouble(),
      akzeptierteKurzantworten: strList(json['akzeptierteKurzantworten']),
      wahr: json['wahr'] as bool?,
      erklaerung: json['erklaerung'] as String,
      selfExplanationPrompt: json['selfExplanationPrompt'] as String?,
      bildAsset: json['bildAsset'] as String?,
      workedExample: json['workedExample'] as String?,
      schwierigkeit: json['schwierigkeit'] as int,
      pruefung: json['pruefung'] as String?,
      pruefungReihenfolge: json['pruefungReihenfolge'] as int?,
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
    'reihenfolge': reihenfolge,
    'paare': paare.map((p) => p.toJson()).toList(),
    'luecken': luecken,
    'loesungswert': loesungswert,
    'einheit': einheit,
    'toleranz': toleranz,
    'akzeptierteKurzantworten': akzeptierteKurzantworten,
    'wahr': wahr,
    'erklaerung': erklaerung,
    'selfExplanationPrompt': selfExplanationPrompt,
    'bildAsset': bildAsset,
    'workedExample': workedExample,
    'schwierigkeit': schwierigkeit,
    'pruefung': pruefung,
    'pruefungReihenfolge': pruefungReihenfolge,
  };
}

enum FrageTyp {
  single,
  multi,
  rechnung,
  wahrfalsch,
  zuordnung,
  kurzantwort,
  lueckentext,
  reihenfolge,
}

FrageTyp frageTypVon(String typ) =>
    FrageTyp.values.firstWhere((t) => t.name == typ);
