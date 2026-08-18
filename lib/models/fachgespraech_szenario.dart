import 'dart:convert';
import 'package:flutter/services.dart';

class FachgespraechFrage {
  final String id;
  final String pruefer;
  final String musterloesung;
  final List<String> schluesselwoerter;
  final String erklaerung;
  final int schwierigkeit;
  final String? bildAsset;

  const FachgespraechFrage({
    required this.id,
    required this.pruefer,
    required this.musterloesung,
    required this.schluesselwoerter,
    required this.erklaerung,
    required this.schwierigkeit,
    this.bildAsset,
  });

  factory FachgespraechFrage.fromJson(Map<String, dynamic> j) =>
      FachgespraechFrage(
        id: j['id'] as String,
        pruefer: j['pruefer'] as String,
        musterloesung: j['musterloesung'] as String,
        schluesselwoerter: (j['schluesselwoerter'] as List)
            .map((e) => e as String)
            .toList(),
        erklaerung: j['erklaerung'] as String,
        schwierigkeit: j['schwierigkeit'] as int,
        bildAsset: j['bildAsset'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'pruefer': pruefer,
    'musterloesung': musterloesung,
    'schluesselwoerter': schluesselwoerter,
    'erklaerung': erklaerung,
    'schwierigkeit': schwierigkeit,
    'bildAsset': bildAsset,
  };
}

class FachgespraechSzenario {
  final String id;
  final String titel;
  final String kontext;
  final String fertigungsauftrag;
  final String? zeichnungsKey;
  final List<String> kategorien;
  final List<FachgespraechFrage> fragen;

  const FachgespraechSzenario({
    required this.id,
    required this.titel,
    required this.kontext,
    required this.fertigungsauftrag,
    this.zeichnungsKey,
    required this.kategorien,
    required this.fragen,
  });

  factory FachgespraechSzenario.fromJson(Map<String, dynamic> j) =>
      FachgespraechSzenario(
        id: j['id'] as String,
        titel: j['titel'] as String,
        kontext: j['kontext'] as String,
        fertigungsauftrag: j['fertigungsauftrag'] as String,
        zeichnungsKey: j['zeichnungsKey'] as String?,
        kategorien: (j['kategorien'] as List).map((e) => e as String).toList(),
        fragen: (j['fragen'] as List)
            .map((e) => FachgespraechFrage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titel': titel,
    'kontext': kontext,
    'fertigungsauftrag': fertigungsauftrag,
    'zeichnungsKey': zeichnungsKey,
    'kategorien': kategorien,
    'fragen': fragen.map((f) => f.toJson()).toList(),
  };

  /// Lädt die Szenarien eines gebündelten Kurses aus assets/.
  ///
  /// Für importierte Kurse liegt der Inhalt im Kursstore - dort geht der Weg
  /// über KursRepository statt über rootBundle.
  static Future<List<FachgespraechSzenario>> ladeAlle([
    String pfad = 'assets/fragen/fachgespraech_szenarien.json',
  ]) async {
    final raw = await rootBundle.loadString(pfad);
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => FachgespraechSzenario.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
