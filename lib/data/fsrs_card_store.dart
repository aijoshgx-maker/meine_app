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

// Kapselt das Lesen/Schreiben der FSRS-Kartenstände in Hive. Jede Frage-id
// ist ein eigener Eintrag in der Box, gespeichert als reine Map (kein
// Codegen/TypeAdapter nötig, da FsrsCard bereits toMap()/fromMap() mitbringt).
class FsrsCardStore {
  static const boxName = 'fsrs_cards';

  Box get _box => Hive.box(boxName);

  GespeicherteKarte? kartenStandFuer(String frageId) {
    final roh = _box.get(frageId);
    if (roh == null) return null;
    return GespeicherteKarte.fromMap(Map<String, dynamic>.from(roh as Map));
  }

  // Alle bekannten Kartenstände, keyed nach Frage-id. Fragen ohne Eintrag
  // (nie gelernt) tauchen hier bewusst nicht auf.
  Map<String, GespeicherteKarte> alleKartenstaende() {
    return {
      for (final key in _box.keys)
        key as String: GespeicherteKarte.fromMap(
          Map<String, dynamic>.from(_box.get(key) as Map),
        ),
    };
  }

  Future<void> speichern(String frageId, GespeicherteKarte karte) async {
    await _box.put(frageId, karte.toMap());
  }
}
