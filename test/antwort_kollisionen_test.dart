// Der Sicherheitsgurt für die nachsichtige Antwortbewertung.
//
// Der Matcher erkennt inzwischen Zahlwörter, römische Ziffern, umgestellte
// Aufzählungen und Pluralformen als gleichwertig. Jede dieser Regeln macht
// die Bewertung großzügiger - und in einer Lern-App ist ein zu Unrecht
// anerkanntes "richtig" schlimmer als ein zu strenges "falsch", weil es
// einen Irrtum bestätigt.
//
// Deshalb wird hier nicht gegen eine Ausnahmeliste geprüft, sondern gegen
// eine Basislinie: den strengen Vergleich von früher. Die Lockerung darf
// keine Kollision erzeugen, die es vorher nicht schon gab. So wächst die
// Prüfung bei neuen Fragen von allein mit.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/matching/antwort_matcher.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/lernpaket.dart';

/// Der Normalisierer, wie er vor der Lockerung aussah.
String _streng(String text) {
  var t = text.trim().toLowerCase();
  t = t
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');
  t = t.replaceAll(RegExp(r'[-/]'), ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.replaceAllMapped(RegExp(r'(\d)[.,](\d)'), (m) => '${m[1]},${m[2]}');
}

/// Alle Antworten, die eine Frage gelten lässt - Kurzantwort wie Lückentext.
List<String> _antwortenVon(Frage frage) => [
  ...frage.akzeptierteKurzantworten,
  ...frage.luecken.expand((l) => l),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Frage> freitextFragen;

  setUpAll(() async {
    final Lernpaket paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );
    freitextFragen = paket.fragen
        .where(
          (f) =>
              f.typ == FrageTyp.kurzantwort.name ||
              f.typ == FrageTyp.lueckentext.name,
        )
        .where((f) => _antwortenVon(f).isNotEmpty)
        .toList();
  });

  test('der Bestand hat überhaupt Freitextfragen zu prüfen', () {
    // Sonst würde dieser Test still nichts prüfen und trotzdem grün sein.
    expect(freitextFragen.length, greaterThan(100));
  });

  test('jede hinterlegte Variante gilt weiterhin für ihre eigene Frage', () {
    final fehler = <String>[];

    for (final frage in freitextFragen) {
      for (final variante in frage.akzeptierteKurzantworten) {
        if (!AntwortMatcher.passtGegenListe(
          variante,
          frage.akzeptierteKurzantworten,
        )) {
          fehler.add('${frage.id}: "$variante" passt nicht mehr');
        }
      }
      for (final luecke in frage.luecken) {
        for (final variante in luecke) {
          if (!AntwortMatcher.passtGegenListe(variante, luecke)) {
            fehler.add('${frage.id}: Lücke "$variante" passt nicht mehr');
          }
        }
      }
    }

    expect(fehler, isEmpty, reason: fehler.join('\n'));
  });

  test('die Lockerung erzeugt keine neue Verwechslung', () {
    // Zwei Fragen derselben Kategorie dürfen nicht durch die Lockerung
    // dieselbe Antwort gelten lassen. Kategorien deshalb, weil dort die
    // Fragen zusammen abgefragt werden - über Kategoriegrenzen hinweg ist
    // ein gleiches Wort meist schlicht dasselbe Fachwort.
    final neueKollisionen = <String>[];

    for (var i = 0; i < freitextFragen.length; i++) {
      for (var j = i + 1; j < freitextFragen.length; j++) {
        final a = freitextFragen[i];
        final b = freitextFragen[j];
        if (a.kategorie != b.kategorie) continue;

        final antwortenA = _antwortenVon(a);
        final antwortenB = _antwortenVon(b);

        final vorherGleich = antwortenA
            .map(_streng)
            .toSet()
            .intersection(antwortenB.map(_streng).toSet());

        for (final antwort in antwortenA) {
          if (!AntwortMatcher.passtGegenListe(antwort, antwortenB)) continue;
          // Schon vorher deckungsgleich? Dann sind es zwei Fragen mit
          // derselben richtigen Antwort - kein Fehler dieser Änderung.
          if (vorherGleich.contains(_streng(antwort))) continue;
          neueKollisionen.add(
            '${a.id} / ${b.id} (${a.kategorie}): "$antwort" gilt jetzt für beide',
          );
        }
      }
    }

    expect(
      neueKollisionen,
      isEmpty,
      reason:
          'Die Antwortbewertung ist zu nachsichtig geworden:\n'
          '${neueKollisionen.join('\n')}',
    );
  });
}
