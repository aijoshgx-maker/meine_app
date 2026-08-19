// Automatische Wochensicherung.
//
// Der Zweck: Ein manuelles Backup macht man genau dann nicht, wenn man es
// bräuchte. Der Wiederholungsplan wächst über Monate und ist nach einem
// Geräteverlust nicht nachzubauen.
//
// Wichtigste Zusage dieser Tests: Die Sicherung darf den App-Start unter
// keinen Umständen stören - auch nicht, wenn sie selbst scheitert.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/auto_backup.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/data/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory dokumente;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('auto_backup_test');
    Hive.init(tempDir.path);
    await Hive.openBox(FsrsCardStore.boxName);
    await Hive.openBox(AttemptHistoryStore.boxName);
    await Hive.openBox(SettingsStore.boxName);

    // path_provider auf das Testverzeichnis umbiegen.
    dokumente = Directory('${tempDir.path}/docs')..createSync();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dokumente.path,
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Directory backupOrdner() =>
      Directory('${dokumente.path}/${AutoBackup.ordnerName}');

  List<String> sicherungen() {
    final o = backupOrdner();
    if (!o.existsSync()) return const [];
    return o.listSync().whereType<File>().map((f) => f.path).toList()..sort();
  }

  Future<void> einKartenstand() => FsrsCardStore().speichern(
    'kurs-a',
    'f1',
    GespeicherteKarte(card: FsrsCard.newCard(now: DateTime(2026))),
  );

  test('beim allerersten Start wird sofort gesichert', () async {
    await einKartenstand();

    final pfad = await AutoBackup().ausfuehrenWennFaellig(appVersion: '1.2.0');

    expect(pfad, isNotNull);
    expect(sicherungen(), hasLength(1));
    expect(SettingsStore().letztesAutoBackupLaden(), isNotNull);
  });

  test('die Datei enthält einen einlesbaren Lernstand', () async {
    await einKartenstand();
    await AutoBackup().ausfuehrenWennFaellig(appVersion: '1.2.0');

    final inhalt = jsonDecode(File(sicherungen().single).readAsStringSync());
    expect(inhalt['schemaVersion'], isA<int>());
    expect(inhalt['anzahlKarten'], 1);
    expect((inhalt['karten'] as Map).keys.single, 'kurs-a::f1');
  });

  test('innerhalb der Woche passiert nichts', () async {
    await einKartenstand();
    final start = DateTime(2026, 8, 1);

    await AutoBackup().ausfuehrenWennFaellig(appVersion: '1.2.0', jetzt: start);
    expect(sicherungen(), hasLength(1));

    // Sechs Tage später - noch nicht fällig.
    final zweiter = await AutoBackup().ausfuehrenWennFaellig(
      appVersion: '1.2.0',
      jetzt: start.add(const Duration(days: 6)),
    );

    expect(zweiter, isNull);
    expect(sicherungen(), hasLength(1));
  });

  test('nach einer Woche wird erneut gesichert', () async {
    await einKartenstand();
    final start = DateTime(2026, 8, 1);

    await AutoBackup().ausfuehrenWennFaellig(appVersion: '1.2.0', jetzt: start);
    await AutoBackup().ausfuehrenWennFaellig(
      appVersion: '1.2.0',
      jetzt: start.add(const Duration(days: 7)),
    );

    expect(sicherungen(), hasLength(2));
  });

  // Ohne Rotation läuft der Gerätespeicher über Jahre voll.
  test('es bleiben höchstens vier Sicherungen übrig', () async {
    await einKartenstand();
    var tag = DateTime(2026, 8, 1);

    for (var i = 0; i < 7; i++) {
      await AutoBackup().ausfuehrenWennFaellig(appVersion: '1.2.0', jetzt: tag);
      tag = tag.add(const Duration(days: 7));
    }

    final uebrig = sicherungen();
    expect(uebrig, hasLength(AutoBackup.maxDateien));

    // Und zwar die NEUESTEN - der Dateiname trägt den Zeitstempel.
    expect(uebrig.last, contains('2026-09-12'));
  });

  test('istFaellig richtet sich nach dem gespeicherten Zeitpunkt', () async {
    final backup = AutoBackup();
    final jetzt = DateTime(2026, 8, 19);

    expect(backup.istFaellig(jetzt), isTrue, reason: 'noch nie gesichert');

    await SettingsStore().letztesAutoBackupSpeichern(
      jetzt.subtract(const Duration(days: 3)),
    );
    expect(backup.istFaellig(jetzt), isFalse);

    await SettingsStore().letztesAutoBackupSpeichern(
      jetzt.subtract(const Duration(days: 8)),
    );
    expect(backup.istFaellig(jetzt), isTrue);
  });

  // Die Kernzusage: Der App-Start darf nie an der Sicherung scheitern.
  test('ein Fehler wird geschluckt statt geworfen', () async {
    // Zielverzeichnis durch eine Datei blockieren - das Schreiben scheitert.
    File(backupOrdner().path).writeAsStringSync('kein Ordner');

    final pfad = await AutoBackup().ausfuehrenWennFaellig(appVersion: '1.2.0');

    expect(pfad, isNull);
    // Und der Zeitstempel bleibt unangetastet, damit es beim nächsten Start
    // wieder versucht wird.
    expect(SettingsStore().letztesAutoBackupLaden(), isNull);
  });
}
