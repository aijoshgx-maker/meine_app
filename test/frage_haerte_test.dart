// Die Stufenlogik der steigenden Schwierigkeit - ohne Provider und ohne Hive.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/quiz/frage_haerte.dart';
import 'package:meine_app/models/frage.dart';

Frage _frage({
  String typ = 'single',
  List<String> optionen = const ['Reiben', 'Honen', 'Senken'],
  List<int> richtigeIndizes = const [0],
  List<String> freieAntwort = const [],
}) => Frage(
  id: 'test-1',
  bereich: 'fertigungstechnik',
  kategorie: 'Zerspanung',
  typ: typ,
  frage: 'Welches Verfahren erzeugt eine H7-Passung?',
  optionen: optionen,
  richtigeIndizes: richtigeIndizes,
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'Weil.',
  schwierigkeit: 1,
  freieAntwort: freieAntwort,
);

void main() {
  group('haertegradVon', () {
    test('die ersten beiden Male bleibt alles beim Alten', () {
      expect(haertegradVon(0), Haertegrad.normal);
      expect(haertegradVon(1), Haertegrad.normal);
    });

    test('ab zwei sicheren Treffern fallen die Tipps weg', () {
      expect(haertegradVon(2), Haertegrad.ohneTipps);
      expect(haertegradVon(3), Haertegrad.ohneTipps);
    });

    test('ab vier wird frei abgefragt', () {
      expect(haertegradVon(4), Haertegrad.freierAbruf);
      expect(haertegradVon(99), Haertegrad.freierAbruf);
    });
  });

  group('naechsterZaehler', () {
    test('sicher und richtig zählt hoch', () {
      expect(naechsterZaehler(0, korrekt: true, sicher: true), 1);
      expect(naechsterZaehler(3, korrekt: true, sicher: true), 4);
    });

    // Wer richtig rät, hat es nicht gekonnt - die leichte Fassung ist damit
    // nicht als zu leicht erwiesen.
    test('richtig, aber unsicher lässt den Stand stehen', () {
      expect(naechsterZaehler(3, korrekt: true, sicher: false), 3);
      expect(naechsterZaehler(0, korrekt: true, sicher: false), 0);
    });

    test('ein Fehler nimmt genau eine Stufe zurück', () {
      // Stufe 2 -> Untergrenze von Stufe 1
      expect(naechsterZaehler(4, korrekt: false, sicher: true), 2);
      expect(naechsterZaehler(9, korrekt: false, sicher: false), 2);
      // Stufe 1 -> Stufe 0
      expect(naechsterZaehler(3, korrekt: false, sicher: true), 0);
      expect(naechsterZaehler(2, korrekt: false, sicher: false), 0);
      // Stufe 0 bleibt Stufe 0
      expect(naechsterZaehler(1, korrekt: false, sicher: true), 0);
      expect(naechsterZaehler(0, korrekt: false, sicher: false), 0);
    });

    test('nach dem Fehler geht es von der neuen Stufe aus weiter', () {
      final nachFehler = naechsterZaehler(5, korrekt: false, sicher: true);
      expect(haertegradVon(nachFehler), Haertegrad.ohneTipps);
      final wiederRichtig = naechsterZaehler(
        nachFehler,
        korrekt: true,
        sicher: true,
      );
      // Zwei richtige Antworten führen zurück auf Stufe 2.
      expect(
        haertegradVon(
          naechsterZaehler(wiederRichtig, korrekt: true, sicher: true),
        ),
        Haertegrad.freierAbruf,
      );
    });
  });

  group('kannFreierAbruf', () {
    test('nur single-Fragen mit hinterlegter Antwort', () {
      expect(kannFreierAbruf(_frage(freieAntwort: const ['Reiben'])), isTrue);
      expect(kannFreierAbruf(_frage()), isFalse);
      expect(
        kannFreierAbruf(
          _frage(typ: 'multi', freieAntwort: const ['Reiben']),
        ),
        isFalse,
      );
    });
  });

  group('haerteFrage', () {
    final bestueckt = _frage(freieAntwort: const ['Reiben', 'Aufreiben']);

    test('unterhalb von Stufe 2 bleibt die Frage unangetastet', () {
      expect(haerteFrage(bestueckt, Haertegrad.normal), same(bestueckt));
      expect(haerteFrage(bestueckt, Haertegrad.ohneTipps), same(bestueckt));
    });

    test('auf Stufe 2 verschwinden die Optionen', () {
      final hart = haerteFrage(bestueckt, Haertegrad.freierAbruf);

      expect(hart.typ, 'kurzantwort');
      expect(hart.optionen, isEmpty);
      // Der Wortlaut der richtigen Option gilt immer mit.
      expect(hart.akzeptierteKurzantworten, ['Reiben', 'Aufreiben', 'Reiben']);
    });

    // Der Lernfortschritt haengt an der ID. Aendert sie sich, waere die harte
    // Fassung eine fremde Karte und der ganze Verlauf verloren.
    test('die ID und der Fragetext bleiben dieselben', () {
      final hart = haerteFrage(bestueckt, Haertegrad.freierAbruf);

      expect(hart.id, bestueckt.id);
      expect(hart.frage, bestueckt.frage);
      expect(hart.erklaerung, bestueckt.erklaerung);
      expect(hart.bereich, bestueckt.bereich);
      expect(hart.kategorie, bestueckt.kategorie);
    });

    test('ohne hinterlegte Antwort bleibt die Auswahlfrage bestehen', () {
      final ohne = _frage();
      expect(haerteFrage(ohne, Haertegrad.freierAbruf), same(ohne));
    });

    test('andere Fragetypen kommen unverändert zurück', () {
      for (final typ in [
        'multi',
        'wahrfalsch',
        'rechnung',
        'kurzantwort',
        'lueckentext',
        'zuordnung',
        'reihenfolge',
      ]) {
        final f = _frage(typ: typ, freieAntwort: const ['Reiben']);
        expect(
          haerteFrage(f, Haertegrad.freierAbruf),
          same(f),
          reason: 'Typ $typ',
        );
      }
    });
  });
}
