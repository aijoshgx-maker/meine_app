import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/app/settings_providers.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/data/settings_store.dart';
import 'package:meine_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/kurs.dart';

import 'hilfen/test_kurs.dart';

class _FakeSettingsStore implements SettingsStore {
  _FakeSettingsStore({this.neueProTag = SettingsStore.neueProTagStandard});

  @override
  String? themeModeLaden() => null;

  @override
  Future<void> themeModeSpeichern(String wert) async {}

  @override
  bool remindersAktiviert() => false;

  @override
  Future<void> remindersAktiviertSpeichern(bool aktiviert) async {}

  @override
  String? aktiverKursLaden() => testKursId;

  @override
  Future<void> aktiverKursSpeichern(String kursId) async {}

  @override
  int datenVersionLaden() => 1;

  @override
  Future<void> datenVersionSpeichern(int version) async {}

  DateTime? _letztesAutoBackup;

  @override
  DateTime? letztesAutoBackupLaden() => _letztesAutoBackup;

  @override
  Future<void> letztesAutoBackupSpeichern(DateTime zeitpunkt) async {
    _letztesAutoBackup = zeitpunkt;
  }

  int neueProTag;

  @override
  int neueProTagLaden() => neueProTag;

  @override
  Future<void> neueProTagSpeichern(int anzahl) async {
    neueProTag = anzahl;
  }

  bool _steigendeSchwierigkeit = true;

  @override
  bool steigendeSchwierigkeitLaden() => _steigendeSchwierigkeit;

  @override
  Future<void> steigendeSchwierigkeitSpeichern(bool aktiv) async {
    _steigendeSchwierigkeit = aktiv;
  }
}

Frage _frage(String id, String kategorie) => Frage(
  id: id,
  bereich: 'allgemein',
  kategorie: kategorie,
  typ: 'single',
  frage: 'Testfrage $id',
  optionen: const ['A', 'B'],
  richtigeIndizes: const [0],
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'Weil.',
  schwierigkeit: 1,
);

Widget _app({
  required FakeFsrsCardStore karten,
  required FakeAttemptHistoryStore verlauf,
  required List<Frage> fragen,
  Kurs? kurs,
  int neueProTag = SettingsStore.neueProTagStandard,
}) => ProviderScope(
  overrides: [
    fsrsCardStoreProvider.overrideWithValue(karten),
    attemptHistoryStoreProvider.overrideWithValue(verlauf),
    settingsStoreProvider.overrideWithValue(
      _FakeSettingsStore(neueProTag: neueProTag),
    ),
    aktivesPaketProvider.overrideWith(
      (_) async => testPaket(fragen, kurs: kurs),
    ),
  ],
  child: const MaterialApp(home: DashboardScreen()),
);

