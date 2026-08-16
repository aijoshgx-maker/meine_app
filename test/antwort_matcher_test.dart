import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/matching/antwort_matcher.dart';

void main() {
  group('AntwortMatcher.passtGenau', () {
    test('Groß-/Kleinschreibung wird ignoriert', () {
      expect(AntwortMatcher.passtGenau('Höchstmaß', 'HÖCHSTMASS'), isTrue);
    });

    test('Umlaut-Schreibweisen sind beidseitig gleichwertig', () {
      // "Höchstmaß" / "hoechstmass" / "HÖCHSTMASS" / "Höchstmass" müssen
      // alle greifen (P12b-Vorgabe).
      const varianten = [
        'Höchstmaß',
        'hoechstmass',
        'HÖCHSTMASS',
        'Höchstmass',
      ];
      for (final a in varianten) {
        for (final b in varianten) {
          expect(
            AntwortMatcher.passtGenau(a, b),
            isTrue,
            reason: '"$a" sollte zu "$b" passen',
          );
        }
      }
    });

    test('Bindestrich, Schrägstrich und Leerzeichen sind äquivalent', () {
      expect(
        AntwortMatcher.passtGenau('Lockout Tagout', 'Lockout-Tagout'),
        isTrue,
      );
      expect(
        AntwortMatcher.passtGenau('Lockout/Tagout', 'Lockout-Tagout'),
        isTrue,
      );
    });

    test('LOTO wird NICHT automatisch als Abkürzung erkannt', () {
      // Reine Normalisierung deckt keine Abkürzungen ab - das bleibt eine
      // fachliche Varianten-Entscheidung in den JSON-Daten, kein
      // Matcher-Bug.
      expect(AntwortMatcher.passtGenau('LOTO', 'Lockout-Tagout'), isFalse);
    });

    test('Dezimaltrennzeichen , und . sind gleichwertig', () {
      expect(AntwortMatcher.passtGenau('0.02', '0,02'), isTrue);
    });

    test('führende/folgende und mehrfache Leerzeichen werden ignoriert', () {
      expect(AntwortMatcher.passtGenau('  Spanwinkel  ', 'Spanwinkel'), isTrue);
      expect(AntwortMatcher.passtGenau('Fest    lager', 'Fest lager'), isTrue);
    });

    test('inhaltlich unterschiedliche Begriffe bleiben unterschiedlich', () {
      expect(AntwortMatcher.passtGenau('Festlager', 'Loslager'), isFalse);
    });
  });

  group('AntwortMatcher.passtGegenListe', () {
    test('greift, wenn irgendeine Variante passt', () {
      expect(
        AntwortMatcher.passtGegenListe('hoechstmass', [
          'Höchstmaß',
          'Mindestmaß',
        ]),
        isTrue,
      );
    });

    test('schlägt fehl, wenn keine Variante passt', () {
      expect(
        AntwortMatcher.passtGegenListe('Mittelmaß', [
          'Höchstmaß',
          'Mindestmaß',
        ]),
        isFalse,
      );
    });
  });

  group('AntwortMatcher.keywordGefunden (Fachgespräch)', () {
    test(
      'Mehrwort-Schlüsselwort: alle Tokens müssen vorkommen, Reihenfolge egal',
      () {
        expect(
          AntwortMatcher.keywordGefunden(
            'Man muss die Stöße dämpfen, sonst bricht das Bauteil.',
            'Stöße dämpfen',
          ),
          isTrue,
        );
        expect(
          AntwortMatcher.keywordGefunden(
            'Um die Stöße zu dämpfen, verwenden wir einen Elastomerpuffer.',
            'Stöße dämpfen',
          ),
          isTrue,
          reason: 'andere Wortstellung soll trotzdem greifen',
        );
      },
    );

    test(
      'reiner Teilstring-Zufallstreffer in einem anderen Wort zählt nicht',
      () {
        // "Rad" sollte nicht in "Fahrradkette" als eigenständiges Token
        // erkannt werden.
        expect(
          AntwortMatcher.keywordGefunden('Die Fahrradkette', 'Rad'),
          isFalse,
        );
      },
    );

    test('fehlendes Token lässt das Keyword als nicht gefunden gelten', () {
      expect(
        AntwortMatcher.keywordGefunden(
          'Man muss Stöße vermeiden.',
          'Stöße dämpfen',
        ),
        isFalse,
      );
    });

    test('Umlaut-Variante wird über denselben Normalisierer erkannt', () {
      expect(
        AntwortMatcher.keywordGefunden(
          'Wir muessen die Stoesse daempfen.',
          'Stöße dämpfen',
        ),
        isTrue,
      );
    });
  });

  group('AntwortMatcher.levenshtein', () {
    test('identische Strings haben Distanz 0', () {
      expect(AntwortMatcher.levenshtein('abc', 'abc'), 0);
    });

    test('ein Zeichen Unterschied ergibt Distanz 1', () {
      expect(AntwortMatcher.levenshtein('festlager', 'festlaher'), 1);
    });

    test(
      'Zahlen mit einer abweichenden Ziffer haben ebenfalls nur Distanz 1 - '
      'Grund, warum Tippfehlertoleranz NICHT pauschal aktiviert wird (siehe REVIEW_OFFEN.md)',
      () {
        expect(AntwortMatcher.levenshtein('14 tage', '24 tage'), 1);
      },
    );
  });
}
