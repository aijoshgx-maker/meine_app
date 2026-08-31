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
        heuteBearbeitet: const {},
        jetzt: jetzt,
      );

      // Zusammen genau das Tagesbudget - aber nicht mehr ausschliesslich
      // Wiederholungen: Ein Teil ist den ungesehenen Karten vorbehalten,
      // sonst kaeme der Rest des Kurses nie dran.
      expect(pensum.gesamt, 20);
      expect(pensum.wiederholungen, isNotEmpty);
      expect(pensum.neue, isNotEmpty);
      expect(pensum.wiederholungen.length + pensum.neue.length, 20);
    });

    test('neue Karten füllen auf, was die Wiederholungen frei lassen', () {
      final faellige = viele('w', 7);
      final neue = viele('n', 30);
      final pensum = auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: alleFaellig(faellige),
        zufall: Random(1),
        kartenProTag: 20,
        heuteBearbeitet: const {},
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
        heuteBearbeitet: const {},
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
        heuteBearbeitet: const {'x0', 'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8', 'x9', 'x10', 'x11', 'x12', 'x13', 'x14'},
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
        heuteBearbeitet: const {'x0', 'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8', 'x9', 'x10', 'x11', 'x12', 'x13', 'x14', 'x15', 'x16', 'x17', 'x18', 'x19'},
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
        heuteBearbeitet: const {'x0', 'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8', 'x9', 'x10', 'x11', 'x12', 'x13', 'x14', 'x15', 'x16', 'x17', 'x18', 'x19', 'x20', 'x21', 'x22', 'x23', 'x24', 'x25', 'x26', 'x27', 'x28', 'x29'},
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
        heuteBearbeitet: const {},
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
        heuteBearbeitet: const {},
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
        heuteBearbeitet: const {},
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
        heuteBearbeitet: const {},
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
        heuteBearbeitet: const {},
        jetzt: jetzt,
      );

      expect(pensum.fragen.first.id, 'a1');
      expect(pensum.fragen.length, 3);
    });
  });

  // Eine mehrstufige Rechenaufgabe kostet ein Vielfaches der Zeit einer
  // Karteikarte. Zwischen neunzehn Karten wuerde sie uebersprungen - deshalb
  // ein eigener Platz, genau einer je Tag.
  // Der gemeldete Fehler: "Viele Fragen kommen gar nicht vor, während einige
  // sich zu schnell wiederholen." Ursache war die Reihenfolge - die
  // Wiederholungen nahmen sich zuerst das ganze Tagesbudget, und sobald
  // täglich genug fällig war, kam nie wieder eine neue Frage dazu.
  group('Kontingent für ungesehene Karten', () {
    final jetzt = DateTime(2026, 8, 28, 10);

    GespeicherteKarte faellig() => GespeicherteKarte(
      card: FsrsCard.newCard(
        now: jetzt,
      ).copyWith(due: jetzt.subtract(const Duration(days: 1))),
    );

    List<Frage> viele(String praefix, int anzahl) =>
        List.generate(anzahl, (i) => frage('$praefix$i', 'wiso'));

    test('neue Karten kommen dran, auch wenn genug fällig wäre', () {
      final faellige = viele('w', 200);
      final neue = viele('n', 481);
      final pensum = auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: {for (final f in faellige) f.id: faellig()},
        zufall: Random(1),
        kartenProTag: 20,
        einfuehrungsFensterTage: 90,
        jetzt: jetzt,
      );

      // 681 Fragen in 90 Tagen sind aufgerundet 8 am Tag.
      expect(pensum.neue, hasLength(8));
      expect(pensum.wiederholungen, hasLength(12));
      expect(pensum.gesamt, 20);
    });

    test('das Kontingent folgt dem eingestellten Fenster', () {
      final faellige = viele('w', 200);
      final neue = viele('n', 481);
      Tagespensum mitFenster(int tage) => auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: {for (final f in faellige) f.id: faellig()},
        zufall: Random(1),
        kartenProTag: 20,
        einfuehrungsFensterTage: tage,
        jetzt: jetzt,
      );

      expect(mitFenster(180).neue, hasLength(4));
      expect(mitFenster(90).neue, hasLength(8));
      // Ein knappes Fenster verlangt mehr, als der Deckel zulässt.
      expect(mitFenster(30).neue, hasLength(13));
    });

    // Ein Drittel des Tages bleibt den Wiederholungen. Was man neu anfängt
    // und nie wiederholt, ist nach zwei Wochen wieder weg.
    test('der Anteil neuer Karten ist gedeckelt', () {
      final faellige = viele('w', 200);
      final neue = viele('n', 481);
      final pensum = auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: {for (final f in faellige) f.id: faellig()},
        zufall: Random(1),
        kartenProTag: 20,
        einfuehrungsFensterTage: 1,
        jetzt: jetzt,
      );

      expect(pensum.neue, hasLength(13));
      expect(pensum.wiederholungen, hasLength(7));
    });

    test('heute schon eingeführte Karten gehen vom Kontingent ab', () {
      final faellige = viele('w', 200);
      final neue = viele('n', 481);
      final pensum = auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: {for (final f in faellige) f.id: faellig()},
        zufall: Random(1),
        kartenProTag: 20,
        neueHeuteSchon: 6,
        einfuehrungsFensterTage: 90,
        jetzt: jetzt,
      );

      expect(pensum.neue, hasLength(2));
    });

    test('sind wenige fällig, rücken weitere neue nach', () {
      final faellige = viele('w', 3);
      final neue = viele('n', 100);
      final pensum = auswahl.tagespensum(
        [...faellige, ...neue],
        kartenstaende: {for (final f in faellige) f.id: faellig()},
        zufall: Random(1),
        kartenProTag: 20,
        einfuehrungsFensterTage: 90,
        jetzt: jetzt,
      );

      expect(pensum.wiederholungen, hasLength(3));
      expect(pensum.neue, hasLength(17));
      expect(pensum.gesamt, 20);
    });

    test('ohne ungesehene Karten geht alles an die Wiederholungen', () {
      final faellige = viele('w', 200);
      final pensum = auswahl.tagespensum(
        faellige,
        kartenstaende: {for (final f in faellige) f.id: faellig()},
        zufall: Random(1),
        kartenProTag: 20,
        einfuehrungsFensterTage: 90,
        jetzt: jetzt,
      );

      expect(pensum.neue, isEmpty);
      expect(pensum.wiederholungen, hasLength(20));
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
      int kartenProTag = 20,
    }) => auswahl.tagespensum(
      fragen,
      kartenstaende: kartenstaende,
      zufall: Random(1),
      kartenProTag: kartenProTag,
      heuteBearbeitet: heuteBearbeitet,
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
      final p = pensum(
        [...normale(30), ...komplexe(5)],
        heuteBearbeitet: const {'k2'},
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
