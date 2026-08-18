// Die Migration auf das Mehrkurs-Schema fasst echten Lernfortschritt an.
// Geht sie schief, verlieren Bestandsnutzer ihre Wiederholungsplanung -
// deshalb hier besonders gründlich, inklusive Abbruch mittendrin.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/data/migrationen.dart';
import 'package:meine_app/data/settings_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('migrationen_test');
    Hive.init(tempDir.path);
    await Hive.openBox(FsrsCardStore.boxName);
    await Hive.openBox(AttemptHistoryStore.boxName);
    await Hive.openBox(SettingsStore.boxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    tempDir.deleteSync(recursive: true);
  });

  /// Legt einen Kartenstand im alten Schema an (Schlüssel = nur Frage-id).
  Future<void> alteKarte(String frageId, {int reps = 0}) async {
    await Hive.box(FsrsCardStore.boxName).put(
      frageId,
      GespeicherteKarte(
        card: FsrsCard.newCard(now: DateTime(2026)).copyWith(reps: reps),
      ).toMap(),
    );
  }

  Future<void> alterVersuch(String frageId) async {
    await Hive.box(AttemptHistoryStore.boxName).add({
      'frageId': frageId,
      'zeitpunkt': DateTime(2026).toIso8601String(),
      'konfidenz': 'sicher',
      'korrekt': true,
      'bereich': 'wiso',
      'kategorie': 'Entgelt',
      'selbsterklaerung': null,
    });
  }

  test('schlüsselt Bestandskarten auf den Bestandskurs um', () async {
    await alteKarte('au-tz-001', reps: 4);
    await alteKarte('ft-sd-005');

    final gelaufen = await Migrationen().ausfuehren();
    expect(gelaufen, 1);

    final store = FsrsCardStore();
    final karten = store.alleKartenstaende(Migrationen.bestandsKursId);

    expect(karten.keys, containsAll(['au-tz-001', 'ft-sd-005']));
    // Der FSRS-Stand muss unverändert übernommen werden - sonst ist die
    // Wiederholungsplanung zurückgesetzt.
    expect(karten['au-tz-001']!.card.reps, 4);

    // Die alten, unpräfixierten Schlüssel dürfen nicht zurückbleiben.
    expect(Hive.box(FsrsCardStore.boxName).containsKey('au-tz-001'), isFalse);
  });

  test('ergänzt fehlende kursId im Verlauf', () async {
    await alterVersuch('au-tz-001');

    await Migrationen().ausfuehren();

    final versuche = AttemptHistoryStore().alle();
    expect(versuche, hasLength(1));
    expect(versuche.single.kursId, Migrationen.bestandsKursId);
    expect(
      AttemptHistoryStore().fuerKurs(Migrationen.bestandsKursId),
      hasLength(1),
    );
  });

  test('läuft nur einmal', () async {
    await alteKarte('au-tz-001');

    expect(await Migrationen().ausfuehren(), 1);
    expect(await Migrationen().ausfuehren(), 0);
    expect(SettingsStore().datenVersionLaden(), Migrationen.aktuelleVersion);
  });

  // Wird die App mitten in der Migration beendet, läuft sie beim nächsten
  // Start erneut - dabei darf ein bereits umgeschlüsselter Stand nicht durch
  // einen alten Rest überschrieben werden.
  test('ein Abbruch mittendrin ist unschädlich', () async {
    final box = Hive.box(FsrsCardStore.boxName);

    // Zustand nach halb gelaufener Migration: neuer Schlüssel existiert
    // bereits mit fortgeschrittenem Stand, alter Schlüssel liegt noch da.
    await box.put(
      FsrsCardStore.schluessel(Migrationen.bestandsKursId, 'au-tz-001'),
      GespeicherteKarte(
        card: FsrsCard.newCard(now: DateTime(2026)).copyWith(reps: 9),
      ).toMap(),
    );
    await alteKarte('au-tz-001', reps: 1);

    await Migrationen().ausfuehren();

    final karten = FsrsCardStore().alleKartenstaende(
      Migrationen.bestandsKursId,
    );
    expect(
      karten['au-tz-001']!.card.reps,
      9,
      reason: 'Der bereits migrierte Stand darf nicht überschrieben werden.',
    );
    expect(box.containsKey('au-tz-001'), isFalse);
  });

  test('bereits partitionierte Karten bleiben unangetastet', () async {
    await FsrsCardStore().speichern(
      'ein-anderer-kurs',
      'f1',
      GespeicherteKarte(card: FsrsCard.newCard(now: DateTime(2026))),
    );

    await Migrationen().ausfuehren();

    expect(
      FsrsCardStore().kartenStandFuer('ein-anderer-kurs', 'f1'),
      isNotNull,
    );
    expect(
      FsrsCardStore().alleKartenstaende(Migrationen.bestandsKursId),
      isEmpty,
    );
  });

  test('leere Boxen sind kein Problem', () async {
    expect(await Migrationen().ausfuehren(), 1);
    expect(FsrsCardStore().alleKartenstaendeRoh(), isEmpty);
  });
}
