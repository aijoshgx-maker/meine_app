// Die freien Antworten gegen den echten Bestand.
//
// Die harte Fassung einer Frage nimmt ihr die Optionen. Was dann als richtig
// gilt, steht allein in `freieAntwort` - ist dort etwas schief, scheitert man
// an einer Frage, die man kann. Genau der Fehler, den die Freitextbewertung
// gerade erst losgeworden ist, deshalb hier ein Gurt ueber den Bestand.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/matching/antwort_matcher.dart';
import 'package:meine_app/core/quiz/frage_haerte.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Frage> alle;
  late List<Frage> bestueckt;

  setUpAll(() async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );
    alle = paket.fragen;
    bestueckt = alle.where((f) => f.freieAntwort.isNotEmpty).toList();
  });

  test('es gibt überhaupt Fragen mit freier Antwort', () {
    // Sonst prüfte alles Folgende still eine leere Liste.
    expect(bestueckt, isNotEmpty);
  });

  test('das Feld steht nur an single-Fragen', () {
    // An jedem anderen Typ wäre es wirkungslos und täuschte Pflege vor.
    for (final f in bestueckt) {
      expect(f.typ, 'single', reason: f.id);
      expect(f.richtigeIndizes, hasLength(1), reason: f.id);
    }
  });

  test('kein Eintrag ist leer oder doppelt', () {
    for (final f in bestueckt) {
      for (final a in f.freieAntwort) {
        expect(a.trim(), isNotEmpty, reason: f.id);
      }
      expect(
        f.freieAntwort.toSet(),
        hasLength(f.freieAntwort.length),
        reason: '${f.id} nennt eine Antwort doppelt',
      );
    }
  });

  test('jede hinterlegte Antwort wird auch als richtig erkannt', () {
    // Klingt trivial, ist es nicht: Die Bewertung normalisiert, und eine
    // Schreibweise, die dabei auseinanderfällt, wäre eine Falle.
    for (final f in bestueckt) {
      final hart = haerteFrage(f, Haertegrad.freierAbruf);
      for (final eingabe in f.freieAntwort) {
        expect(
          AntwortMatcher.passtGegenListe(eingabe, hart.akzeptierteKurzantworten),
          isTrue,
          reason: '${f.id}: "$eingabe" gilt nicht als richtig',
        );
      }
    }
  });

  test('der Text einer falschen Option gilt nicht als richtig', () {
    // Sonst wäre die harte Fassung leichter als die leichte.
    for (final f in bestueckt) {
      final hart = haerteFrage(f, Haertegrad.freierAbruf);
      final richtig = f.richtigeIndizes.first;
      for (var i = 0; i < f.optionen.length; i++) {
        if (i == richtig) continue;
        expect(
          AntwortMatcher.passtGegenListe(
            f.optionen[i],
            hart.akzeptierteKurzantworten,
          ),
          isFalse,
          reason: '${f.id}: Ablenker "${f.optionen[i]}" gilt als richtig',
        );
      }
    }
  });

  test('die richtige Option selbst gilt als richtig', () {
    // Wer sich an den Wortlaut der Option erinnert, darf ihn eintippen.
    for (final f in bestueckt) {
      final hart = haerteFrage(f, Haertegrad.freierAbruf);
      final richtig = f.optionen[f.richtigeIndizes.first];
      expect(
        AntwortMatcher.passtGegenListe(richtig, hart.akzeptierteKurzantworten),
        isTrue,
        reason: '${f.id}: "$richtig" gilt nicht als richtig',
      );
    }
  });
}
