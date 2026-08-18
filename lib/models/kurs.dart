// Ein Kurs ist die Beschreibung eines Lernpakets: Bereiche, optionale
// Prüfungen, Feature-Flags und Beschriftungen. Der Inhalt (Fragen,
// Fachgespräch-Szenarien) hängt nicht hier dran, sondern in Lernpaket -
// so bleibt die Metadatenliste im Kursstore klein und schnell ladbar.
//
// Gebündelte Kurse liegen unter assets/kurse/<id>/ und laden ihre Fragen
// aus Dateien; importierte Kurse liegen komplett in Hive und tragen ihre
// Fragen inline.

import 'package:flutter/material.dart';

/// Woher der Kurs stammt - bestimmt, wie seine Fragen geladen werden.
enum KursQuelle {
  /// Mit der App ausgeliefert, Fragen kommen über rootBundle aus assets/.
  gebuendelt,

  /// Vom Nutzer importiert, Fragen liegen inline im Kursstore (Hive).
  importiert,
}

/// Ein Themenbereich innerhalb eines Kurses. [gewicht] steuert, wie stark
/// der Bereich in den Lernstand eingeht (null = gleichgewichtet).
class Bereich {
  final String id;
  final String titel;
  final String? farbe; // Hex, z.B. "#3F6FBF"
  final double? gewicht;
  final String? icon; // Schlüssel aus [bereichsIcons]

  const Bereich({
    required this.id,
    required this.titel,
    this.farbe,
    this.gewicht,
    this.icon,
  });

  factory Bereich.fromJson(Map<String, dynamic> json) => Bereich(
    id: json['id'] as String,
    titel: json['titel'] as String,
    farbe: json['farbe'] as String?,
    gewicht: (json['gewicht'] as num?)?.toDouble(),
    icon: json['icon'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titel': titel,
    if (farbe != null) 'farbe': farbe,
    if (gewicht != null) 'gewicht': gewicht,
    if (icon != null) 'icon': icon,
  };

  /// Farbe als [Color], oder null wenn nicht gesetzt bzw. unparsbar.
  Color? get farbeAlsColor {
    final roh = farbe;
    if (roh == null) return null;
    final hex = roh.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) return null;
    final wert = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return wert == null ? null : Color(wert);
  }

  /// Icon aus dem festen Katalog. Ein fester Katalog statt dynamischer
  /// Codepoints, weil Flutter sonst beim Icon-Tree-Shaking bricht.
  IconData get iconData => bereichsIcons[icon] ?? Icons.folder_outlined;
}

/// Auswählbare Icons für Bereiche. Bewusst klein und stabil gehalten -
/// die Schlüssel sind Teil des Paketformats.
const Map<String, IconData> bereichsIcons = {
  'engineering': Icons.engineering,
  'manufacturing': Icons.precision_manufacturing,
  'business': Icons.account_balance,
  'school': Icons.school,
  'language': Icons.translate,
  'science': Icons.science,
  'calculate': Icons.calculate,
  'code': Icons.code,
  'health': Icons.local_hospital,
  'law': Icons.gavel,
  'nature': Icons.eco,
  'history': Icons.history_edu,
  'geography': Icons.public,
  'art': Icons.palette,
  'music': Icons.music_note,
  'book': Icons.menu_book,
};

/// Eine Zeichnung/Abbildung, die während eines Testlaufs einsehbar ist.
class Zeichnung {
  final String pfad;
  final String label;

  const Zeichnung({required this.pfad, required this.label});

  factory Zeichnung.fromJson(Map<String, dynamic> json) => Zeichnung(
    pfad: json['pfad'] as String,
    label: json['label'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'pfad': pfad, 'label': label};
}

/// Ein Testlauf auf Zeit ("Prüfung"). Fragen werden über Frage.pruefung
/// == [code] zugeordnet und nach Frage.pruefungReihenfolge sortiert.
class PruefungsDefinition {
  final String code;
  final String titel;
  final int zeitlimitMinuten;
  final String beschreibung;
  final List<Zeichnung> zeichnungen;
  final List<String> diagrammKeys;
  final Map<String, String> stueckliste;

