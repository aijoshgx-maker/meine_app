import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_fragen_auswahl.dart';
import 'package:meine_app/features/quiz/providers/quiz_modus.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  final auswahl = QuizFragenAuswahl();

  Frage frage(String id, String bereich, {String kategorie = 'Test'}) => Frage(
    id: id,
    bereich: bereich,
    kategorie: kategorie,
    typ: 'single',
    frage: 'Frage $id?',
    optionen: const ['a', 'b'],
    richtigeIndizes: const [0],
    reihenfolge: const [],
    paare: const [],
    luecken: const [],
    akzeptierteKurzantworten: const [],
    erklaerung: '...',
    schwierigkeit: 1,
  );

  final fragen = [
    frage('a1', 'auftragsanalyse', kategorie: 'Zerspanung'),
    frage('ft1', 'fertigungstechnik', kategorie: 'CNC'),
    frage('w1', 'wiso', kategorie: 'Tarifrecht'),
  ];

  test('freiUebung gibt alle Fragen unverändert zurück', () {
    final ergebnis = auswahl.waehleFragen(
      const QuizModus.freiUebung(),
      fragen,
      kartenstaende: {},
      zufall: Random(1),
    );
    expect(ergebnis, fragen);
  });

  group('Tagespensum', () {
    final jetzt = DateTime(2026, 8, 26, 10);

    GespeicherteKarte stand({required Duration faelligIn}) => GespeicherteKarte(
      card: FsrsCard.newCard(now: jetzt).copyWith(due: jetzt.add(faelligIn)),
    );

    List<Frage> viele(String praefix, int anzahl) =>
        List.generate(anzahl, (i) => frage('$praefix$i', 'wiso'));

    Map<String, GespeicherteKarte> alleFaellig(List<Frage> fragen) => {
      for (final f in fragen) f.id: stand(faelligIn: const Duration(days: -1)),
    };

    test('neue Karten sind auf das Tagesbudget gedeckelt', () {
      final pensum = auswahl.tagespensum(
        viele('n', 50),
        kartenstaende: const {},
        zufall: Random(1),
        neueProTag: 20,
        neueHeuteSchon: 0,
        jetzt: jetzt,
      );

      expect(pensum.neue.length, 20);
      expect(pensum.wiederholungen, isEmpty);
      // Ungesehene Karten sind nicht überfällig - sie warten nur.
      expect(pensum.zurueckgestellt, 0);
    });

    // Der Kern gegen die zweite Session am selben Tag: ohne Abzug bekäme man
    // abends noch einmal das volle Neu-Kontingent aufgetischt.
    test('heute schon angefangene Karten gehen vom Budget ab', () {
      final pensum = auswahl.tagespensum(
        viele('n', 50),
        kartenstaende: const {},
        zufall: Random(1),
        neueProTag: 20,
        neueHeuteSchon: 15,
        jetzt: jetzt,
      );

      expect(pensum.neue.length, 5);
    });

    test('ist das Budget aufgebraucht, kommen keine neuen mehr', () {
      final pensum = auswahl.tagespensum(
        viele('n', 50),
        kartenstaende: const {},
        zufall: Random(1),
        neueProTag: 20,
        neueHeuteSchon: 20,
        jetzt: jetzt,
      );

      expect(pensum.neue, isEmpty);
      expect(pensum.gesamt, 0);
    });

    // Wer den Regler nach einer Session herunterdreht, hat mehr angefangen
    // als erlaubt. Das darf kein negatives Budget ergeben.
    test('mehr angefangen als erlaubt ergibt kein negatives Budget', () {
      final pensum = auswahl.tagespensum(
        viele('n', 50),
        kartenstaende: const {},
        zufall: Random(1),
        neueProTag: 5,
        neueHeuteSchon: 30,
        jetzt: jetzt,
      );

      expect(pensum.neue, isEmpty);
    });

    test('bei Tempo 0 wird nur wiederholt', () {
      final neue = viele('n', 10);
      final faellige = viele('w', 5);
      final pensum = auswahl.tagespensum(
        [...neue, ...faellige],
        kartenstaende: alleFaellig(faellige),
        zufall: Random(1),
        neueProTag: 0,
        neueHeuteSchon: 0,
        jetzt: jetzt,
      );

      expect(pensum.neue, isEmpty);
      expect(pensum.wiederholungen.length, 5);
    });

    // Eine Woche ausgesetzt heißt nicht dreihundert Karten am Stück - der
    // Rest bleibt fällig und kommt morgen wieder.
    test('Wiederholungen sind gedeckelt, der Rest wird zurückgestellt', () {
      final alle = viele('w', 100);
      final pensum = auswahl.tagespensum(
        alle,
        kartenstaende: alleFaellig(alle),
        zufall: Random(1),
        neueProTag: 20,
        neueHeuteSchon: 0,
        jetzt: jetzt,
      );

      expect(
        pensum.wiederholungen.length,
        20 * QuizFragenAuswahl.wiederholungsFaktor,
      );
      expect(pensum.zurueckgestellt, 40);
    });

    test('auch bei Tempo 0 bleibt eine Untergrenze an Wiederholungen', () {
      final alle = viele('w', 100);
      final pensum = auswahl.tagespensum(
        alle,
        kartenstaende: alleFaellig(alle),
        zufall: Random(1),
        neueProTag: 0,
        neueHeuteSchon: 0,
        jetzt: jetzt,
      );

      expect(
        pensum.wiederholungen.length,
        QuizFragenAuswahl.mindestWiederholungen,
      );
    });

    test('noch nicht fällige Karten tauchen nirgends auf', () {
      final pensum = auswahl.tagespensum(
        fragen,
        kartenstaende: {
          'a1': stand(faelligIn: const Duration(days: -1)),
          'ft1': stand(faelligIn: const Duration(days: 5)),
        },
        zufall: Random(1),
        neueProTag: 20,
        neueHeuteSchon: 0,
        jetzt: jetzt,
      );

      expect(pensum.wiederholungen.map((f) => f.id), ['a1']);
      expect(pensum.neue.map((f) => f.id), ['w1']);
      expect(pensum.gesamt, 2);
    });

    test('Wiederholungen kommen vor neuen Karten', () {
      final pensum = auswahl.tagespensum(
        fragen,
        kartenstaende: {'a1': stand(faelligIn: const Duration(days: -1))},
        zufall: Random(1),
        neueProTag: 20,
        neueHeuteSchon: 0,
        jetzt: jetzt,
      );

      expect(pensum.fragen.first.id, 'a1');
      expect(pensum.fragen.length, 3);
    });
  });

  group('heuteFaellig', () {
    final vieleFragen = List.generate(50, (i) => frage('f$i', 'wiso'));

    test('reicht das Tagespensum durch', () {
      final ergebnis = auswahl.waehleFragen(
        const QuizModus.heuteFaellig(),
        vieleFragen,
        kartenstaende: const {},
        zufall: Random(1),
        neueProTag: 12,
      );

      // Alle ungesehen -> nur das Neu-Budget, keine Wiederholungen.
      expect(ergebnis.length, 12);
    });

    test('ohne Tagesbudget bleibt die Session leer statt zu überschwemmen', () {
      final ergebnis = auswahl.waehleFragen(
        const QuizModus.heuteFaellig(),
        vieleFragen,
        kartenstaende: const {},
        zufall: Random(1),
        neueProTag: 0,
      );

      expect(ergebnis, isEmpty);
    });
  });

  test('themenVertiefung filtert nur die gewählte Kategorie', () {
    final ergebnis = auswahl.waehleFragen(
      const QuizModus.themenVertiefung(kategorie: 'CNC'),
      fragen,
      kartenstaende: {},
      zufall: Random(1),
    );
    expect(ergebnis.map((f) => f.id).toList(), ['ft1']);
  });

  _fehlerquellenTests();
}

