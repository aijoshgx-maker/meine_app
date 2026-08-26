// Die steigende Schwierigkeit im Zusammenspiel: Kartenstand rein, gehaertete
// Session raus - und der Zaehler wandert nach der Bewertung zurueck in den
// Speicher.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/app/settings_providers.dart';
import 'package:meine_app/core/quiz/frage_haerte.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/kurs.dart';

import 'hilfen/test_kurs.dart';

const _frageId = 'ft-zg-015';

final _frage = Frage(
  id: _frageId,
  bereich: 'fertigungstechnik',
  kategorie: 'Zerspanung',
  typ: 'single',
  frage: 'Welches Verfahren erzeugt eine H7-Passung?',
  optionen: const ['Reiben', 'Honen', 'Senken'],
  richtigeIndizes: const [0],
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'Reiben erzeugt Bohrungen hoher Maß- und Formgenauigkeit.',
  schwierigkeit: 1,
  // Gehört zu einem Prüfungsbogen, damit der Testlauf sie überhaupt auswählt.
  pruefung: 'S18',
  pruefungReihenfolge: 1,
  freieAntwort: const ['Reiben', 'Aufreiben'],
);

/// Kartenspeicher mit genau einem vorbelegten Zählerstand.
Future<FakeFsrsCardStore> _karten(int zaehler) async {
  final store = FakeFsrsCardStore();
  await store.speichern(
    testKursId,
    _frageId,
    GespeicherteKarte(
      card: FsrsCard.newCard(now: DateTime.now()),
      sicherRichtigInFolge: zaehler,
    ),
  );
  return store;
}

