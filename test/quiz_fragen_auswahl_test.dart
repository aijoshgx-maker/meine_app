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

    Map<String, GespeicherteKarte> alleFaellig(
      List<Frage> fragen, {
      int tageUeberfaellig = 1,
    }) => {
      for (final f in fragen)
        f.id: stand(faelligIn: Duration(days: -tageUeberfaellig)),
    };

    // Der Kern der Umstellung: ein Budget fuer beide Toepfe. Getrennt
    // gedeckelt standen an einem Tag achtzig Karten an.
    test('Wiederholungen und neue teilen sich EIN Tagesbudget', () {
      final faellige = viele('w', 30);
      final neue = viele('n', 30);
      final pensum = auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: alleFaellig(faellige),
        zufall: Random(1),
        kartenProTag: 20,
        heuteSchonBearbeitet: 0,
        jetzt: jetzt,
      );

      expect(pensum.gesamt, 20);
      expect(pensum.wiederholungen.length, 20);
      expect(pensum.neue, isEmpty);
    });

    test('neue Karten füllen auf, was die Wiederholungen frei lassen', () {
      final faellige = viele('w', 7);
      final neue = viele('n', 30);
      final pensum = auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: alleFaellig(faellige),
        zufall: Random(1),
        kartenProTag: 20,
        heuteSchonBearbeitet: 0,
        jetzt: jetzt,
      );

      expect(pensum.wiederholungen.length, 7);
      expect(pensum.neue.length, 13);
      expect(pensum.gesamt, 20);
    });

    test('reine Neu-Session, wenn nichts fällig ist', () {
      final pensum = auswahl.tagespensum(
        viele('n', 50),
        kartenstaende: const {},
        zufall: Random(1),
        kartenProTag: 20,
        heuteSchonBearbeitet: 0,
        jetzt: jetzt,
      );

      expect(pensum.neue.length, 20);
      expect(pensum.wiederholungen, isEmpty);
    });

    // Sonst tischte eine zweite Session am selben Tag noch einmal das volle
    // Pensum auf.
    test('heute schon Bearbeitetes geht vom Budget ab', () {
      final pensum = auswahl.tagespensum(
        viele('n', 50),
        kartenstaende: const {},
        zufall: Random(1),
        kartenProTag: 20,
        heuteSchonBearbeitet: 15,
        jetzt: jetzt,
      );

      expect(pensum.gesamt, 5);
    });

    test('ist das Pensum erledigt, bleibt nichts übrig', () {
      final faellige = viele('w', 30);
      final pensum = auswahl.tagespensum(
        [...faellige, ...viele('n', 30)],
        kartenstaende: alleFaellig(faellige),
        zufall: Random(1),
        kartenProTag: 20,
        heuteSchonBearbeitet: 20,
        jetzt: jetzt,
      );

      expect(pensum.gesamt, 0);
    });

    test('mehr bearbeitet als erlaubt ergibt kein negatives Budget', () {
      final pensum = auswahl.tagespensum(
        viele('n', 50),
        kartenstaende: const {},
        zufall: Random(1),
        kartenProTag: 5,
        heuteSchonBearbeitet: 30,
        jetzt: jetzt,
      );

      expect(pensum.gesamt, 0);
    });

    // Das eigentliche Versprechen: Wer eine Woche aussetzt, findet am achten
    // Tag genauso viele Karten vor wie am ersten.
    test('Versäumtes summiert sich nicht auf', () {
      final faellige = viele('w', 200);
      final pensum = auswahl.tagespensum(
        faellige,
        kartenstaende: alleFaellig(faellige, tageUeberfaellig: 14),
        zufall: Random(1),
        kartenProTag: 20,
        heuteSchonBearbeitet: 0,
        jetzt: jetzt,
      );

      expect(pensum.gesamt, 20);
    });

    test('die am längsten überfällige Karte kommt zuerst', () {
      final fragen = viele('w', 5);
      final pensum = auswahl.tagespensum(
        fragen,
        kartenstaende: {
          for (var i = 0; i < fragen.length; i++)
            fragen[i].id: stand(faelligIn: Duration(days: -(i + 1))),
        },
        zufall: Random(1),
        kartenProTag: 3,
        heuteSchonBearbeitet: 0,
        jetzt: jetzt,
      );

      // w4 ist fünf Tage überfällig, w3 vier, w2 drei.
      expect(pensum.wiederholungen.map((f) => f.id), ['w4', 'w3', 'w2']);
    });

    test('bei Tempo 0 steht nichts an', () {
      final faellige = viele('w', 30);
      final pensum = auswahl.tagespensum(
        [...faellige, ...viele('n', 30)],
        kartenstaende: alleFaellig(faellige),
        zufall: Random(1),
        kartenProTag: 0,
        heuteSchonBearbeitet: 0,
        jetzt: jetzt,
      );

      expect(pensum.gesamt, 0);
    });

    test('noch nicht fällige Karten tauchen nirgends auf', () {
      final pensum = auswahl.tagespensum(
        fragen,
        kartenstaende: {
          'a1': stand(faelligIn: const Duration(days: -1)),
          'ft1': stand(faelligIn: const Duration(days: 5)),
        },
        zufall: Random(1),
        kartenProTag: 20,
        heuteSchonBearbeitet: 0,
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
        kartenProTag: 20,
        heuteSchonBearbeitet: 0,
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
        kartenProTag: 12,
      );

      expect(ergebnis.length, 12);
    });

    test('ohne Tagesbudget bleibt die Session leer statt zu überschwemmen', () {
      final ergebnis = auswahl.waehleFragen(
        const QuizModus.heuteFaellig(),
        vieleFragen,
        kartenstaende: const {},
        zufall: Random(1),
        kartenProTag: 0,
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
