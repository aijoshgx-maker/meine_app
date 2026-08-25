// Variierende Aufgaben: aus der Beschreibung wird eine gewöhnliche Frage.
//
// Was hier schiefgehen kann, sieht man der App nicht an: eine falsch
// eingesetzte Zahl, ein Lösungsweg, der nicht zu den gezeigten Werten passt,
// oder ein Lösungswert, den niemand treffen kann. Alles drei sähe für den
// Lernenden nach dem eigenen Fehler aus.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/quiz/frage_variante.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/frage_varianten.dart';

Frage _rechenfrage({FrageVarianten? varianten}) => Frage(
  id: 'test-001',
  bereich: 'auftragsanalyse',
  kategorie: 'Antriebstechnik (mechanisch)',
  typ: 'rechnung',
  frage: 'Ein Motor liefert P₁ = 5,5 kW bei η = 0,92. Berechne P₂.',
  optionen: const [],
  richtigeIndizes: const [],
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  loesungswert: 5.06,
  einheit: 'kW',
  toleranz: 0.05,
  akzeptierteKurzantworten: const [],
  erklaerung: 'η = P₂/P₁',
  workedExample: 'P₂ = 0,92 · 5,5 kW = 5,06 kW',
  schwierigkeit: 2,
  varianten: varianten,
);

const _wirkungsgrad = FrageVarianten(
  variablen: {
    'P1': VariablenQuelle(von: 2.2, bis: 15.0, schritt: 0.1),
    'eta': VariablenQuelle(werte: [0.82, 0.85, 0.88, 0.9, 0.92, 0.95]),
  },
  original: {'P1': 5.5, 'eta': 0.92},
  frage: 'Ein Motor liefert P₁ = {P1} kW bei η = {eta}. Berechne P₂.',
  loesung: 'eta * P1',
  rundung: 2,
  toleranzProzent: 1.0,
  workedExample: 'P₂ = {eta} · {P1} kW = {loesung} kW',
);

