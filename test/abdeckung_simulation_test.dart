// Kommt wirklich jede Frage im eingestellten Zeitraum dran?
//
// Der Anlass: In der App kamen viele Fragen gar nicht vor, während sich
// einige zu schnell wiederholten. Ursache war die Reihenfolge in der
// Auswahl - die fälligen Wiederholungen nahmen sich zuerst das ganze
// Tagesbudget. Sobald täglich zwanzig Karten fällig waren, wurde nie wieder
// eine neue Frage eingeführt, und der größte Teil des Kurses blieb liegen.
//
// Einzelne Behauptungen über das Kontingent stehen in
// quiz_fragen_auswahl_test.dart. Hier läuft stattdessen die Uhr: Der Test
// spielt Tag für Tag durch, mit echtem FSRS-Scheduler, und prüft am Ende,
// was tatsächlich drangekommen ist. Nur das beantwortet die Frage, die
// gestellt war.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_fragen_auswahl.dart';
import 'package:meine_app/models/frage.dart';

Frage _frage(int i) => Frage(
  id: 'f$i',
  bereich: 'allgemein',
  kategorie: 'Test',
  typ: 'single',
  frage: 'Frage $i',
  optionen: const ['A', 'B'],
  richtigeIndizes: const [0],
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'Weil.',
  schwierigkeit: 1,
);

/// Ergebnis eines durchgespielten Zeitraums.
class _Verlauf {
  /// Tag, an dem eine Frage zum ersten Mal drankam (0-basiert).
  final Map<String, int> erstesMal;

  /// Wie oft jede Frage insgesamt drankam.
  final Map<String, int> haeufigkeit;

  /// Karten pro Tag, um Leerlauf zu erkennen.
  final List<int> proTag;

  const _Verlauf(this.erstesMal, this.haeufigkeit, this.proTag);
}

/// Spielt [tage] Tage durch.
///
/// [antwortGut] steuert, wie gut geantwortet wird - davon hängen die
/// FSRS-Intervalle und damit die Wiederholungslast ab. Der ungünstige Fall
/// ist die schlechte Antwort: Sie erzeugt kurze Intervalle und damit den
/// Stau, an dem die alte Auswahl scheiterte.
_Verlauf _spiele({
  required int anzahlFragen,
  required int tage,
  required int kartenProTag,
  required int fensterTage,
  required bool antwortGut,
}) {
  final auswahl = QuizFragenAuswahl();
  final scheduler = FsrsScheduler();
  final fragen = List.generate(anzahlFragen, _frage);
  final staende = <String, GespeicherteKarte>{};
  final erstesMal = <String, int>{};
  final haeufigkeit = <String, int>{};
  final proTag = <int>[];
  final zufall = Random(20260828);

  var jetzt = DateTime(2026, 1, 1, 9);

  for (var tag = 0; tag < tage; tag++) {
    final neueHeute = <String>{};
    final bearbeitet = <String>{};

    // Innerhalb eines Tages kann in mehreren Sitzungen gelernt werden; der
    // Test erledigt das Pensum in einem Zug und fragt danach noch einmal
    // nach, damit auch der Nachschlag-Pfad mitläuft.
    for (var runde = 0; runde < 2; runde++) {
      final pensum = auswahl.tagespensum(
        fragen,
        kartenstaende: staende,
        zufall: zufall,
        kartenProTag: kartenProTag,
        heuteBearbeitet: bearbeitet,
        neueHeuteSchon: neueHeute.length,
        einfuehrungsFensterTage: fensterTage,
        jetzt: jetzt,
      );
      if (pensum.gesamt == 0) break;

      for (final frage in pensum.fragen) {
        erstesMal.putIfAbsent(frage.id, () => tag);
        haeufigkeit[frage.id] = (haeufigkeit[frage.id] ?? 0) + 1;
        if (staende[frage.id] == null) neueHeute.add(frage.id);
        bearbeitet.add(frage.id);

        final karte = staende[frage.id]?.card ?? FsrsCard.newCard(now: jetzt);
        staende[frage.id] = GespeicherteKarte(
          card: scheduler.review(
            karte,
            antwortGut ? Rating.good : Rating.hard,
            jetzt,
          ),
        );
      }
    }

    proTag.add(bearbeitet.length);
    jetzt = jetzt.add(const Duration(days: 1));
  }

  return _Verlauf(erstesMal, haeufigkeit, proTag);
}

void main() {
  const anzahlFragen = 681;
  const kartenProTag = 20;
  const fenster = 90;

  group('Einführungsfenster von $fenster Tagen, $kartenProTag Karten am Tag', () {
    // Die eigentliche Zusage: Innerhalb des Fensters ist jede Frage einmal
    // drangekommen. Gerechnet wird mit schlechten Antworten - dem
    // ungünstigen Fall, weil kurze Intervalle die Wiederholungslast
    // hochtreiben.
    test('jede Frage kommt im Fenster mindestens einmal dran', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: fenster,
        kartenProTag: kartenProTag,
        fensterTage: fenster,
        antwortGut: false,
      );

      final nieDran = [
        for (var i = 0; i < anzahlFragen; i++)
          if (!verlauf.erstesMal.containsKey('f$i')) 'f$i',
      ];

      expect(
        nieDran,
        isEmpty,
        reason:
            '${nieDran.length} von $anzahlFragen Fragen kamen in $fenster '
            'Tagen nie dran',
      );
    });

    test('auch bei guten Antworten bleibt keine liegen', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: fenster,
        kartenProTag: kartenProTag,
        fensterTage: fenster,
        antwortGut: true,
      );

      expect(verlauf.erstesMal, hasLength(anzahlFragen));
    });

    // Die zweite Hälfte der Meldung: "einige wiederholen sich zu schnell".
    // Ganz vermeiden lässt sich das nicht - eine schlecht gewusste Karte SOLL
    // früher wiederkommen. Aber keine darf das Pensum an sich reißen.
    test('keine Frage frisst einen unverhältnismäßigen Anteil', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: fenster,
        kartenProTag: kartenProTag,
        fensterTage: fenster,
        antwortGut: false,
      );

      final gesamtKarten = verlauf.proTag.reduce((a, b) => a + b);
      final oefteste = verlauf.haeufigkeit.values.reduce(max);

      expect(
        oefteste / gesamtKarten,
        lessThan(0.01),
        reason:
            'Eine einzelne Frage nimmt $oefteste von $gesamtKarten Plätzen '
            'ein',
      );
    });

    test('das Tagesbudget wird ausgeschöpft, nicht überschritten', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: 30,
        kartenProTag: kartenProTag,
        fensterTage: fenster,
        antwortGut: false,
      );

      for (var tag = 0; tag < verlauf.proTag.length; tag++) {
        expect(
          verlauf.proTag[tag],
          kartenProTag,
          reason: 'Tag $tag hatte ${verlauf.proTag[tag]} Karten',
        );
      }
    });
  });

  // Gegenprobe: Ohne das Kontingent - also mit einem Fenster, das so weit
  // gefasst ist, dass praktisch keine neuen Karten eingeplant werden - bleibt
  // der Kurs liegen. Das ist der Zustand, der gemeldet wurde.
  test('ein zu weites Fenster lässt den Kurs erwartungsgemäß liegen', () {
    final verlauf = _spiele(
      anzahlFragen: anzahlFragen,
      tage: fenster,
      kartenProTag: kartenProTag,
      fensterTage: 100000,
      antwortGut: false,
    );

    expect(verlauf.erstesMal.length, lessThan(anzahlFragen));
  });
}
