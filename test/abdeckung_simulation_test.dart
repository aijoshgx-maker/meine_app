// Läuft der Kurs wirklich durch, und kommt Zurückgelegtes wirklich wieder?
//
// Der Anlass: In der App kamen viele Fragen gar nicht vor, während sich
// einige zu schnell wiederholten. Ursache war ein Terminplan, der sich
// zuerst das ganze Tagesbudget nahm. Wiederholt wird jetzt nur noch, was man
// selbst mit "Nochmal" zurücklegt - und das kommt obendrauf.
//
// Einzelne Behauptungen über die Auswahl stehen in
// quiz_fragen_auswahl_test.dart. Hier läuft stattdessen die Uhr: Der Test
// spielt Tag für Tag durch und prüft am Ende, was tatsächlich drankam. Nur
// das beantwortet die Frage, die gestellt war.

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
        jetzt: jetzt,
      );
      if (pensum.gesamt == 0) break;

      for (final frage in pensum.fragen) {
        erstesMal.putIfAbsent(frage.id, () => tag);
        haeufigkeit[frage.id] = (haeufigkeit[frage.id] ?? 0) + 1;
        if (staende[frage.id] == null) neueHeute.add(frage.id);
        bearbeitet.add(frage.id);

        final karte = staende[frage.id]?.card ?? FsrsCard.newCard(now: jetzt);
        final rating = antwortGut ? Rating.good : Rating.again;
        staende[frage.id] = GespeicherteKarte(
          card: scheduler.review(karte, rating, jetzt),
          // Nur "Nochmal" legt eine Karte auf Wiedervorlage.
          nochmal: rating == Rating.again,
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

  // 681 Fragen zu 20 am Tag: nach 35 Tagen ist der Kurs einmal durch.
  const durchlaufTage = 35;

  group('$kartenProTag neue Fragen am Tag', () {
    test('nach $durchlaufTage Tagen ist jede Frage einmal drangewesen', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: durchlaufTage,
        kartenProTag: kartenProTag,
        antwortGut: true,
      );

      final nieDran = [
        for (var i = 0; i < anzahlFragen; i++)
          if (!verlauf.erstesMal.containsKey('f$i')) 'f$i',
      ];

      expect(
        nieDran,
        isEmpty,
        reason:
            '${nieDran.length} von $anzahlFragen Fragen kamen in '
            '$durchlaufTage Tagen nie dran',
      );
    });

    // Der Durchlauf darf nicht davon abhängen, wie gut geantwortet wird.
    // Zurückgelegte Karten kommen obendrauf und bremsen ihn deshalb nicht.
    test('auch mit lauter "Nochmal" bleibt keine Frage liegen', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: durchlaufTage,
        kartenProTag: kartenProTag,
        antwortGut: false,
      );

      expect(verlauf.erstesMal, hasLength(anzahlFragen));
    });

    test('täglich kommen genau $kartenProTag neue Fragen dazu', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: 10,
        kartenProTag: kartenProTag,
        antwortGut: true,
      );

      // Bei guten Antworten liegt nichts auf Wiedervorlage, das Pensum
      // besteht also nur aus den neuen Fragen.
      for (var tag = 0; tag < verlauf.proTag.length; tag++) {
        expect(
          verlauf.proTag[tag],
          kartenProTag,
          reason: 'Tag $tag hatte ${verlauf.proTag[tag]} Karten',
        );
      }
    });

    // Wer alles zurücklegt, bekommt alles wieder - und zwar zusätzlich.
    test('Zurückgelegtes kommt obendrauf', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: 5,
        kartenProTag: kartenProTag,
        antwortGut: false,
      );

      // Tag 1: 20 neue. Ab Tag 2 kommen die zurückgelegten dazu.
      expect(verlauf.proTag.first, kartenProTag);
      expect(verlauf.proTag[1], greaterThan(kartenProTag));
    });

    test('was einmal gut beantwortet wurde, kommt nicht von selbst wieder', () {
      final verlauf = _spiele(
        anzahlFragen: anzahlFragen,
        tage: durchlaufTage,
        kartenProTag: kartenProTag,
        antwortGut: true,
      );

      final oefteste = verlauf.haeufigkeit.values.reduce(max);
      expect(
        oefteste,
        1,
        reason: 'Eine Frage kam $oefteste-mal dran, obwohl sie saß',
      );
    });
  });
}
