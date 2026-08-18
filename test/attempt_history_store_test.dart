import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/models/konfidenz.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('attempt_history_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AttemptHistoryStore.boxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'anhaengen() ist append-only und alle() liest in Schreibreihenfolge',
    () async {
      final store = AttemptHistoryStore();
      final jetzt = DateTime.now();

      await store.anhaengen(
        Attempt(
          kursId: 'ap2-industriemechaniker',
          frageId: 'ft-101',
          zeitpunkt: jetzt,
          konfidenz: Konfidenz.sicher,
          korrekt: true,
          bereich: 'fertigungstechnik',
          kategorie: 'Zerspanung',
        ),
      );
      await store.anhaengen(
        Attempt(
          kursId: 'ap2-industriemechaniker',
          frageId: 'wiso-101',
          zeitpunkt: jetzt.add(const Duration(minutes: 1)),
          konfidenz: Konfidenz.geraten,
          korrekt: false,
          bereich: 'wiso',
          kategorie: 'Berufsausbildung',
          selbsterklaerung: 'War mir nicht sicher.',
        ),
      );

      final alle = store.alle();

      expect(alle, hasLength(2));
      expect(alle[0].frageId, 'ft-101');
      expect(alle[0].konfidenz, Konfidenz.sicher);
      expect(alle[0].korrekt, true);
      expect(alle[0].selbsterklaerung, isNull);
      expect(alle[1].frageId, 'wiso-101');
      expect(alle[1].selbsterklaerung, 'War mir nicht sicher.');
    },
  );

  test('fuerKurs() filtert auf genau einen Kurs', () async {
    final store = AttemptHistoryStore();
    final jetzt = DateTime.now();

    Attempt fuer(String kursId, String frageId) => Attempt(
      kursId: kursId,
      frageId: frageId,
      zeitpunkt: jetzt,
      konfidenz: Konfidenz.sicher,
      korrekt: true,
      bereich: 'b',
      kategorie: 'k',
    );

    await store.anhaengen(fuer('kurs-a', 'f1'));
    await store.anhaengen(fuer('kurs-b', 'f2'));
    await store.anhaengen(fuer('kurs-a', 'f3'));

    expect(store.fuerKurs('kurs-a').map((a) => a.frageId), ['f1', 'f3']);
    expect(store.fuerKurs('kurs-b'), hasLength(1));

    expect(await store.kursLoeschen('kurs-a'), 2);
    expect(store.alle(), hasLength(1));
  });
}
