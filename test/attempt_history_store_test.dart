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
}
