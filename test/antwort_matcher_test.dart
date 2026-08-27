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

    // Das Malzeichen · steht auf keiner Handytastatur. Wer die Formel kennt,
    // soll nicht an der Wahl des Zeichens scheitern.
    test('Malzeichen und Leerzeichen sind äquivalent', () {
      expect(AntwortMatcher.passtGenau('v * A', 'v · A'), isTrue);
      expect(AntwortMatcher.passtGenau('v A', 'v · A'), isTrue);
      expect(AntwortMatcher.passtGenau('v × A', 'v · A'), isTrue);
      expect(AntwortMatcher.passtGenau('Pa*s', 'Pa·s'), isTrue);
    });

    test('das Malzeichen macht nicht beliebige Antworten gleich', () {
      expect(AntwortMatcher.passtGenau('v * B', 'v · A'), isFalse);
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

  // Jeder Fall hier stammt aus einem Screenshot: richtig gewusst, richtig
  // getippt - und die App sagte trotzdem "Falsch".
  group('gemeldete Fehlbewertungen', () {
    test('römische und arabische Ziffer meinen dasselbe', () {
      expect(
        AntwortMatcher.passtGenau('Arbeitslosengeld 2', 'Arbeitslosengeld II'),
        isTrue,
      );
      expect(AntwortMatcher.passtGenau('ALG 2', 'ALG II'), isTrue);
    });

    test('Komma statt "und", und Plural statt Singular', () {
      expect(
        AntwortMatcher.passtGenau(
          'Gewerkschaften, Arbeitgeber',
          'Gewerkschaft und Arbeitgeber',
        ),
        isTrue,
      );
    });

    test('die Reihenfolge einer Aufzählung ist gleichgültig', () {
      expect(
        AntwortMatcher.passtGenau(
          'Berufsschule und Betrieb',
          'Betrieb und Berufsschule',
        ),
        isTrue,
      );
    });

    test('ausgeschriebene Zahlen zählen wie Ziffern', () {
      expect(AntwortMatcher.passtGenau('vierzehn Tage', '14 Tage'), isTrue);
      expect(AntwortMatcher.passtGenau('sechs Stunden', '6 Stunden'), isTrue);
    });
  });

  // Die Gegenprobe. Ohne sie wäre die Lockerung oben nicht zu verantworten:
  // Eine Lern-App, die Falsches durchgehen lässt, bestätigt einen Irrtum.
  group('Grenzen der Nachsicht', () {
    test('fachlich entgegengesetzte Begriffe bleiben getrennt', () {
      expect(AntwortMatcher.passtGenau('Festlager', 'Loslager'), isFalse);
    });

    test('Härte und Härten bleiben zwei verschiedene Antworten', () {
      // Eigenschaft gegen Verfahren - das darf die Pluralregel nicht
      // einebnen. Sie greift deshalb erst ab neun Zeichen.
      expect(AntwortMatcher.passtGenau('Härte', 'Härten'), isFalse);
      expect(AntwortMatcher.passtGenau('Schleife', 'Schleifen'), isFalse);
    });

    test('eine abweichende Zahl bleibt falsch', () {
      expect(AntwortMatcher.passtGenau('24 Tage', '14 Tage'), isFalse);
      expect(AntwortMatcher.passtGenau('zwölf Monate', '12 Wochen'), isFalse);
    });

    test('das V in einer Spannungsangabe wird nicht zur Zahl', () {
      // Nur I bis IV gelten als römische Ziffern - V, X, C und M sind im
      // Fachbestand Einheiten und Kurzzeichen.
      expect(AntwortMatcher.normalisieren('230 V'), '230 v');
      expect(AntwortMatcher.normalisieren('M8'), 'm8');
    });

    test('ein Dezimalkomma trennt keine Aufzählung', () {
      expect(AntwortMatcher.teileAntwort('38,0'), {'38,0'});
      expect(AntwortMatcher.passtGenau('38,0', '38.0'), isTrue);
    });

    test('ein Plus ohne Leerzeichen bleibt Teil der Antwort', () {
      // "+A" ist der Kurzbezeichner für weichgeglüht (ft-ww-011).
      expect(AntwortMatcher.teileAntwort('Weichglühen (+A)'), hasLength(1));
    });

    test('eine Teilantwort allein genügt nicht', () {
      expect(
        AntwortMatcher.passtGenau(
          'Gewerkschaften',
          'Gewerkschaften und Arbeitgeberverbände',
        ),
        isFalse,
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