void main() {
  test('eine Frage ohne Varianten kommt unverändert zurück', () {
    final frage = _rechenfrage();
    final variante = wuerfleVariante(frage, Random(1));

    expect(identical(variante, frage), isTrue);
  });

  test('mit Originalwerten steht die Aufgabe wieder wie zuvor da', () {
    final frage = _rechenfrage(varianten: _wirkungsgrad);
    final variante = wuerfleVariante(frage, Random(1), originalwerte: true);

    expect(variante.frage, frage.frage);
    expect(variante.loesungswert, closeTo(5.06, 1e-9));
    expect(variante.workedExample, 'P₂ = 0,92 · 5,5 kW = 5,06 kW');
  });

  test('gewürfelt: Text, Lösungswert und Lösungsweg passen zueinander', () {
    final frage = _rechenfrage(varianten: _wirkungsgrad);
    final variante = wuerfleVariante(frage, Random(7));

    // Kein Platzhalter darf stehen bleiben.
    expect(variante.frage, isNot(contains('{')));
    expect(variante.workedExample, isNot(contains('{')));

    // Die Zahlen aus dem Fragetext müssen im Lösungsweg wieder auftauchen -
    // sonst rechnet der Weg eine andere Aufgabe vor als die gestellte.
    final zahlen = RegExp(r'[\d,]+').allMatches(variante.frage).map((m) => m.group(0));
    for (final zahl in zahlen) {
      expect(variante.workedExample, contains(zahl));
    }
  });

  test('derselbe Seed ergibt dieselbe Aufgabe', () {
    final frage = _rechenfrage(varianten: _wirkungsgrad);

    expect(
      wuerfleVariante(frage, Random(42)).frage,
      wuerfleVariante(frage, Random(42)).frage,
    );
  });

  test('über viele Ziehungen entstehen wirklich verschiedene Aufgaben', () {
    final frage = _rechenfrage(varianten: _wirkungsgrad);
    final texte = {
      for (var i = 0; i < 50; i++) wuerfleVariante(frage, Random(i)).frage,
    };

    expect(texte.length, greaterThan(10));
  });

  group('Zahlen', () {
    test('werden deutsch geschrieben, ohne nachlaufende Nullen', () {
      final variante = wuerfleVariante(
        _rechenfrage(varianten: _wirkungsgrad),
        Random(1),
        originalwerte: true,
      );

      expect(variante.frage, contains('5,5 kW'));
      expect(variante.frage, isNot(contains('5.5')));
      expect(variante.frage, isNot(contains('5,5000')));
    });

    test('ganze Zahlen bekommen kein Komma', () {
      const varianten = FrageVarianten(
        variablen: {'n': VariablenQuelle(werte: [960])},
        original: {'n': 960},
        frage: 'Drehzahl {n} min⁻¹',
        loesung: 'n / 2',
        rundung: 0,
      );
      final variante = wuerfleVariante(
        _rechenfrage(varianten: varianten),
        Random(1),
      );

      expect(variante.frage, 'Drehzahl 960 min⁻¹');
      expect(variante.loesungswert, 480);
    });

    test('der Lösungswert wird auf die angegebene Stellenzahl gerundet', () {
      const varianten = FrageVarianten(
        variablen: {'n': VariablenQuelle(werte: [960])},
        original: {'n': 960},
        loesung: 'n / 9',
        rundung: 2,
      );
      final variante = wuerfleVariante(
        _rechenfrage(varianten: varianten),
        Random(1),
      );

      expect(variante.loesungswert, 106.67);
    });
  });

  group('Zwischenschritte', () {
    test('werden der Reihe nach ausgewertet und sind einsetzbar', () {
      const varianten = FrageVarianten(
        variablen: {
          'z1': VariablenQuelle(werte: [20]),
          'z2': VariablenQuelle(werte: [60]),
          'n1': VariablenQuelle(werte: [960]),
        },
        original: {'z1': 20, 'z2': 60, 'n1': 960},
        zwischen: {'i': 'z2 / z1', 'i_ges': 'i * 3'},
        frage: 'z₁ = {z1}, z₂ = {z2}, n₁ = {n1}',
        loesung: 'n1 / i_ges',
        rundung: 2,
        workedExample: 'i = {i}, i_ges = {i_ges}, n = {loesung}',
      );
      final variante = wuerfleVariante(
        _rechenfrage(varianten: varianten),
        Random(1),
      );

      expect(variante.workedExample, 'i = 3, i_ges = 9, n = 106,67');
      expect(variante.loesungswert, 106.67);
    });
  });

  group('Toleranz', () {
    test('toleranzProzent skaliert mit dem Lösungswert', () {
      final variante = wuerfleVariante(
        _rechenfrage(varianten: _wirkungsgrad),
        Random(1),
        originalwerte: true,
      );

      // 1 % von 5,06.
      expect(variante.toleranz, closeTo(0.0506, 1e-9));
    });

    test('die Rundung selbst bleibt immer im Spielraum', () {
      // Ohne Untergrenze wäre 1 % von 0,2 gerade noch 0,002 - der auf zwei
      // Stellen gerundete Wert läge dann außerhalb und niemand könnte die
      // Aufgabe richtig beantworten.
      const varianten = FrageVarianten(
        variablen: {'x': VariablenQuelle(werte: [0.2])},
        original: {'x': 0.2},
        loesung: 'x',
        rundung: 2,
        toleranzProzent: 0.1,
      );
      final variante = wuerfleVariante(
        _rechenfrage(varianten: varianten),
        Random(1),
      );

      expect(variante.toleranz, greaterThanOrEqualTo(0.005));
    });

    test('ohne toleranzProzent bleibt die Toleranz der Frage stehen', () {
      const varianten = FrageVarianten(
        variablen: {'x': VariablenQuelle(werte: [4])},
        original: {'x': 4},
        loesung: 'x',
      );
      final variante = wuerfleVariante(
        _rechenfrage(varianten: varianten),
        Random(1),
      );

      expect(variante.toleranz, 0.05);
    });
  });

  group('Tabellenquelle', () {
    const nachschlagen = FrageVarianten(
      spalten: ['nennmass', 'feld', 'hoechstmass'],
      zeilen: [
        [40, 'H7', '40,025'],
        [25, 'H7', '25,021'],
      ],
      original: {'nennmass': 40, 'feld': 'H7', 'hoechstmass': '40,025'},
      frage: 'Höchstmaß einer Bohrung Ø{nennmass} {feld}?',
      akzeptierteKurzantworten: ['{hoechstmass}', '{hoechstmass} mm'],
    );

    test('eine ganze Zeile wird gezogen, nie Werte aus zwei Zeilen', () {
      final frage = _rechenfrage(varianten: nachschlagen);

      for (var i = 0; i < 30; i++) {
        final variante = wuerfleVariante(frage, Random(i));
        final passt =
            (variante.frage.contains('Ø40') &&
                variante.akzeptierteKurzantworten.first == '40,025') ||
            (variante.frage.contains('Ø25') &&
                variante.akzeptierteKurzantworten.first == '25,021');
        expect(passt, isTrue, reason: 'zerrissene Zeile: ${variante.frage}');
      }
    });

    test('Textspalten werden unverändert eingesetzt', () {
      final variante = wuerfleVariante(
        _rechenfrage(varianten: nachschlagen),
        Random(1),
        originalwerte: true,
      );

      expect(variante.frage, 'Höchstmaß einer Bohrung Ø40 H7?');
      expect(variante.akzeptierteKurzantworten, ['40,025', '40,025 mm']);
    });
  });

  group('Fehler bleiben nicht still', () {
    test('ein unbelegter Platzhalter wird gemeldet', () {
      const varianten = FrageVarianten(
        variablen: {'x': VariablenQuelle(werte: [1])},
        original: {'x': 1},
        frage: 'Wert {y}',
        loesung: 'x',
      );

      expect(
        () => wuerfleVariante(_rechenfrage(varianten: varianten), Random(1)),
        throwsA(
          isA<VariantenException>().having(
            (e) => e.nachricht,
            'nachricht',
            contains('{y}'),
          ),
        ),
      );
    });

    test('eine kaputte Formel wird gemeldet', () {
      const varianten = FrageVarianten(
        variablen: {'x': VariablenQuelle(werte: [1])},
        original: {'x': 1},
        loesung: 'x * ',
      );

      expect(
        () => wuerfleVariante(_rechenfrage(varianten: varianten), Random(1)),
        throwsA(isA<VariantenException>()),
      );
    });
  });
}
