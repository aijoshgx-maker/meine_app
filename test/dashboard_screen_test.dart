import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meine_app/app/settings_providers.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/data/settings_store.dart';
import 'package:meine_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:meine_app/features/dashboard/providers/dashboard_providers.dart'
    show pruefungsreifeHorizontTage;
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/kurs.dart';

import 'hilfen/test_kurs.dart';

class _FakeSettingsStore implements SettingsStore {
  _FakeSettingsStore({this.kartenProTag = SettingsStore.kartenProTagStandard});

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

  int kartenProTag;

  @override
  int kartenProTagLaden() => kartenProTag;

  @override
  Future<void> kartenProTagSpeichern(int anzahl) async {
    kartenProTag = anzahl;
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
  int kartenProTag = SettingsStore.kartenProTagStandard,
}) => ProviderScope(
  overrides: [
    fsrsCardStoreProvider.overrideWithValue(karten),
    attemptHistoryStoreProvider.overrideWithValue(verlauf),
    settingsStoreProvider.overrideWithValue(
      _FakeSettingsStore(kartenProTag: kartenProTag),
    ),
    aktivesPaketProvider.overrideWith(
      (_) async => testPaket(fragen, kurs: kurs),
    ),
  ],
  child: MaterialApp.router(routerConfig: _router()),
);

/// Minimaler Router: Das Dashboard navigiert per context.go, ein nacktes
/// MaterialApp waere dafuer kein tragfaehiger Untergrund. Statt des echten
/// Quiz steht am Ziel ein Erkennungszeichen.
GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
    GoRoute(path: '/quiz', builder: (_, _) => const Text(_quizMarke)),
  ],
);

const _quizMarke = 'QUIZ-SESSION';

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

    /// Karte, die mit „Nochmal" zurückgelegt wurde.
    GespeicherteKarte zurueckgelegt() => GespeicherteKarte(
      card: FsrsCard.newCard(now: jetzt),
      nochmal: true,
    );

    /// Erledigte Karte - sie kommt nicht von selbst wieder.
    GespeicherteKarte erledigt() =>
        GespeicherteKarte(card: FsrsCard.newCard(now: jetzt));

    testWidgets('zeigt Neues und Zurückgelegtes getrennt', (tester) async {
      final karten = FakeFsrsCardStore();
      await karten.speichern(testKursId, 'f1', zurueckgelegt());

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
      expect(find.text('2 neu · 1 zurückgelegt'), findsOneWidget);
    });

    testWidgets('meldet Feierabend, wenn nichts mehr offen ist', (
      tester,
    ) async {
      final karten = FakeFsrsCardStore();
      await karten.speichern(testKursId, 'f1', erledigt());

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

    // Erledigtes bleibt erledigt: Ohne "Nochmal" gibt es keinen Grund, eine
    // Karte wiederzusehen.
    testWidgets('erledigte Karten stauen sich nicht auf', (tester) async {
      final karten = FakeFsrsCardStore();
      final fragen = [for (var i = 0; i < 80; i++) _frage('f$i', 'Thema A')];
      for (final f in fragen) {
        await karten.speichern(testKursId, f.id, erledigt());
      }

      await tester.pumpWidget(
        _app(
          karten: karten,
          verlauf: FakeAttemptHistoryStore(),
          fragen: fragen,
          kartenProTag: 20,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Heute nichts mehr offen – gut gemacht!'),
        findsOneWidget,
      );
    });

    testWidgets('ein Tippen führt direkt in die Session', (tester) async {
      final karten = FakeFsrsCardStore();
      await karten.speichern(testKursId, 'f1', zurueckgelegt());

      await tester.pumpWidget(
        _app(
          karten: karten,
          verlauf: FakeAttemptHistoryStore(),
          fragen: [_frage('f1', 'Thema A')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heute 1 Karte'));
      await tester.pumpAndSettle();

      expect(find.text(_quizMarke), findsOneWidget);
    });

    // Ein Tippen, das in eine leere Session führt, wäre ein leeres
    // Versprechen.
    testWidgets('erledigt ist die Karte nicht antippbar', (tester) async {
      final karten = FakeFsrsCardStore();
      await karten.speichern(testKursId, 'f1', erledigt());

      await tester.pumpWidget(
        _app(
          karten: karten,
          verlauf: FakeAttemptHistoryStore(),
          fragen: [_frage('f1', 'Thema A')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heute nichts mehr offen – gut gemacht!'));
      await tester.pumpAndSettle();

      expect(find.text(_quizMarke), findsNothing);
    });
  });

  // Die Beschriftungen standen einmal unter einer gemeinsamen Achse und
  // ueberlappten sich, sobald ein Kategoriename laenger war als sein
  // Saeulenabstand. Jetzt gehoert jede zu genau einem Balken.
  group('Beschriftungen', () {
    const langeKategorie = 'Werkzeugmaschinen und Vorrichtungen';
    const zweiteKategorie = 'Technische Berechnungen und Formeln';

    Future<void> pumpeMitThemen(WidgetTester tester) async {
      final verlauf = FakeAttemptHistoryStore();
      final jetzt = DateTime.now();
      for (final (kategorie, korrekt) in [
        (langeKategorie, false),
        (langeKategorie, false),
        (zweiteKategorie, false),
        (zweiteKategorie, true),
      ]) {
        verlauf.eintraege.add(
          Attempt(
            kursId: testKursId,
            frageId: 'f-$kategorie-$korrekt',
            zeitpunkt: jetzt,
            konfidenz: Konfidenz.sicher,
            korrekt: korrekt,
            bereich: 'allgemein',
            kategorie: kategorie,
          ),
        );
      }

      await tester.pumpWidget(
        _app(
          karten: FakeFsrsCardStore(),
          verlauf: verlauf,
          fragen: [_frage('f1', langeKategorie)],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('jeder Balken trägt seinen eigenen Namen und Wert', (
      tester,
    ) async {
      await pumpeMitThemen(tester);

      await tester.dragUntilVisible(
        find.text('Schwache Themen'),
        find.byType(ListView),
        const Offset(0, -300),
      );

      // Vollständiger Name, nicht auf eine Achsenbeschriftung eingedampft.
      expect(find.text(langeKategorie), findsOneWidget);
      expect(find.text(zweiteKategorie), findsOneWidget);
      expect(find.text('100 %'), findsWidgets);
      expect(find.text('50 %'), findsWidgets);

      // Eine Quote ohne ihre Grundgesamtheit ist leicht misszuverstehen.
      expect(find.text('2 Versuche'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('der Lernstand nennt seinen Horizont', (tester) async {
      await pumpeMitThemen(tester);

      await tester.dragUntilVisible(
        find.textContaining('So viel sitzt auch in'),
        find.byType(ListView),
        const Offset(0, -300),
      );

      expect(
        find.text(
          'Geschätzt: So viel sitzt auch in '
          '$pruefungsreifeHorizontTage Tagen noch',
        ),
        findsOneWidget,
      );
    });
  });
}
