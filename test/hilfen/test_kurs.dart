// Gemeinsames Test-Gerüst für die Mehrkurs-Architektur: ein minimaler Kurs
// plus In-Memory-Fakes der beiden Hive-gestützten Stores.
//
// Ohne das müsste jeder Test seinen eigenen Kurs zusammenbauen und dabei die
// Schlüsselkonvention "kursId::frageId" nachbilden.

import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/data/settings_store.dart';
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
  int bearbeiteteAm(String kursId, DateTime tag) {
    final erster = <String, DateTime>{};
    for (final a in fuerKurs(kursId)) {
      final bisher = erster[a.frageId];
      if (bisher == null || a.zeitpunkt.isBefore(bisher)) {
        erster[a.frageId] = a.zeitpunkt;
      }
    }
    return erster.values
        .where(
          (z) =>
              z.year == tag.year && z.month == tag.month && z.day == tag.day,
        )
        .length;
  }

  @override
  Future<int> kursLoeschen(String kursId) async {
    final vorher = eintraege.length;
    eintraege.removeWhere((a) => a.kursId == kursId);
    return vorher - eintraege.length;
  }
}

/// In-Memory-Ersatz fuer den Hive-gestuetzten Einstellungsspeicher.
///
/// Braucht jeder Test, der eine Quiz-Session aufbaut: Der Sessionaufbau liest
/// den Schalter fuer die steigende Schwierigkeit, und ohne Override liefe das
/// gegen eine nicht geoeffnete Hive-Box.
class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore({
    this.kartenProTag = SettingsStore.kartenProTagStandard,
    this.steigendeSchwierigkeit = true,
  });

  int kartenProTag;
  bool steigendeSchwierigkeit;
  String? _themeMode;
  bool _reminders = false;
  String? _aktiverKurs = testKursId;
  int _datenVersion = 1;
  DateTime? _letztesAutoBackup;

  @override
  String? themeModeLaden() => _themeMode;

  @override
  Future<void> themeModeSpeichern(String wert) async => _themeMode = wert;

  @override
  bool remindersAktiviert() => _reminders;

  @override
  Future<void> remindersAktiviertSpeichern(bool aktiviert) async =>
      _reminders = aktiviert;

  @override
  String? aktiverKursLaden() => _aktiverKurs;

  @override
  Future<void> aktiverKursSpeichern(String kursId) async =>
      _aktiverKurs = kursId;

  @override
  int datenVersionLaden() => _datenVersion;

  @override
  Future<void> datenVersionSpeichern(int version) async =>
      _datenVersion = version;

  @override
  DateTime? letztesAutoBackupLaden() => _letztesAutoBackup;

  @override
  Future<void> letztesAutoBackupSpeichern(DateTime zeitpunkt) async =>
      _letztesAutoBackup = zeitpunkt;

  @override
  int kartenProTagLaden() => kartenProTag;

  @override
  Future<void> kartenProTagSpeichern(int anzahl) async => kartenProTag = anzahl;

  @override
  bool steigendeSchwierigkeitLaden() => steigendeSchwierigkeit;

  @override
  Future<void> steigendeSchwierigkeitSpeichern(bool aktiv) async =>
      steigendeSchwierigkeit = aktiv;
}
