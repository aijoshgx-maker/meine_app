import 'package:hive/hive.dart';

import '../core/spaced_repetition/fsrs_scheduler.dart';

// Persistierter Stand einer Karte: der FSRS-Stand selbst plus das
// Hypercorrection-Flag (sicher geantwortet, aber falsch).
class GespeicherteKarte {
  final FsrsCard card;
  final bool hochkonfidentFalsch;

  const GespeicherteKarte({
    required this.card,
    this.hochkonfidentFalsch = false,
  });

  Map<String, dynamic> toMap() => {
    ...card.toMap(),
    'hochkonfidentFalsch': hochkonfidentFalsch,
  };

  factory GespeicherteKarte.fromMap(Map<String, dynamic> map) =>
      GespeicherteKarte(
        card: FsrsCard.fromMap(map),
        hochkonfidentFalsch: map['hochkonfidentFalsch'] as bool? ?? false,
      );
}

// Kapselt das Lesen/Schreiben der FSRS-Kartenstände in Hive.
//
// Der Box-Schlüssel ist "kursId::frageId", nicht die Frage-id allein: seit
// beliebige Lernpakete importierbar sind, dürfen sich gleichnamige Frage-ids
// aus verschiedenen Kursen nicht überschreiben. Bestandsdaten aus der Zeit
// davor werden von Migrationen.ausfuehren() einmalig umgeschlüsselt.
//
// Gespeichert wird als reine Map (kein Codegen/TypeAdapter nötig, da
// FsrsCard bereits toMap()/fromMap() mitbringt).
class FsrsCardStore {
  static const boxName = 'fsrs_cards';
  static const trennzeichen = '::';

  Box get _box => Hive.box(boxName);

  /// Box-Schlüssel für eine Frage innerhalb eines Kurses.
  static String schluessel(String kursId, String frageId) =>
      '$kursId$trennzeichen$frageId';

  /// Zerlegt einen Box-Schlüssel wieder in Kurs- und Frage-id. Gibt null
  /// zurück, wenn der Schlüssel nicht dem Schema entspricht.
  static (String kursId, String frageId)? zerlege(String schluessel) {
    final index = schluessel.indexOf(trennzeichen);
    if (index <= 0) return null;
    return (
      schluessel.substring(0, index),
      schluessel.substring(index + trennzeichen.length),
    );
  }

  GespeicherteKarte? kartenStandFuer(String kursId, String frageId) {
    final roh = _box.get(schluessel(kursId, frageId));
    if (roh == null) return null;
    return GespeicherteKarte.fromMap(Map<String, dynamic>.from(roh as Map));
  }

  /// Alle Kartenstände eines Kurses, keyed nach Frage-id. Fragen ohne
  /// Eintrag (nie gelernt) tauchen hier bewusst nicht auf.
  Map<String, GespeicherteKarte> alleKartenstaende(String kursId) {
    final praefix = '$kursId$trennzeichen';
    final ergebnis = <String, GespeicherteKarte>{};
    for (final key in _box.keys) {
      final schluessel = key as String;
      if (!schluessel.startsWith(praefix)) continue;
      ergebnis[schluessel.substring(
        praefix.length,
      )] = GespeicherteKarte.fromMap(
        Map<String, dynamic>.from(_box.get(key) as Map),
      );
    }
    return ergebnis;
  }

  /// Rohe Kartenstände über alle Kurse hinweg, keyed nach Box-Schlüssel.
  /// Nur für Backup/Export gedacht.
  Map<String, GespeicherteKarte> alleKartenstaendeRoh() {
    return {
      for (final key in _box.keys)
        key as String: GespeicherteKarte.fromMap(
          Map<String, dynamic>.from(_box.get(key) as Map),
        ),
    };
  }

  Future<void> speichern(
    String kursId,
    String frageId,
    GespeicherteKarte karte,
  ) async {
    await _box.put(schluessel(kursId, frageId), karte.toMap());
  }

  /// Schreibt direkt über den Box-Schlüssel - nur für den Backup-Import.
  Future<void> speichernRoh(String schluessel, GespeicherteKarte karte) async {
    await _box.put(schluessel, karte.toMap());
  }

  /// Entfernt den gesamten Lernfortschritt eines Kurses. Wird beim
  /// Deinstallieren aufgerufen, damit keine verwaisten Karten zurückbleiben.
  Future<int> kursLoeschen(String kursId) async {
    final praefix = '$kursId$trennzeichen';
    final zuLoeschen = _box.keys
        .cast<String>()
        .where((k) => k.startsWith(praefix))
        .toList();
    await _box.deleteAll(zuLoeschen);
    return zuLoeschen.length;
  }
}
