// Gemeinsames Test-Gerüst für die Mehrkurs-Architektur: ein minimaler Kurs
// plus In-Memory-Fakes der beiden Hive-gestützten Stores.
//
// Ohne das müsste jeder Test seinen eigenen Kurs zusammenbauen und dabei die
// Schlüsselkonvention "kursId::frageId" nachbilden.

import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/models/fachgespraech_szenario.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/kurs.dart';
import 'package:meine_app/models/lernpaket.dart';

const testKursId = 'test-kurs';

Kurs testKurs({
  String id = testKursId,
  List<Bereich> bereiche = const [Bereich(id: 'allgemein', titel: 'Allgemein')],
  List<PruefungsDefinition> pruefungen = const [],
  KursFeatures features = const KursFeatures(),
}) => Kurs(
  id: id,
  titel: 'Testkurs',
  bereiche: bereiche,
  pruefungen: pruefungen,
  features: features,
);

Lernpaket testPaket(
  List<Frage> fragen, {
  Kurs? kurs,
  List<FachgespraechSzenario> szenarien = const [],
}) => Lernpaket(kurs: kurs ?? testKurs(), fragen: fragen, szenarien: szenarien);

/// In-Memory-Ersatz für den Hive-gestützten Kartenspeicher. Bildet die
/// Kurs-Partitionierung nach, damit Tests echte Schlüssel sehen.
class FakeFsrsCardStore implements FsrsCardStore {
  final Map<String, GespeicherteKarte> daten = {};

  @override
  GespeicherteKarte? kartenStandFuer(String kursId, String frageId) =>
      daten[FsrsCardStore.schluessel(kursId, frageId)];

  @override
  Map<String, GespeicherteKarte> alleKartenstaende(String kursId) {
    final praefix = '$kursId${FsrsCardStore.trennzeichen}';
    return {
      for (final e in daten.entries)
        if (e.key.startsWith(praefix)) e.key.substring(praefix.length): e.value,
    };
  }

  @override
  Map<String, GespeicherteKarte> alleKartenstaendeRoh() => Map.of(daten);

  @override
  Future<void> speichern(
    String kursId,
    String frageId,
    GespeicherteKarte karte,
  ) async {
    daten[FsrsCardStore.schluessel(kursId, frageId)] = karte;
  }

  @override
  Future<void> speichernRoh(String schluessel, GespeicherteKarte karte) async {
    daten[schluessel] = karte;
  }

  @override
  Future<int> kursLoeschen(String kursId) async {
    final praefix = '$kursId${FsrsCardStore.trennzeichen}';
    final weg = daten.keys.where((k) => k.startsWith(praefix)).toList();
    for (final k in weg) {
      daten.remove(k);
    }
    return weg.length;
  }
}

class FakeAttemptHistoryStore implements AttemptHistoryStore {
  final List<Attempt> eintraege = [];

  @override
  Future<void> anhaengen(Attempt attempt) async => eintraege.add(attempt);

  @override
  List<Attempt> alle() => List.of(eintraege);

  @override
  List<Attempt> fuerKurs(String kursId) =>
      eintraege.where((a) => a.kursId == kursId).toList();

  @override
  Future<int> kursLoeschen(String kursId) async {
    final vorher = eintraege.length;
    eintraege.removeWhere((a) => a.kursId == kursId);
    return vorher - eintraege.length;
  }
}