ProviderContainer _container({
  required FakeFsrsCardStore karten,
  bool schalter = true,
  Kurs? kurs,
}) {
  final container = ProviderContainer(
    overrides: [
      fsrsCardStoreProvider.overrideWithValue(karten),
      settingsStoreProvider.overrideWithValue(
        FakeSettingsStore(steigendeSchwierigkeit: schalter),
      ),
      attemptHistoryStoreProvider.overrideWithValue(FakeAttemptHistoryStore()),
      aktivesPaketProvider.overrideWith(
        (_) async => testPaket([_frage], kurs: kurs),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<QuizSessionState> _session(
  ProviderContainer container,
  QuizModus modus,
) async {
  await container.read(quizSessionProvider(modus).future);
  return container.read(quizSessionProvider(modus)).value!;
}

void main() {
  // Die Bewertung loest ein haptisches Signal aus - ohne Binding laeuft das
  // gegen einen fehlenden Plattformkanal.
  TestWidgetsFlutterBinding.ensureInitialized();

  const uebung = QuizModus.freiUebung();

  test('frisch gelernte Fragen kommen unverändert', () async {
    final state = await _session(
      _container(karten: await _karten(1)),
      uebung,
    );

    expect(state.aktuelleFrage!.typ, 'single');
    expect(state.aktuelleFrage!.optionen, isNotEmpty);
    expect(state.aktuellerHaertegrad, Haertegrad.normal);
  });

  test('ab zwei sicheren Treffern fallen nur die Tipps weg', () async {
    final state = await _session(
      _container(karten: await _karten(2)),
      uebung,
    );

    // Die Frage selbst bleibt, was sie war - nur die Stütze verschwindet.
    expect(state.aktuellerHaertegrad, Haertegrad.ohneTipps);
    expect(state.aktuelleFrage!.typ, 'single');
    expect(state.aktuelleFrage!.optionen, isNotEmpty);
  });

  test('ab vier verschwinden die Optionen', () async {
    final state = await _session(
      _container(karten: await _karten(4)),
      uebung,
    );

    expect(state.aktuellerHaertegrad, Haertegrad.freierAbruf);
    expect(state.aktuelleFrage!.typ, 'kurzantwort');
    expect(state.aktuelleFrage!.optionen, isEmpty);
    expect(state.aktuelleFrage!.akzeptierteKurzantworten, contains('Reiben'));
    // Die ID bleibt: sonst wäre der Lernfortschritt eine fremde Karte.
    expect(state.aktuelleFrage!.id, _frageId);
  });

  test('ausgeschaltet bleibt alles beim Alten', () async {
    final state = await _session(
      _container(karten: await _karten(9), schalter: false),
      uebung,
    );

    expect(state.aktuellerHaertegrad, Haertegrad.normal);
    expect(state.aktuelleFrage!.typ, 'single');
    expect(state.aktuelleFrage!.optionen, isNotEmpty);
  });

  // Im Testlauf zählt der authentische Prüfungsbogen - dieselbe Regel wie
  // bei den variierenden Aufgaben.
  test('der Testlauf bleibt vom Härtegrad unberührt', () async {
    final state = await _session(
      _container(
        karten: await _karten(9),
        kurs: testKurs(
          pruefungen: const [
            PruefungsDefinition(code: 'S18', titel: 'Sommer 2018'),
          ],
          features: const KursFeatures(pruefungssimulation: true),
        ),
      ),
      const QuizModus.pruefungssimulation(
        pruefungsId: 'S18',
        zeitlimitMinuten: 90,
      ),
    );

    expect(state.aktuellerHaertegrad, Haertegrad.normal);
    expect(state.aktuelleFrage!.typ, 'single');
  });

  group('Zähler nach der Bewertung', () {
    Future<int> spielen({
      required int start,
      required bool richtig,
      required Konfidenz konfidenz,
    }) async {
      final karten = await _karten(start);
      final container = _container(karten: karten);
      await container.read(quizSessionProvider(uebung).future);
      final controller = container.read(quizSessionProvider(uebung).notifier);

      final frage = container
          .read(quizSessionProvider(uebung))
          .value!
          .aktuelleFrage!;
      // Auf Stufe 2 gibt es keine Optionen mehr - dort wird getippt.
      if (frage.typ == 'kurzantwort') {
        controller.freitextSetzen(richtig ? 'Reiben' : 'Senken');
      } else {
        controller.auswahlUmschalten(richtig ? 0 : 2);
      }
      controller.weiterZuKonfidenz();
      controller.konfidenzUndAufdecken(konfidenz);
      await controller.bewerten(Rating.good);

      return karten
              .kartenStandFuer(testKursId, _frageId)
              ?.sicherRichtigInFolge ??
          -1;
    }

    test('sicher und richtig zählt hoch', () async {
      expect(
        await spielen(start: 1, richtig: true, konfidenz: Konfidenz.sicher),
        2,
      );
    });

    test('unsicher lässt den Stand stehen', () async {
      expect(
        await spielen(start: 3, richtig: true, konfidenz: Konfidenz.unsicher),
        3,
      );
    });

    test('ein Fehler auf Stufe 2 stuft auf Stufe 1 zurück', () async {
      final nachher = await spielen(
        start: 5,
        richtig: false,
        konfidenz: Konfidenz.sicher,
      );

      expect(nachher, 2);
      expect(haertegradVon(nachher), Haertegrad.ohneTipps);
    });

    // Der Zähler ist Teil des Lernstands, nicht der Erprobung: Ohne das
    // stünde man nach dem Einschalten des Schalters wieder bei null.
    test('er läuft auch bei ausgeschaltetem Schalter weiter', () async {
      final karten = await _karten(1);
      final container = _container(karten: karten, schalter: false);
      await container.read(quizSessionProvider(uebung).future);
      final controller = container.read(quizSessionProvider(uebung).notifier);

      controller.auswahlUmschalten(0);
      controller.weiterZuKonfidenz();
      controller.konfidenzUndAufdecken(Konfidenz.sicher);
      await controller.bewerten(Rating.good);

      expect(
        karten.kartenStandFuer(testKursId, _frageId)?.sicherRichtigInFolge,
        2,
      );
    });
  });
}