void main() {
  testWidgets('Dashboard rendert alle Kennzahlen ohne Fehler (leere Daten)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        karten: FakeFsrsCardStore(),
        verlauf: FakeAttemptHistoryStore(),
        fragen: [_frage('f1', 'Thema A')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Frei üben'), findsOneWidget);
    expect(find.text('Heute fällig'), findsOneWidget);
    expect(find.text('Thema vertiefen'), findsOneWidget);

    for (final text in [
      'Behaltensquote',
      'Lernstand',
      'Konfidenz-Kalibrierung',
      'Schwache Themen',
    ]) {
      await tester.dragUntilVisible(
        find.text(text),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text(text), findsOneWidget);
    }
  });

  // Der leere Fall verdeckte bisher, dass die Auswertungen mit echten Daten
  // gar nicht durchlaufen - dieser Test schließt die Lücke.
  testWidgets('Dashboard rendert mit vorhandenem Lernfortschritt', (
    tester,
  ) async {
    final karten = FakeFsrsCardStore();
    final verlauf = FakeAttemptHistoryStore();
    final jetzt = DateTime.now();

    await karten.speichern(
      testKursId,
      'f1',
      GespeicherteKarte(card: FsrsCard.newCard(now: jetzt)),
    );
    verlauf.eintraege.addAll([
      Attempt(
        kursId: testKursId,
        frageId: 'f1',
        zeitpunkt: jetzt,
        konfidenz: Konfidenz.sicher,
        korrekt: false,
        bereich: 'allgemein',
        kategorie: 'Thema A',
      ),
      Attempt(
        kursId: testKursId,
        frageId: 'f2',
        zeitpunkt: jetzt,
        konfidenz: Konfidenz.unsicher,
        korrekt: true,
        bereich: 'allgemein',
        kategorie: 'Thema B',
      ),
    ]);

    await tester.pumpWidget(
      _app(
        karten: karten,
        verlauf: verlauf,
        fragen: [_frage('f1', 'Thema A'), _frage('f2', 'Thema B')],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Die Kalibrierungs-Karte liegt unterhalb des sichtbaren Bereichs.
    await tester.dragUntilVisible(
      find.text('Hochkonfident falsch: 1'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Hochkonfident falsch: 1'), findsOneWidget);
  });

  testWidgets('Testlauf-Knopf fehlt, wenn der Kurs keinen anbietet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        karten: FakeFsrsCardStore(),
        verlauf: FakeAttemptHistoryStore(),
        fragen: [_frage('f1', 'Thema A')],
        kurs: testKurs(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Testlauf'), findsNothing);
    expect(find.text('Dialog'), findsNothing);
  });

  // Die Pensum-Karte ist der einzige Ort, an dem die Aufteilung sichtbar
  // wird. Eine reine Gesamtzahl sagte nicht, ob heute wiederholt oder neu
  // gelernt wird - und genau das entscheidet, wie anstrengend es wird.
  group('Pensum-Karte', () {
    final jetzt = DateTime.now();

    GespeicherteKarte stand(Duration faelligIn) => GespeicherteKarte(
      card: FsrsCard.newCard(now: jetzt).copyWith(due: jetzt.add(faelligIn)),
    );

    testWidgets('zeigt Wiederholungen und neue Karten getrennt', (
      tester,
    ) async {
      final karten = FakeFsrsCardStore();
      await karten.speichern(testKursId, 'f1', stand(const Duration(days: -1)));

      await tester.pumpWidget(
        _app(
          karten: karten,
          verlauf: FakeAttemptHistoryStore(),
          fragen: [
            _frage('f1', 'Thema A'),
            _frage('f2', 'Thema B'),
            _frage('f3', 'Thema B'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heute 3 Karten'), findsOneWidget);
      expect(find.text('1 Wiederholung · 2 neu'), findsOneWidget);
    });

    testWidgets('meldet Feierabend, wenn nichts mehr offen ist', (
      tester,
    ) async {
      final karten = FakeFsrsCardStore();
      await karten.speichern(testKursId, 'f1', stand(const Duration(days: 3)));

      await tester.pumpWidget(
        _app(
          karten: karten,
          verlauf: FakeAttemptHistoryStore(),
          fragen: [_frage('f1', 'Thema A')],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Heute nichts mehr offen – gut gemacht!'),
        findsOneWidget,
      );
    });

    // Aufgestaute Wiederholungen werden genannt, aber nicht ins Pensum
    // geschlagen - sonst steht man nach einer Woche Pause vor 300 Karten
    // und fängt gar nicht erst an.
    testWidgets('nennt zurückgestellte Wiederholungen separat', (
      tester,
    ) async {
      final karten = FakeFsrsCardStore();
      final fragen = [for (var i = 0; i < 25; i++) _frage('f$i', 'Thema A')];
      for (final f in fragen) {
        await karten.speichern(
          testKursId,
          f.id,
          stand(const Duration(days: -1)),
        );
      }

      await tester.pumpWidget(
        _app(
          karten: karten,
          verlauf: FakeAttemptHistoryStore(),
          fragen: fragen,
          neueProTag: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heute 20 Karten'), findsOneWidget);
      expect(find.text('20 Wiederholungen'), findsOneWidget);
      expect(
        find.text('5 weitere warten auf die nächsten Tage'),
        findsOneWidget,
      );
    });
  });
}
