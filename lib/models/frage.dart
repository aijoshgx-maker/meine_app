// Eine einzelne Prüfungsfrage. Inhalt kommt aus assets/fragen/, der
// Lernfortschritt (FsrsCard) wird getrennt davon in Hive gespeichert.

import 'package:meine_app/models/frage_varianten.dart';

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

  // Optionale Kurzfassung der Erklärung, direkt nach dem Aufdecken gezeigt.
  //
  // Ohne Angabe wird sie aus erklaerung abgeleitet (siehe
  // core/quiz/erklaerung_teilen.dart) - deshalb optional: Ein Pflichtfeld
  // müsste für alle 681 Bestandsfragen von Hand geschrieben werden.
  final String? kurzerklaerung;

  final String? selfExplanationPrompt;
  final String? bildAsset;
  final String? workedExample;
  final int schwierigkeit; // 1=leicht, 2=mittel, 3=schwer

  // Kennzeichnet Fragen, die direkt aus einer echten IHK-Prüfung stammen.
  // Wert: "W22", "S17", "S19" oder "S18" – null für allgemeine Übungsfragen.
  final String? pruefung;
  // Reihenfolge innerhalb der Prüfung für die Prüfungssimulation.
  final int? pruefungReihenfolge;

  // Glossarbegriffe, die bei dieser Frage NICHT als Tipp erscheinen sollen.
  //
  // Nötig, wo der Tipp die Antwort verriete: Bei "Welche Einheit hat die
  // Winkelgeschwindigkeit?" wäre der Eintrag dazu die Lösung.
  final List<String> tippsAus;

  // Prüfungen des Validators, die für diese Frage bewusst abgeschaltet sind.
  //
  // Manche Warnungen sind Heuristiken, die legitime Fragen mittreffen: Bei
  // "Welche gehören zu X?" sind aus der Sache heraus oft fast alle Optionen
  // richtig - dort IST die Abgrenzung der Lernstoff. Für die App ohne
  // Bedeutung; steht hier, damit das Feld einen Import/Export übersteht.
  final List<String> bewusstSo;

  // Antworten, die als freie Texteingabe gelten, wenn diese Frage auf der
  // hoechsten Haertestufe ohne ihre Optionen gestellt wird.
  //
  // Leer bei allen Fragen, deren richtige Option nur im Zusammenspiel mit den
  // uebrigen Optionen Sinn ergibt ("Ja, fuer 9 Monate") - dort waere die
  // Frage ohne Auswahl unloesbar. Nur bei typ == single gefuellt; siehe
  // core/quiz/frage_haerte.dart.
  final List<String> freieAntwort;

  // Beschreibung, wie diese Aufgabe mit anderen Zahlen erscheinen kann.
  //
  // Null bei allen Fragen, die einen festen Merksatz abfragen - dort wäre
  // Variation Unsinn. Gesetzt bei Rechen- und Nachschlageaufgaben, wo sonst
  // das Ergebnis statt des Verfahrens auswendig gelernt wird.
  final FrageVarianten? varianten;

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
    this.kurzerklaerung,
    this.selfExplanationPrompt,
    this.bildAsset,
    this.workedExample,
    required this.schwierigkeit,
    this.pruefung,
    this.pruefungReihenfolge,
    this.tippsAus = const [],
    this.bewusstSo = const [],
    this.freieAntwort = const [],
    this.varianten,
  });

  /// Kopie mit ausgetauschten Feldern.
  ///
  /// Gebraucht, um eine gewürfelte Variante zu bauen: Sie ist eine
  /// gewöhnliche [Frage] mit ersetztem Text und neuem Lösungswert, damit
  /// Bewertung, Aufdeckung und Lernfortschritt unverändert weiterlaufen.
  Frage copyWith({
    String? typ,
    String? frage,
    List<String>? optionen,
    List<String>? akzeptierteKurzantworten,
    List<List<String>>? luecken,
    double? loesungswert,
    double? toleranz,
    String? erklaerung,
    String? workedExample,
  }) {
    return Frage(
      id: id,
      bereich: bereich,
      kategorie: kategorie,
      typ: typ ?? this.typ,
      frage: frage ?? this.frage,
      optionen: optionen ?? this.optionen,
      richtigeIndizes: richtigeIndizes,
      reihenfolge: reihenfolge,
      paare: paare,
      luecken: luecken ?? this.luecken,
      loesungswert: loesungswert ?? this.loesungswert,
      einheit: einheit,
      toleranz: toleranz ?? this.toleranz,
      akzeptierteKurzantworten:
          akzeptierteKurzantworten ?? this.akzeptierteKurzantworten,
      wahr: wahr,
      erklaerung: erklaerung ?? this.erklaerung,
      kurzerklaerung: kurzerklaerung,
      selfExplanationPrompt: selfExplanationPrompt,
      bildAsset: bildAsset,
      workedExample: workedExample ?? this.workedExample,
      schwierigkeit: schwierigkeit,
      pruefung: pruefung,
      pruefungReihenfolge: pruefungReihenfolge,
      tippsAus: tippsAus,
      bewusstSo: bewusstSo,
      freieAntwort: freieAntwort,
      varianten: varianten,
    );
  }

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
      kurzerklaerung: json['kurzerklaerung'] as String?,
      selfExplanationPrompt: json['selfExplanationPrompt'] as String?,
      bildAsset: json['bildAsset'] as String?,
      workedExample: json['workedExample'] as String?,
      schwierigkeit: json['schwierigkeit'] as int,
      pruefung: json['pruefung'] as String?,
      pruefungReihenfolge: json['pruefungReihenfolge'] as int?,
      tippsAus: strList(json['tippsAus']),
      bewusstSo: strList(json['bewusstSo']),
      freieAntwort: strList(json['freieAntwort']),
      varianten: json['varianten'] == null
          ? null
          : FrageVarianten.fromJson(
              (json['varianten'] as Map).cast<String, dynamic>(),
            ),
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
    if (kurzerklaerung != null) 'kurzerklaerung': kurzerklaerung,
    'selfExplanationPrompt': selfExplanationPrompt,
    'bildAsset': bildAsset,
    'workedExample': workedExample,
    'schwierigkeit': schwierigkeit,
    'pruefung': pruefung,
    'pruefungReihenfolge': pruefungReihenfolge,
    if (tippsAus.isNotEmpty) 'tippsAus': tippsAus,
    if (bewusstSo.isNotEmpty) 'bewusstSo': bewusstSo,
    if (freieAntwort.isNotEmpty) 'freieAntwort': freieAntwort,
    if (varianten != null) 'varianten': varianten!.toJson(),
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

/// Wie [frageTypVon], aber null statt einer Exception bei unbekanntem Typ.
/// Wird beim Import genutzt, um eine einzelne kaputte Frage zu überspringen,
/// statt das ganze Paket abzulehnen.
FrageTyp? frageTypOderNull(String typ) {
  for (final t in FrageTyp.values) {
    if (t.name == typ) return t;
  }
  return null;
}