// Fehlerquellen-Modus: nur Karten, die beim letzten Mal "sicher, aber
// falsch" waren. Der Modus lebt davon, dass sich die Menge von selbst
// leert - deshalb wird hier auch geprüft, dass nicht markierte Karten
// draußen bleiben.
void _fehlerquellenTests() {
  final auswahl = QuizFragenAuswahl();
  const modus = QuizModus.fehlerquellen();

  Frage frage(String id) => Frage(
    id: id,
    bereich: 'allgemein',
    kategorie: 'Test',
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

  GespeicherteKarte karte({required bool markiert}) => GespeicherteKarte(
    card: FsrsCard.newCard(now: DateTime(2026)),
    hochkonfidentFalsch: markiert,
  );

  test('nimmt nur hochkonfident-falsche Karten', () {
    final ergebnis = auswahl.waehleFragen(
      modus,
      [frage('a'), frage('b'), frage('c')],
      kartenstaende: {
        'a': karte(markiert: true),
        'b': karte(markiert: false),
        // 'c' hat gar keinen Kartenstand - nie gelernt
      },
      zufall: Random(1),
    );

    expect(ergebnis.map((f) => f.id), ['a']);
  });

  test('ohne markierte Karten bleibt die Auswahl leer', () {
    final ergebnis = auswahl.waehleFragen(
      modus,
      [frage('a'), frage('b')],
      kartenstaende: {'a': karte(markiert: false)},
      zufall: Random(1),
    );

    expect(ergebnis, isEmpty);
  });
}
