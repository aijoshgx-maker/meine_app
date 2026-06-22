import 'package:hive/hive.dart';

import '../models/konfidenz.dart';

// Ein einzelner Beantwortungsversuch, append-only protokolliert. bereich und
// kategorie werden zum Zeitpunkt des Schreibens denormalisiert (aus der
// jeweiligen Frage kopiert), damit das Dashboard später ohne Rückgriff auf
// den (möglicherweise inzwischen geänderten) Fragenkatalog auswerten kann.
class Attempt {
  final String frageId;
  final DateTime zeitpunkt;
  final Konfidenz konfidenz;
  final bool korrekt;
  final String bereich;
  final String kategorie;
  final String? selbsterklaerung;

  const Attempt({
    required this.frageId,
    required this.zeitpunkt,
    required this.konfidenz,
    required this.korrekt,
    required this.bereich,
    required this.kategorie,
    this.selbsterklaerung,
  });

  Map<String, dynamic> toMap() => {
    'frageId': frageId,
    'zeitpunkt': zeitpunkt.toIso8601String(),
    'konfidenz': konfidenz.name,
    'korrekt': korrekt,
    'bereich': bereich,
    'kategorie': kategorie,
    'selbsterklaerung': selbsterklaerung,
  };

  factory Attempt.fromMap(Map<String, dynamic> map) => Attempt(
    frageId: map['frageId'] as String,
    zeitpunkt: DateTime.parse(map['zeitpunkt'] as String),
    konfidenz: Konfidenz.values.byName(map['konfidenz'] as String),
    korrekt: map['korrekt'] as bool,
    bereich: map['bereich'] as String,
    kategorie: map['kategorie'] as String,
    selbsterklaerung: map['selbsterklaerung'] as String?,
  );
}

// Append-only Protokoll aller Beantwortungsversuche, Grundlage für das
// Dashboard (Behaltensquote, Kalibrierung, schwache Themen).
class AttemptHistoryStore {
  static const boxName = 'attempt_history';

  Box get _box => Hive.box(boxName);

  Future<void> anhaengen(Attempt attempt) async {
    await _box.add(attempt.toMap());
  }

  List<Attempt> alle() {
    return _box.values
        .map((roh) => Attempt.fromMap(Map<String, dynamic>.from(roh as Map)))
        .toList();
  }
}
