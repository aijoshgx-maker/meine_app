import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';

import 'attempt_history_store.dart';
import 'fsrs_card_store.dart';
import 'settings_store.dart';

/// Einmalige Datenumbauten beim App-Start.
///
/// Die erreichte Version steht in der Settings-Box. Jede Migration muss
/// idempotent sein: bricht die App mittendrin ab, läuft sie beim nächsten
/// Start erneut und darf dabei nichts kaputt machen.
class Migrationen {
  /// Aktuelle Datenversion. Beim Erhöhen einen Fall in [_schritte] ergänzen.
  static const aktuelleVersion = 1;

  /// Kurs, dem Bestandsdaten ohne Kurszuordnung zugeschlagen werden. Vor der
  /// Mehrkurs-Fähigkeit gab es nur diesen einen Kurs.
  static const bestandsKursId = 'ap2-industriemechaniker';

  final SettingsStore _einstellungen;

  Migrationen({SettingsStore? einstellungen})
    : _einstellungen = einstellungen ?? SettingsStore();

  /// Führt alle noch ausstehenden Migrationen aus und gibt zurück, wie viele
  /// Schritte tatsächlich gelaufen sind.
  Future<int> ausfuehren() async {
    var version = _einstellungen.datenVersionLaden();
    if (version >= aktuelleVersion) return 0;

    var gelaufen = 0;
    while (version < aktuelleVersion) {
      final naechste = version + 1;
      await _schritt(naechste);
      await _einstellungen.datenVersionSpeichern(naechste);
      version = naechste;
      gelaufen++;
    }
    return gelaufen;
  }

  Future<void> _schritt(int version) async {
    switch (version) {
      case 1:
        await _v1KursIdsNachtragen();
      default:
        throw StateError('Keine Migration für Datenversion $version');
    }
  }

  /// v1: Mehrkurs-Fähigkeit.
  ///
  /// Vorher waren FSRS-Karten allein unter der Frage-id abgelegt und
  /// Verlaufseinträge trugen keine Kurszuordnung. Beides bekommt jetzt den
  /// Bestandskurs zugeordnet, damit der bisherige Lernfortschritt erhalten
  /// bleibt, statt beim ersten Start unter dem neuen Schlüsselschema
  /// unsichtbar zu werden.
  Future<void> _v1KursIdsNachtragen() async {
    final kartenBox = Hive.box(FsrsCardStore.boxName);
    var karten = 0;

    // Erst sammeln, dann schreiben: die Box während der Iteration zu
    // verändern würde den Iterator invalidieren.
    final umzuschluesseln = <String, Map>{};
    for (final key in kartenBox.keys) {
      final schluessel = key as String;
      if (schluessel.contains(FsrsCardStore.trennzeichen)) continue;
      umzuschluesseln[schluessel] = kartenBox.get(key) as Map;
    }

    for (final eintrag in umzuschluesseln.entries) {
      final neuerSchluessel = FsrsCardStore.schluessel(
        bestandsKursId,
        eintrag.key,
      );
      // Nicht überschreiben, falls der neue Schlüssel schon existiert -
      // dann lief die Migration bereits einmal teilweise durch.
      if (!kartenBox.containsKey(neuerSchluessel)) {
        await kartenBox.put(neuerSchluessel, eintrag.value);
      }
      await kartenBox.delete(eintrag.key);
      karten++;
    }

    final verlaufBox = Hive.box(AttemptHistoryStore.boxName);
    var verlauf = 0;
    for (final key in verlaufBox.keys.toList()) {
      final roh = Map<String, dynamic>.from(verlaufBox.get(key) as Map);
      if (roh['kursId'] != null) continue;
      roh['kursId'] = bestandsKursId;
      await verlaufBox.put(key, roh);
      verlauf++;
    }

    debugPrint(
      'Migration v1: $karten Karten umgeschlüsselt, '
      '$verlauf Verlaufseinträge ergänzt.',
    );
  }
}
