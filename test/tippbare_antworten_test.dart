// Die angezeigten Antworten gegen den echten Bestand.
//
// Die Loesungsansicht zeigt immer den ERSTEN Eintrag einer Antwortliste.
// Stand dort ein Formelzeichen wie ε, η oder π, las man nach dem Aufdecken
// eine Antwort, die sich auf einer deutschen Handytastatur gar nicht
// eintippen laesst - gemeldet an au-tb-003 (Hookesches Gesetz).
//
// Der Test haelt fest, dass die angezeigte Fassung immer die tippbare ist.
// Das Zeichen selbst darf als weitere Schreibweise dahinter stehen.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/matching/antwort_matcher.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';

/// Zeichen, die auf einer deutschen Tastatur ohne Umwege erreichbar sind:
/// druckbares ASCII plus Umlaute und Eszett.
final _tippbar = RegExp(r'^[\x20-\x7EÄÖÜäöüß]*$');

/// Bewusst belassen: Das Gradzeichen liegt auf der Handytastatur.
const _ausnahmen = {'ft-mp-001'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Frage> alle;

  setUpAll(() async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );
    alle = paket.fragen;
  });

  test('der Bestand hat überhaupt Freitextfragen', () {
    // Sonst prüfte alles Folgende still eine leere Liste.
    expect(
      alle.where((f) => f.luecken.isNotEmpty || f.typ == 'kurzantwort'),
      isNotEmpty,
    );
  });

  test('jede angezeigte Lückenantwort lässt sich tippen', () {
    for (final frage in alle) {
      if (_ausnahmen.contains(frage.id)) continue;
      for (var i = 0; i < frage.luecken.length; i++) {
        final gap = frage.luecken[i];
        if (gap.isEmpty) continue;
        expect(
          _tippbar.hasMatch(gap.first),
          isTrue,
          reason:
              '${frage.id} Lücke ${i + 1}: "${gap.first}" steht auf keiner '
              'deutschen Tastatur. Die ausgeschriebene Fassung gehört nach '
              'vorn, das Zeichen dahinter.',
        );
      }
    }
  });

  test('jede angezeigte Kurzantwort lässt sich tippen', () {
    for (final frage in alle) {
      if (_ausnahmen.contains(frage.id)) continue;
      if (frage.typ != 'kurzantwort') continue;
      final akzeptiert = frage.akzeptierteKurzantworten;
      if (akzeptiert.isEmpty) continue;
      expect(
        _tippbar.hasMatch(akzeptiert.first),
        isTrue,
        reason:
            '${frage.id}: "${akzeptiert.first}" steht auf keiner deutschen '
            'Tastatur.',
      );
    }
  });

  // Die angezeigte Fassung muss auch die sein, die durchgeht - sonst zeigt
  // die App eine Antwort, die sie selbst nicht annimmt.
  test('die angezeigte Fassung wird auch als richtig erkannt', () {
    for (final frage in alle) {
      for (var i = 0; i < frage.luecken.length; i++) {
        final gap = frage.luecken[i];
        if (gap.isEmpty) continue;
        expect(
          AntwortMatcher.passtGegenListe(gap.first, gap),
          isTrue,
          reason: '${frage.id} Lücke ${i + 1}',
        );
      }
      if (frage.typ == 'kurzantwort' &&
          frage.akzeptierteKurzantworten.isNotEmpty) {
        expect(
          AntwortMatcher.passtGegenListe(
            frage.akzeptierteKurzantworten.first,
            frage.akzeptierteKurzantworten,
          ),
          isTrue,
          reason: frage.id,
        );
      }
    }
  });
}