  const PruefungsDefinition({
    required this.code,
    required this.titel,
    this.zeitlimitMinuten = 60,
    this.beschreibung = '',
    this.zeichnungen = const [],
    this.diagrammKeys = const [],
    this.stueckliste = const {},
  });

  factory PruefungsDefinition.fromJson(Map<String, dynamic> json) =>
      PruefungsDefinition(
        code: json['code'] as String,
        titel: json['titel'] as String? ?? json['code'] as String,
        zeitlimitMinuten: (json['zeitlimitMinuten'] as num?)?.toInt() ?? 60,
        beschreibung: json['beschreibung'] as String? ?? '',
        zeichnungen: (json['zeichnungen'] as List? ?? [])
            .map((z) => Zeichnung.fromJson(Map<String, dynamic>.from(z as Map)))
            .toList(),
        diagrammKeys: (json['diagrammKeys'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        stueckliste: ((json['stueckliste'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k as String, v as String),
        ),
      );

  Map<String, dynamic> toJson() => {
    'code': code,
    'titel': titel,
    'zeitlimitMinuten': zeitlimitMinuten,
    'beschreibung': beschreibung,
    'zeichnungen': zeichnungen.map((z) => z.toJson()).toList(),
    'diagrammKeys': diagrammKeys,
    'stueckliste': stueckliste,
  };
}

/// Welche optionalen Modi ein Kurs mitbringt. Was hier false ist, wird in
/// der UI gar nicht erst angeboten.
class KursFeatures {
  final bool fachgespraech;
  final bool pruefungssimulation;
  final bool zeichnungen;

  const KursFeatures({
    this.fachgespraech = false,
    this.pruefungssimulation = false,
    this.zeichnungen = false,
  });

  factory KursFeatures.fromJson(Map<String, dynamic> json) => KursFeatures(
    fachgespraech: json['fachgespraech'] as bool? ?? false,
    pruefungssimulation: json['pruefungssimulation'] as bool? ?? false,
    zeichnungen: json['zeichnungen'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'fachgespraech': fachgespraech,
    'pruefungssimulation': pruefungssimulation,
    'zeichnungen': zeichnungen,
  };
}

/// Überschreibbare Beschriftungen. Ein Sprachkurs will "Sprachstand" statt
/// "Prüfungsreife" lesen - die Defaults bleiben neutral formuliert.
class KursBegriffe {
  final String lernstand;
  final String testlauf;
  final String dialog;

  const KursBegriffe({
    this.lernstand = 'Lernstand',
    this.testlauf = 'Testlauf',
    this.dialog = 'Dialog',
  });

  factory KursBegriffe.fromJson(Map<String, dynamic> json) => KursBegriffe(
    lernstand: json['lernstand'] as String? ?? 'Lernstand',
    testlauf: json['testlauf'] as String? ?? 'Testlauf',
    dialog: json['dialog'] as String? ?? 'Dialog',
  );

  Map<String, dynamic> toJson() => {
    'lernstand': lernstand,
    'testlauf': testlauf,
    'dialog': dialog,
  };
}

class Kurs {
  final String id;
  final String titel;
  final String kurzbeschreibung;
  final String sprache;
  final String? version;
  final String? autor;
  final List<Bereich> bereiche;
  final List<PruefungsDefinition> pruefungen;
  final KursFeatures features;
  final KursBegriffe begriffe;
  final KursQuelle quelle;

  /// Nur bei [KursQuelle.gebuendelt]: Basisordner unter assets/, aus dem
  /// [fragenDateien] und [fachgespraechDatei] geladen werden.
  final String? assetOrdner;
  final List<String> fragenDateien;
  final String? fachgespraechDatei;

  /// Wann der Kurs installiert wurde - nur bei importierten Kursen gesetzt.
  final DateTime? installiertAm;

  const Kurs({
    required this.id,
    required this.titel,
    this.kurzbeschreibung = '',
    this.sprache = 'de',
    this.version,
    this.autor,
    required this.bereiche,
    this.pruefungen = const [],
    this.features = const KursFeatures(),
    this.begriffe = const KursBegriffe(),
    this.quelle = KursQuelle.importiert,
    this.assetOrdner,
    this.fragenDateien = const [],
    this.fachgespraechDatei,
    this.installiertAm,
  });

  factory Kurs.fromJson(
    Map<String, dynamic> json, {
    KursQuelle quelle = KursQuelle.importiert,
    String? assetOrdner,
  }) => Kurs(
    id: json['id'] as String,
    titel: json['titel'] as String,
    kurzbeschreibung: json['kurzbeschreibung'] as String? ?? '',
    sprache: json['sprache'] as String? ?? 'de',
    version: json['version'] as String?,
    autor: json['autor'] as String?,
    bereiche: (json['bereiche'] as List? ?? [])
        .map((b) => Bereich.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList(),
    pruefungen: (json['pruefungen'] as List? ?? [])
        .map(
          (p) =>
              PruefungsDefinition.fromJson(Map<String, dynamic>.from(p as Map)),
        )
        .toList(),
    features: KursFeatures.fromJson(
      Map<String, dynamic>.from((json['features'] as Map?) ?? {}),
    ),
    begriffe: KursBegriffe.fromJson(
      Map<String, dynamic>.from((json['begriffe'] as Map?) ?? {}),
    ),
    quelle: quelle,
    assetOrdner: assetOrdner ?? json['assetOrdner'] as String?,
    fragenDateien: (json['fragenDateien'] as List? ?? [])
        .map((e) => e as String)
        .toList(),
    fachgespraechDatei: json['fachgespraechDatei'] as String?,
    installiertAm: json['installiertAm'] is String
        ? DateTime.tryParse(json['installiertAm'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titel': titel,
    'kurzbeschreibung': kurzbeschreibung,
    'sprache': sprache,
    if (version != null) 'version': version,
    if (autor != null) 'autor': autor,
    'bereiche': bereiche.map((b) => b.toJson()).toList(),
    'pruefungen': pruefungen.map((p) => p.toJson()).toList(),
    'features': features.toJson(),
    'begriffe': begriffe.toJson(),
    'quelle': quelle.name,
    if (assetOrdner != null) 'assetOrdner': assetOrdner,
    'fragenDateien': fragenDateien,
    if (fachgespraechDatei != null) 'fachgespraechDatei': fachgespraechDatei,
    if (installiertAm != null)
      'installiertAm': installiertAm!.toIso8601String(),
  };

  Kurs kopieMit({KursQuelle? quelle, DateTime? installiertAm}) => Kurs(
    id: id,
    titel: titel,
    kurzbeschreibung: kurzbeschreibung,
    sprache: sprache,
    version: version,
    autor: autor,
    bereiche: bereiche,
    pruefungen: pruefungen,
    features: features,
    begriffe: begriffe,
    quelle: quelle ?? this.quelle,
    assetOrdner: assetOrdner,
    fragenDateien: fragenDateien,
    fachgespraechDatei: fachgespraechDatei,
    installiertAm: installiertAm ?? this.installiertAm,
  );

  Bereich? bereichFuer(String id) {
    for (final b in bereiche) {
      if (b.id == id) return b;
    }
    return null;
  }

  PruefungsDefinition? pruefungFuer(String code) {
    for (final p in pruefungen) {
      if (p.code == code) return p;
    }
    return null;
  }

  /// Normalisierte Bereichsgewichte, die immer auf 1.0 summieren.
  ///
  /// Ohne Angabe im Paket werden alle Bereiche gleich gewichtet. Sind nur
  /// manche gewichtet, bekommen die übrigen 0 - das ist gewollt, damit ein
  /// Paket bewusst Bereiche vom Lernstand ausnehmen kann.
  Map<String, double> get normalisierteGewichte {
    if (bereiche.isEmpty) return const {};

    final hatGewichte = bereiche.any((b) => b.gewicht != null);
    if (!hatGewichte) {
      final anteil = 1.0 / bereiche.length;
      return {for (final b in bereiche) b.id: anteil};
    }

    final summe = bereiche.fold<double>(0, (s, b) => s + (b.gewicht ?? 0));
    if (summe <= 0) {
      final anteil = 1.0 / bereiche.length;
      return {for (final b in bereiche) b.id: anteil};
    }
    return {for (final b in bereiche) b.id: (b.gewicht ?? 0) / summe};
  }
}
