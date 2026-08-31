import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_fragen_auswahl.dart';
import 'package:meine_app/features/quiz/providers/quiz_modus.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  final auswahl = QuizFragenAuswahl();

  Frage frage(
    String id,
    String bereich, {
    String kategorie = 'Test',
    bool komplex = false,
  }) => Frage(
    id: id,
    bereich: bereich,
    kategorie: kategorie,
    komplex: komplex,
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
    final jetzt = DateTime(2026, 8, 28, 10);

    /// Kartenstand einer Karte, die auf Wiedervorlage liegt.
    GespeicherteKarte zurueckgelegt() => GespeicherteKarte(
      card: FsrsCard.newCard(now: jetzt),
      nochmal: true,
    );

    /// Kartenstand einer erledigten Karte - sie kommt nicht wieder.
    GespeicherteKarte erledigt() =>
        GespeicherteKarte(card: FsrsCard.newCard(now: jetzt));

    List<Frage> viele(String praefix, int anzahl) =>
        List.generate(anzahl, (i) => frage('$praefix$i', 'wiso'));

    Tagespensum pensum(
      List<Frage> fragen, {
      Map<String, GespeicherteKarte> kartenstaende = const {},
      Set<String> heuteBearbeitet = const {},
      int neueHeuteSchon = 0,
      int kartenProTag = 20,
    }) => auswahl.tagespensum(
      fragen,
      kartenstaende: kartenstaende,
      zufall: Random(1),
      kartenProTag: kartenProTag,
      heuteBearbeitet: heuteBearbeitet,
      neueHeuteSchon: neueHeuteSchon,
      jetzt: jetzt,
    );

    test('das Kontingent gilt für die neuen Fragen', () {
      final p = pensum(viele('n', 100));

      expect(p.neue, hasLength(20));
      expect(p.wiederholungen, isEmpty);
    });

    // Der Kern der Umstellung: Was man selbst zurückgelegt hat, kommt
    // OBENDRAUF - dafür fällt keine neue Frage aus.
    test('Zurückgelegtes kommt zusätzlich zum Kontingent', () {
      final zurueck = viele('z', 5);
      final p = pensum(
        [...zurueck, ...viele('n', 100)],
        kartenstaende: {for (final f in zurueck) f.id: zurueckgelegt()},
      );

      expect(p.wiederholungen, hasLength(5));
      expect(p.neue, hasLength(20));
      expect(p.gesamt, 25);
    });

    // Ohne "Nochmal" gibt es keinen Grund, eine Karte wiederzusehen. Ein
    // Terminplan, der von sich aus zurückholt, existiert nicht mehr.
    test('erledigte Karten kommen nicht von selbst wieder', () {
      final alt = viele('a', 50);
      final p = pensum(
        [...alt, ...viele('n', 10)],
        kartenstaende: {for (final f in alt) f.id: erledigt()},
      );

      expect(p.wiederholungen, isEmpty);
      expect(p.neue, hasLength(10));
    });

    test('heute schon eingeführte Fragen gehen vom Kontingent ab', () {
      final p = pensum(viele('n', 100), neueHeuteSchon: 14);

      expect(p.neue, hasLength(6));
    });

    test('mehr eingeführt als erlaubt ergibt kein negatives Budget', () {
      final p = pensum(viele('n', 100), neueHeuteSchon: 30);

      expect(p.neue, isEmpty);
    });

    // Sonst stünde eine gerade beantwortete Wiedervorlage in derselben
    // Sitzung sofort wieder da.
    test('heute Bearbeitetes taucht nicht noch einmal auf', () {
      final zurueck = viele('z', 3);
      final p = pensum(
        zurueck,
        kartenstaende: {for (final f in zurueck) f.id: zurueckgelegt()},
        heuteBearbeitet: const {'z0', 'z1'},
      );

      expect(p.wiederholungen.map((f) => f.id), ['z2']);
    });

    test('bei Tempo 0 kommen keine neuen dazu, Zurückgelegtes schon', () {
      final zurueck = viele('z', 4);
      final p = pensum(
        [...zurueck, ...viele('n', 50)],
        kartenstaende: {for (final f in zurueck) f.id: zurueckgelegt()},
        kartenProTag: 0,
      );

      expect(p.neue, isEmpty);
      expect(p.wiederholungen, hasLength(4));
    });

    test('Zurückgelegtes steht in der Session vor dem Neuen', () {
      final zurueck = viele('z', 2);
      final p = pensum(
        [...zurueck, ...viele('n', 5)],
        kartenstaende: {for (final f in zurueck) f.id: zurueckgelegt()},
      );

      expect(p.fragen.take(2).every((f) => f.id.startsWith('z')), isTrue);
    });

    test('ohne Fragen bleibt das Pensum leer', () {
      expect(pensum(const []).gesamt, 0);
    });
  });

  group('Komplexaufgabe des Tages', () {
    final jetzt = DateTime(2026, 8, 27, 10);

    GespeicherteKarte stand({required Duration faelligIn}) => GespeicherteKarte(
      card: FsrsCard.newCard(now: jetzt).copyWith(due: jetzt.add(faelligIn)),
    );

    List<Frage> normale(int anzahl) =>
        List.generate(anzahl, (i) => frage('n$i', 'wiso'));

    List<Frage> komplexe(int anzahl) => List.generate(
      anzahl,
      (i) => frage('k$i', 'wiso', komplex: true),
    );

    Tagespensum pensum(
      List<Frage> fragen, {
      Map<String, GespeicherteKarte> kartenstaende = const {},
      Set<String> heuteBearbeitet = const {},
      int neueHeuteSchon = 0,
      int kartenProTag = 20,
    }) => auswahl.tagespensum(
      fragen,
      kartenstaende: kartenstaende,
      zufall: Random(1),
      kartenProTag: kartenProTag,
      heuteBearbeitet: heuteBearbeitet,
      neueHeuteSchon: neueHeuteSchon,
      jetzt: jetzt,
    );

    test('genau eine kommt ins Pensum, auch wenn viele bereitstehen', () {
      final p = pensum([...normale(30), ...komplexe(5)]);

      expect(p.komplex, hasLength(1));
      expect(p.gesamt, 20);
    });

    test('sie belegt einen Platz im Tagesbudget, nicht einen zusätzlichen', () {
      final p = pensum([...normale(30), ...komplexe(5)]);

      expect(p.wiederholungen.length + p.neue.length, 19);
      expect(p.gesamt, 20);
    });

    // Sonst käme sie im normalen Topf ein zweites Mal vor.
    test('Komplexaufgaben tauchen nicht als gewöhnliche Karten auf', () {
      final p = pensum([...normale(5), ...komplexe(5)]);

      expect(p.neue.where((f) => f.komplex), isEmpty);
      expect(p.wiederholungen.where((f) => f.komplex), isEmpty);
      expect(p.neue, hasLength(5));
    });

    test('ist heute schon eine bearbeitet, kommt keine zweite', () {
      // k2 war heute schon dran - sie hat damit auch einen Platz des
      // Kontingents verbraucht, wie jede erstmals gestellte Frage.
      final p = pensum(
        [...normale(30), ...komplexe(5)],
        heuteBearbeitet: const {'k2'},
        neueHeuteSchon: 1,
      );

      expect(p.komplex, isEmpty);
      // Der frei gewordene Platz fällt an die übrigen Karten zurück.
      expect(p.gesamt, 19);
    });

    test('eine fällige geht einer ungesehenen vor', () {
      final alle = komplexe(3);
      final p = pensum(
        alle,
        kartenstaende: {'k1': stand(faelligIn: const Duration(days: -2))},
      );

      expect(p.komplex.single.id, 'k1');
    });

    test('von mehreren fälligen kommt die am längsten überfällige', () {
      final alle = komplexe(3);
      final p = pensum(
        alle,
        kartenstaende: {
          'k0': stand(faelligIn: const Duration(days: -1)),
          'k1': stand(faelligIn: const Duration(days: -9)),
          'k2': stand(faelligIn: const Duration(days: -3)),
        },
      );

      expect(p.komplex.single.id, 'k1');
    });

    test('eine noch nicht fällige bleibt liegen', () {
      final alle = komplexe(1);
      final p = pensum(
        alle,
        kartenstaende: {'k0': stand(faelligIn: const Duration(days: 4))},
      );

      expect(p.komplex, isEmpty);
    });

    test('ohne Komplexaufgaben im Kurs ändert sich nichts', () {
      final p = pensum(normale(30));

      expect(p.komplex, isEmpty);
      expect(p.gesamt, 20);
    });

    test('sie steht in der Session vorn', () {
      final p = pensum([...normale(5), ...komplexe(2)]);

      expect(p.fragen.first.komplex, isTrue);
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
