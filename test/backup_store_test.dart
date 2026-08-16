import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/backup_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/data/settings_store.dart';
import 'package:meine_app/models/konfidenz.dart';

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
        'au-tz-001',
        GespeicherteKarte(card: FsrsCard.newCard(now: jetzt)),
      );
      await kartenStore.speichern(
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
      final exportiert = backupStore.erstellen(appVersion: '1.1.0');
      final jsonRoundtrip = BackupDaten.fromJson(exportiert.toJson());
      expect(jsonRoundtrip.anzahlKarten, 2);
      expect(jsonRoundtrip.verlauf, hasLength(1));

      // Lernstand "verlieren" (frisches Gerät simulieren).
      await Hive.box(FsrsCardStore.boxName).clear();
      await Hive.box(AttemptHistoryStore.boxName).clear();
      expect(kartenStore.alleKartenstaende(), isEmpty);

      final ergebnis = await backupStore.importieren(
        jsonRoundtrip,
        modus: ImportModus.ersetzen,
        bekannteFrageIds: {'au-tz-001', 'ft-sd-005'},
      );

      expect(ergebnis.importiert, 2);
      expect(ergebnis.uebersprungenUnbekannt, 0);
      expect(ergebnis.verlaufHinzugefuegt, 1);

      final wiederhergestellt = kartenStore.alleKartenstaende();
      expect(wiederhergestellt.keys, containsAll(['au-tz-001', 'ft-sd-005']));
      expect(wiederhergestellt['ft-sd-005']!.hochkonfidentFalsch, isTrue);
      expect(wiederhergestellt['ft-sd-005']!.card.reps, 3);
      expect(verlaufStore.alle(), hasLength(1));
      expect(einstellungenStore.themeModeLaden(), 'dark');
      expect(einstellungenStore.remindersAktiviert(), isTrue);
    },
  );

  test('Import überspringt unbekannte Frage-IDs und zählt sie', () async {
    final kartenStore = FsrsCardStore();
    final backupStore = BackupStore(kartenStore: kartenStore);
    final jetzt = DateTime(2026, 1, 15);

    final daten = BackupDaten(
      schemaVersion: backupSchemaVersion,
      exportiertAm: jetzt,
      appVersion: '1.0.0',
      karten: {
        'noch-vorhanden': GespeicherteKarte(
          card: FsrsCard.newCard(now: jetzt),
        ).toMap(),
        'geloeschte-frage-xyz': GespeicherteKarte(
          card: FsrsCard.newCard(now: jetzt),
        ).toMap(),
      },
      verlauf: const [],
      einstellungen: const {},
    );

    final ergebnis = await backupStore.importieren(
      daten,
      modus: ImportModus.ersetzen,
      bekannteFrageIds: {'noch-vorhanden'},
    );

    expect(ergebnis.importiert, 1);
    expect(ergebnis.uebersprungenUnbekannt, 1);
    expect(kartenStore.kartenStandFuer('geloeschte-frage-xyz'), isNull);
  });

  test('Zusammenführen: jüngeres "due" gewinnt', () async {
    final kartenStore = FsrsCardStore();
    final backupStore = BackupStore(kartenStore: kartenStore);
    final jetzt = DateTime(2026, 1, 15);

    // Lokal: due in 5 Tagen (weiter fortgeschritten).
    await kartenStore.speichern(
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
        'au-tz-001': GespeicherteKarte(
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
      bekannteFrageIds: {'au-tz-001'},
    );

    // Lokaler (jüngerer) Stand muss erhalten bleiben.
    final stand = kartenStore.kartenStandFuer('au-tz-001')!;
    expect(stand.card.due, jetzt.add(const Duration(days: 5)));
  });
}
