import 'package:hive/hive.dart';

import '../models/konfidenz.dart';

// Ein einzelner Beantwortungsversuch, append-only protokolliert. kursId,
// bereich und kategorie werden zum Zeitpunkt des Schreibens denormalisiert
// (aus dem aktiven Kurs bzw. der jeweiligen Frage kopiert), damit das
// Dashboard später ohne Rückgriff auf den (möglicherweise inzwischen
// geänderten oder deinstallierten) Fragenkatalog auswerten kann.
class Attempt {
  final String kursId;
  final String frageId;
  final DateTime zeitpunkt;
  final Konfidenz konfidenz;
  final bool korrekt;
  final String bereich;
  final String kategorie;
  final String? selbsterklaerung;

  const Attempt({
    required this.kursId,
    required this.frageId,
    required this.zeitpunkt,
    required this.konfidenz,
    required this.korrekt,
    required this.bereich,
    required this.kategorie,
    this.selbsterklaerung,
  });

  Map<String, dynamic> toMap() => {
    'kursId': kursId,
    'frageId': frageId,
    'zeitpunkt': zeitpunkt.toIso8601String(),
    'konfidenz': konfidenz.name,
    'korrekt': korrekt,
    'bereich': bereich,
    'kategorie': kategorie,
    'selbsterklaerung': selbsterklaerung,
  };

  // kursId fehlt in Einträgen aus der Zeit vor der Mehrkurs-Fähigkeit.
  // Migrationen.ausfuehren() schreibt sie nach, dieser Fallback fängt nur
  // noch Backups aus alten App-Versionen ab.
  factory Attempt.fromMap(
    Map<String, dynamic> map, {
    String standardKursId = '',
  }) => Attempt(
    kursId: map['kursId'] as String? ?? standardKursId,
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

  /// Alle Versuche über alle Kurse hinweg - für Backup und Migration.
  List<Attempt> alle() {
    return _box.values
        .map((roh) => Attempt.fromMap(Map<String, dynamic>.from(roh as Map)))
        .toList();
  }

  /// Nur die Versuche eines Kurses. Das Dashboard wertet immer genau einen
  /// Kurs aus, damit sich Fortschritte verschiedener Themen nicht vermischen.
  List<Attempt> fuerKurs(String kursId) =>
      alle().where((a) => a.kursId == kursId).toList();

  /// Entfernt die Historie eines Kurses (beim Deinstallieren).
  Future<int> kursLoeschen(String kursId) async {
    final zuLoeschen = <dynamic>[];
    for (final key in _box.keys) {
      final roh = Map<String, dynamic>.from(_box.get(key) as Map);
      if (roh['kursId'] == kursId) zuLoeschen.add(key);
    }
    await _box.deleteAll(zuLoeschen);
    return zuLoeschen.length;
  }
}
