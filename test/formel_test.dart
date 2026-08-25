// Der Formelauswerter ist die Grundlage der variierenden Aufgaben: Aus ihm
// kommt der Lösungswert, den die App als richtig gelten lässt. Ein Fehler
// hier fällt niemandem auf - er sieht nur aus wie eine Aufgabe, die man
// falsch gerechnet hat.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/formel/formel.dart';

void main() {
  group('Grundrechenarten', () {
    test('Punkt vor Strich', () {
      expect(werteAus('2 + 3 * 4', const {}), 14);
      expect(werteAus('2 * 3 + 4', const {}), 10);
    });

    test('Klammern gehen vor', () {
      expect(werteAus('(2 + 3) * 4', const {}), 20);
    });

    test('Subtraktion und Division sind linksassoziativ', () {
      expect(werteAus('10 - 3 - 2', const {}), 5);
      expect(werteAus('100 / 5 / 2', const {}), 10);
    });

    test('Leerzeichen sind belanglos', () {
      expect(werteAus('  2+3  ', const {}), 5);
      expect(werteAus('2*3', const {}), 6);
    });

    test('Dezimalzahlen', () {
      expect(werteAus('0.92 * 5.5', const {}), closeTo(5.06, 0.0001));
    });
  });

  group('Potenz und Vorzeichen', () {
    test('rechtsassoziativ', () {
      // 2^(3^2) = 512, nicht (2^3)^2 = 64.
      expect(werteAus('2^3^2', const {}), 512);
    });

    test('das Vorzeichen bindet schwächer als die Potenz', () {
      expect(werteAus('-2^2', const {}), -4);
    });

    test('negativer Exponent', () {
      expect(werteAus('2^-1', const {}), 0.5);
    });

    test('unäres Minus vor Klammer und Variable', () {
      expect(werteAus('-(2 + 3)', const {}), -5);
      expect(werteAus('3 * -x', const {'x': 4}), -12);
    });
  });

  group('Variablen, Konstanten, Funktionen', () {
    test('Variablen werden eingesetzt', () {
      expect(
        werteAus('eta * P1', const {'eta': 0.92, 'P1': 5.5}),
        closeTo(5.06, 1e-9),
      );
    });

    test('Variablennamen dürfen Ziffern und Unterstriche enthalten', () {
      expect(werteAus('z_2 / z1', const {'z_2': 60, 'z1': 20}), 3);
    });

    test('pi ist bekannt', () {
      expect(werteAus('2 * pi', const {}), closeTo(6.28318, 0.0001));
    });

    test('e ist KEINE Konstante, sondern eine gewöhnliche Variable', () {
      // In technischen Aufgaben ist "e" fast immer die Exzentrizität oder
      // die Dehnung. Ein stiller Namenskonflikt wäre hier nicht bemerkbar.
      expect(werteAus('e * 2', const {'e': 5}), 10);
      expect(() => werteAus('e * 2', const {}), throwsA(isA<FormelException>()));
    });

    test('sqrt', () {
      expect(werteAus('sqrt(P / R)', const {'P': 5, 'R': 1500}), closeTo(0.05774, 0.0001));
    });

    test('Winkelfunktionen rechnen in Grad', () {
      expect(werteAus('sin(30)', const {}), closeTo(0.5, 0.0001));
      expect(werteAus('cos(60)', const {}), closeTo(0.5, 0.0001));
      expect(werteAus('tan(45)', const {}), closeTo(1.0, 0.0001));
    });

    test('min und max nehmen mehrere Argumente', () {
      expect(werteAus('min(3, 7, 5)', const {}), 3);
      expect(werteAus('max(3, 7, 5)', const {}), 7);
    });

    test('round, floor, ceil, abs', () {
      expect(werteAus('round(2.6)', const {}), 3);
      expect(werteAus('floor(2.6)', const {}), 2);
      expect(werteAus('ceil(2.1)', const {}), 3);
      expect(werteAus('abs(0 - 4)', const {}), 4);
    });
  });

  // Jeder dieser Fälle muss laut werden. Ein still zurückgegebenes NaN würde
  // als Lösungswert in eine Aufgabe wandern und dort jede Eingabe verwerfen.
  group('Fehler bleiben nicht still', () {
    test('unbekannte Variable', () {
      expect(
        () => werteAus('a * b', const {'a': 2}),
        throwsA(
          isA<FormelException>().having(
            (e) => e.nachricht,
            'nachricht',
            contains('b'),
          ),
        ),
      );
    });

    test('unbekannte Funktion', () {
      expect(
        () => werteAus('wurzel(4)', const {}),
        throwsA(isA<FormelException>()),
      );
    });

    test('Division durch null', () {
      expect(
        () => werteAus('5 / x', const {'x': 0}),
        throwsA(isA<FormelException>()),
      );
    });

    test('fehlende Klammer', () {
      expect(() => werteAus('(2 + 3', const {}), throwsA(isA<FormelException>()));
    });

    test('unvollständiger Ausdruck', () {
      expect(() => werteAus('2 +', const {}), throwsA(isA<FormelException>()));
      expect(() => werteAus('', const {}), throwsA(isA<FormelException>()));
    });

    test('Müll hinter dem Ausdruck', () {
      expect(() => werteAus('2 + 3 )', const {}), throwsA(isA<FormelException>()));
    });

    test('falsche Anzahl Argumente', () {
      expect(
        () => werteAus('sqrt(4, 9)', const {}),
        throwsA(isA<FormelException>()),
      );
    });

    test('ein NaN-Ergebnis wird gemeldet, nicht durchgereicht', () {
      // Wurzel aus einer negativen Zahl.
      expect(
        () => werteAus('sqrt(0 - 1)', const {}),
        throwsA(isA<FormelException>()),
      );
    });
  });

  group('variablenIn', () {
    test('findet Variablen und lässt Funktionen und pi aus', () {
      expect(variablenIn('sqrt(P / R) * pi + n_ab'), {'P', 'R', 'n_ab'});
    });

    test('eine Formel ohne Variablen ergibt eine leere Menge', () {
      expect(variablenIn('2 * 3'), isEmpty);
    });
  });
}
