import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/backup_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/data/migrationen.dart';
import 'package:meine_app/data/settings_store.dart';
import 'package:meine_app/models/konfidenz.dart';

const _kurs = 'ap2-industriemechaniker';
String _s(String frageId, [String kursId = _kurs]) =>
    FsrsCardStore.schluessel(kursId, frageId);

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('backup_store_test');
    Hive.init(tempDir.path);
    await Hive.openBox(FsrsCardStore.boxName);
    await Hive.openBox(AttemptHistoryStore.boxName);
    await Hive.openBox(SettingsStore.boxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'Export -> JSON-Roundtrip -> Import (ersetzen) liefert identischen Zustand',
    () async {
      final kartenStore = FsrsCardStore();
      final verlaufStore = AttemptHistoryStore();
      final einstellungenStore = SettingsStore();
      final backupStore = BackupStore(
        kartenStore: kartenStore,
        verlaufStore: verlaufStore,
        einstellungenStore: einstellungenStore,
      );

      final jetzt = DateTime(2026, 1, 15, 10, 30);
      await kartenStore.speichern(
        _kurs,
        'au-tz-001',
        GespeicherteKarte(card: FsrsCard.newCard(now: jetzt)),
      );
      await kartenStore.speichern(
        _kurs,
        'ft-sd-005',
        GespeicherteKarte(
          card: FsrsCard.newCard(
            now: jetzt,
          ).copyWith(due: jetzt.add(const Duration(days: 10)), reps: 3),
          hochkonfidentFalsch: true,
        ),
      );
      await verlaufStore.anhaengen(
        Attempt(
          kursId: _kurs,
          frageId: 'au-tz-001',
          zeitpunkt: jetzt,
          konfidenz: Konfidenz.sicher,
          korrekt: true,
          bereich: 'auftragsanalyse',
          kategorie: 'Technisches Zeichnen',
        ),
      );
      await einstellungenStore.themeModeSpeichern('dark');
      await einstellungenStore.remindersAktiviertSpeichern(true);

      // Export -> über JSON hin und her (wie beim echten Datei-Export/Import).
      final exportiert = backupStore.erstellen(appVersion: '1.2.0');
      final jsonRoundtrip = BackupDaten.fromJson(exportiert.toJson());
      expect(jsonRoundtrip.anzahlKarten, 2);
      expect(jsonRoundtrip.verlauf, hasLength(1));

      // Lernstand "verlieren" (frisches Gerät simulieren).
      await Hive.box(FsrsCardStore.boxName).clear();
      await Hive.box(AttemptHistoryStore.boxName).clear();
      expect(kartenStore.alleKartenstaende(_kurs), isEmpty);

      final ergebnis = await backupStore.importieren(
        jsonRoundtrip,
        modus: ImportModus.ersetzen,
        bekannteSchluessel: {_s('au-tz-001'), _s('ft-sd-005')},
      );

      expect(ergebnis.importiert, 2);
      expect(ergebnis.uebersprungenUnbekannt, 0);
      expect(ergebnis.verlaufHinzugefuegt, 1);

      final wiederhergestellt = kartenStore.alleKartenstaende(_kurs);
      expect(wiederhergestellt.keys, containsAll(['au-tz-001', 'ft-sd-005']));
      expect(wiederhergestellt['ft-sd-005']!.hochkonfidentFalsch, isTrue);
      expect(wiederhergestellt['ft-sd-005']!.card.reps, 3);
      expect(verlaufStore.alle(), hasLength(1));
      expect(verlaufStore.alle().first.kursId, _kurs);
      expect(einstellungenStore.themeModeLaden(), 'dark');
      expect(einstellungenStore.remindersAktiviert(), isTrue);
    },
  );

  test('Import überspringt unbekannte Karten und zählt sie', () async {
    final kartenStore = FsrsCardStore();
    final backupStore = BackupStore(kartenStore: kartenStore);
    final jetzt = DateTime(2026, 1, 15);

    final daten = BackupDaten(
      schemaVersion: backupSchemaVersion,
      exportiertAm: jetzt,
      appVersion: '1.0.0',
      karten: {
        _s('noch-vorhanden'): GespeicherteKarte(
          card: FsrsCard.newCard(now: jetzt),
        ).toMap(),
        _s('geloeschte-frage-xyz'): GespeicherteKarte(
          card: FsrsCard.newCard(now: jetzt),
        ).toMap(),
        // Karte eines gar nicht installierten Kurses.
        _s('f1', 'fremder-kurs'): GespeicherteKarte(
          card: FsrsCard.newCard(now: jetzt),
        ).toMap(),
      },
      verlauf: const [],
      einstellungen: const {},
    );

    final ergebnis = await backupStore.importieren(
      daten,
      modus: ImportModus.ersetzen,
      bekannteSchluessel: {_s('noch-vorhanden')},
    );

    expect(ergebnis.importiert, 1);
    expect(ergebnis.uebersprungenUnbekannt, 2);
    expect(kartenStore.kartenStandFuer(_kurs, 'geloeschte-frage-xyz'), isNull);
    expect(kartenStore.kartenStandFuer('fremder-kurs', 'f1'), isNull);
  });

  test('Zusammenführen: jüngeres "due" gewinnt', () async {
    final kartenStore = FsrsCardStore();
    final backupStore = BackupStore(kartenStore: kartenStore);
    final jetzt = DateTime(2026, 1, 15);

    // Lokal: due in 5 Tagen (weiter fortgeschritten).
    await kartenStore.speichern(
      _kurs,
      'au-tz-001',
      GespeicherteKarte(
        card: FsrsCard.newCard(
          now: jetzt,
        ).copyWith(due: jetzt.add(const Duration(days: 5))),
      ),
    );

    // Import: due nur in 1 Tag (älterer/weniger fortgeschrittener Stand).
    final daten = BackupDaten(
      schemaVersion: backupSchemaVersion,
      exportiertAm: jetzt,
      appVersion: '1.0.0',
      karten: {
        _s('au-tz-001'): GespeicherteKarte(
          card: FsrsCard.newCard(
            now: jetzt,
          ).copyWith(due: jetzt.add(const Duration(days: 1))),
        ).toMap(),
      },
      verlauf: const [],
      einstellungen: const {},
    );

    await backupStore.importieren(
      daten,
      modus: ImportModus.zusammenfuehren,
      bekannteSchluessel: {_s('au-tz-001')},
    );

    // Lokaler (jüngerer) Stand muss erhalten bleiben.
    final stand = kartenStore.kartenStandFuer(_kurs, 'au-tz-001')!;
    expect(stand.card.due, jetzt.add(const Duration(days: 5)));
  });

  // Ein Backup aus der Zeit vor der Mehrkurs-Fähigkeit muss weiter einlesbar
  // sein - sonst verlieren Bestandsnutzer beim Update ihren gesicherten Stand.
  test('Backup der Version 1 wird auf den Bestandskurs umgeschrieben', () {
    final jetzt = DateTime(2026, 1, 15);

    final altesBackup = {
      'schemaVersion': 1,
      'exportiertAm': jetzt.toIso8601String(),
      'appVersion': '1.1.0',
      'karten': {
        'au-tz-001': GespeicherteKarte(
          card: FsrsCard.newCard(now: jetzt),
        ).toMap(),
      },
      'verlauf': [
        {
          'frageId': 'au-tz-001',
          'zeitpunkt': jetzt.toIso8601String(),
          'konfidenz': 'sicher',
          'korrekt': true,
          'bereich': 'auftragsanalyse',
          'kategorie': 'Technisches Zeichnen',
          'selbsterklaerung': null,
        },
      ],
      'einstellungen': const {},
    };

    final daten = BackupDaten.fromJson(altesBackup);

    expect(daten.karten.keys.single, _s('au-tz-001'));
    expect(daten.verlauf.single['kursId'], Migrationen.bestandsKursId);
  });

  test('Backup mit zu neuer Schemaversion wird abgelehnt', () {
    expect(
      () => BackupDaten.fromJson({
        'schemaVersion': backupSchemaVersion + 1,
        'exportiertAm': DateTime(2026).toIso8601String(),
        'karten': const {},
        'verlauf': const [],
      }),
      throwsFormatException,
    );
  });
}
