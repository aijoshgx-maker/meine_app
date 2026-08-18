// Installieren, Ersetzen und Entfernen von Lernpaketen. Wichtigster Punkt:
// ein erneuter Import darf den Lernfortschritt nicht mitnehmen, ein Entfernen
// schon.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:meine_app/data/kurs_store.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/kurs.dart';
import 'package:meine_app/models/lernpaket.dart';

Frage _frage(String id) => Frage(
  id: id,
  bereich: 'a',
  kategorie: 'K',
  typ: 'single',
  frage: 'F $id',
  optionen: const ['A', 'B'],
  richtigeIndizes: const [0],
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'E',
  schwierigkeit: 1,
);

Lernpaket _paket(String id, List<Frage> fragen) => Lernpaket(
  kurs: Kurs(
    id: id,
    titel: 'Kurs $id',
    kurzbeschreibung: 'Beschreibung',
    version: '1.0.0',
    bereiche: const [Bereich(id: 'a', titel: 'A', gewicht: 1)],
    features: const KursFeatures(pruefungssimulation: true),
    pruefungen: const [PruefungsDefinition(code: 't1', titel: 'Test 1')],
  ),
  fragen: fragen,
);

void main() {
  // Für entfernen(): dort wird path_provider angefasst. Der Zugriff schlägt
  // im Test fehl und wird bewusst geschluckt - die Binding-Initialisierung
  // sorgt nur dafür, dass die Fehlermeldung nicht schon vorher auftritt.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('kurs_store_test');
    Hive.init(tempDir.path);
    await Hive.openBox(KursStore.boxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    tempDir.deleteSync(recursive: true);
  });

  test('installieren und wieder auslesen (Roundtrip)', () async {
    final store = KursStore();
    await store.installieren(_paket('kurs-a', [_frage('f1'), _frage('f2')]));

    expect(store.kennt('kurs-a'), isTrue);
    expect(store.alleIds(), ['kurs-a']);

    final geladen = store.paketFuer('kurs-a')!;
    expect(geladen.kurs.titel, 'Kurs kurs-a');
    expect(geladen.kurs.version, '1.0.0');
    expect(geladen.kurs.quelle, KursQuelle.importiert);
    expect(geladen.kurs.installiertAm, isNotNull);
    expect(geladen.kurs.bereiche.single.gewicht, 1);
    expect(geladen.kurs.pruefungen.single.code, 't1');
    expect(geladen.fragen.map((f) => f.id), ['f1', 'f2']);
  });

  test('kursFuer() liest die Metadaten ohne die Fragen', () async {
    final store = KursStore();
    await store.installieren(_paket('kurs-a', [_frage('f1')]));

    expect(store.kursFuer('kurs-a')?.titel, 'Kurs kurs-a');
    expect(store.kursFuer('gibt-es-nicht'), isNull);
  });

  test('erneutes Installieren ersetzt den Inhalt vollständig', () async {
    final store = KursStore();
    await store.installieren(_paket('kurs-a', [_frage('alt')]));
    await store.installieren(
      _paket('kurs-a', [_frage('neu1'), _frage('neu2')]),
    );

    expect(store.alleIds(), ['kurs-a']);
    expect(store.paketFuer('kurs-a')!.fragen.map((f) => f.id), [
      'neu1',
      'neu2',
    ]);
  });

  test('entfernen löscht den Kurs', () async {
    final store = KursStore();
    await store.installieren(_paket('kurs-a', [_frage('f1')]));
    await store.entfernen('kurs-a');

    expect(store.kennt('kurs-a'), isFalse);
    expect(store.paketFuer('kurs-a'), isNull);
  });

  test('mehrere Kurse stehen unabhängig nebeneinander', () async {
    final store = KursStore();
    await store.installieren(_paket('kurs-a', [_frage('f1')]));
    await store.installieren(_paket('kurs-b', [_frage('f1'), _frage('f2')]));

    expect(
      store.alleKurse().map((k) => k.id),
      containsAll(['kurs-a', 'kurs-b']),
    );
    // Gleiche Frage-id in beiden Kursen ist ausdrücklich erlaubt.
    expect(store.paketFuer('kurs-a')!.fragen, hasLength(1));
    expect(store.paketFuer('kurs-b')!.fragen, hasLength(2));
  });

  test(
    'ohne geöffnete Box meldet der Store schlicht "nichts installiert"',
    () async {
      await Hive.box(KursStore.boxName).close();
      final store = KursStore();

      expect(store.alleIds(), isEmpty);
      expect(store.kennt('kurs-a'), isFalse);
      expect(store.paketFuer('kurs-a'), isNull);
      expect(store.alleKurse(), isEmpty);
    },
  );
}
