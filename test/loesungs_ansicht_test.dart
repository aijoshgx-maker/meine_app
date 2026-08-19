// Die Lösungsdarstellung nach dem Aufdecken.
//
// Vorher stand dort nur der Erklärungstext - bei Zuordnungen, Lückentexten
// und Reihenfolgen musste man sich die Lösung daraus zusammenreimen. Diese
// Tests halten je Fragetyp fest, dass die erwartete Antwort erscheint, und
// dass bei einer falschen Antwort der Vergleich sichtbar wird.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/widgets/loesungs_ansicht.dart';
import 'package:meine_app/models/frage.dart';

Frage _frage({
  required String typ,
  List<String> optionen = const [],
  List<int> richtigeIndizes = const [],
  List<int> reihenfolge = const [],
  List<Paar> paare = const [],
  List<List<String>> luecken = const [],
  List<String> akzeptierteKurzantworten = const [],
  double? loesungswert,
  String? einheit,
  double? toleranz,
  bool? wahr,
}) => Frage(
  id: 'x',
  bereich: 'allgemein',
  kategorie: 'Test',
  typ: typ,
  frage: 'Testfrage',
  optionen: optionen,
  richtigeIndizes: richtigeIndizes,
  reihenfolge: reihenfolge,
  paare: paare,
  luecken: luecken,
  akzeptierteKurzantworten: akzeptierteKurzantworten,
  loesungswert: loesungswert,
  einheit: einheit,
  toleranz: toleranz,
  wahr: wahr,
  erklaerung: 'Weil.',
  schwierigkeit: 1,
);

Future<void> _pumpe(
  WidgetTester tester,
  Frage frage,
  AntwortZustand antwort,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LoesungsAnsicht(frage: frage, antwort: antwort),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Textdekoration des Spans, der genau [text] enthält.
///
/// Die Zeilen werden als Text.rich mit mehreren Spans gebaut (Vorsatz +
/// Inhalt), deshalb reicht ein Blick auf den äußeren Stil nicht.
TextDecoration? _dekorationVon(WidgetTester tester, String text) {
  for (final element in find.byType(Text).evaluate()) {
    final span = (element.widget as Text).textSpan;
    if (span is! TextSpan) continue;

    for (final kind in span.children ?? const <InlineSpan>[]) {
      if (kind is TextSpan && kind.text == text) return kind.style?.decoration;
    }
  }
  fail('Kein Textspan mit "$text" gefunden.');
}

void main() {
  group('single und multi', () {
    final frage = _frage(
      typ: 'multi',
      optionen: const ['Drehen', 'Fräsen', 'Gießen', 'Schweißen'],
      richtigeIndizes: const [0, 1],
    );

    testWidgets('zeigt die richtigen Optionen', (tester) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(ausgewaehlteIndizes: {0, 1}, korrekt: true),
      );

      expect(find.text('Drehen'), findsOneWidget);
      expect(find.text('Fräsen'), findsOneWidget);
      // Nicht gewählte falsche Optionen bleiben draußen - sonst wäre die
      // Lösung nur eine Wiederholung der Frage.
      expect(find.text('Gießen'), findsNothing);
    });

    testWidgets('markiert falsch Angekreuztes zusätzlich', (tester) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(ausgewaehlteIndizes: {0, 2}, korrekt: false),
      );

      expect(find.text('Drehen'), findsOneWidget);
      expect(find.text('Fräsen'), findsOneWidget, reason: 'übersehen');
      expect(find.text('Gießen'), findsOneWidget, reason: 'falsch gewählt');

      // Durchgestrichen, damit der Unterschied auch ohne Farbsehen
      // erkennbar ist.
      expect(
        _dekorationVon(tester, 'Gießen'),
        TextDecoration.lineThrough,
        reason: 'Falsch Angekreuztes muss durchgestrichen sein.',
      );
      expect(
        _dekorationVon(tester, 'Fräsen'),
        isNull,
        reason: 'Die richtige Antwort darf nicht durchgestrichen sein.',
      );
    });
  });

  testWidgets('wahrfalsch zeigt die Aussage', (tester) async {
    await _pumpe(
      tester,
      _frage(typ: 'wahrfalsch', wahr: false),
      const AntwortZustand(korrekt: false),
    );

    expect(find.text('Falsch'), findsOneWidget);
  });

  group('rechnung', () {
    final frage = _frage(
      typ: 'rechnung',
      loesungswert: 100.53,
      einheit: 'm/min',
      toleranz: 1.0,
    );

    testWidgets('zeigt Wert, Einheit und Toleranz', (tester) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(freitext: '100,5', korrekt: true),
      );

      expect(find.text('100.53 m/min'), findsOneWidget);
      expect(find.textContaining('± 1'), findsOneWidget);
    });

    testWidgets('bei falscher Antwort steht die eigene Eingabe daneben', (
      tester,
    ) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(freitext: '95', korrekt: false),
      );

      expect(find.text('100.53 m/min'), findsOneWidget);
      expect(find.textContaining('95 m/min'), findsOneWidget);
    });

    testWidgets('ganze Zahlen ohne Komma', (tester) async {
      await _pumpe(
        tester,
        _frage(typ: 'rechnung', loesungswert: 60.0, einheit: 'cm³/min'),
        const AntwortZustand(korrekt: true),
      );

      expect(find.text('60 cm³/min'), findsOneWidget);
    });
  });

  group('kurzantwort', () {
    testWidgets('zeigt die erwartete Antwort und Alternativen', (tester) async {
      await _pumpe(
        tester,
        _frage(
          typ: 'kurzantwort',
          akzeptierteKurzantworten: const ['Gleitringdichtung', 'GLRD'],
        ),
        const AntwortZustand(freitext: 'Gleitringdichtung', korrekt: true),
      );

      expect(find.text('Gleitringdichtung'), findsOneWidget);
      expect(find.textContaining('GLRD'), findsOneWidget);
    });
  });

  group('lueckentext', () {
    final frage = _frage(
      typ: 'lueckentext',
      luecken: const [
        ['Oslo'],
        ['Helsinki'],
      ],
    );

    testWidgets('zeigt jede Lücke einzeln', (tester) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(
          lueckenAntworten: {0: 'Oslo', 1: 'Helsinki'},
          korrekt: true,
        ),
      );

      expect(find.textContaining('Lücke 1'), findsOneWidget);
      expect(find.textContaining('Oslo'), findsOneWidget);
      expect(find.textContaining('Helsinki'), findsOneWidget);
    });

    // Nur die abweichende Lücke bekommt den Vergleich - sonst wird die
    // Lösung von "du: ..."-Wiederholungen zugestellt.
    testWidgets('vergleicht nur die abweichenden Lücken', (tester) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(
          lueckenAntworten: {0: 'Oslo', 1: 'Stockholm'},
          korrekt: false,
        ),
      );

      expect(find.text('du: Stockholm'), findsOneWidget);
      expect(find.text('du: Oslo'), findsNothing);
    });
  });

  group('zuordnung', () {
    final frage = _frage(
      typ: 'zuordnung',
      paare: const [
        Paar(links: 'Tiefziehen', rechts: 'Zugdruckumformen'),
        Paar(links: 'Schmieden', rechts: 'Druckumformen'),
      ],
    );

    testWidgets('zeigt die Sollpaare', (tester) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(zuordnungsAuswahl: {0: 0, 1: 1}, korrekt: true),
      );

      expect(find.textContaining('Tiefziehen'), findsOneWidget);
      expect(find.textContaining('Zugdruckumformen'), findsOneWidget);
    });

    testWidgets('zeigt bei Vertauschung die eigene Zuordnung', (tester) async {
      await _pumpe(
        tester,
        frage,
        const AntwortZustand(zuordnungsAuswahl: {0: 1, 1: 0}, korrekt: false),
      );

      expect(find.text('du: Druckumformen'), findsOneWidget);
      expect(find.text('du: Zugdruckumformen'), findsOneWidget);
    });
  });

  testWidgets('reihenfolge zeigt die Sollreihenfolge nummeriert', (
    tester,
  ) async {
    await _pumpe(
      tester,
      _frage(
        typ: 'reihenfolge',
        optionen: const ['Berlin', 'Madrid', 'Rom'],
        reihenfolge: const [1, 0, 2],
      ),
      const AntwortZustand(reihenfolgeAuswahl: [0, 1, 2], korrekt: false),
    );

    expect(find.textContaining('Madrid'), findsOneWidget);
    expect(find.textContaining('1. '), findsOneWidget);
    expect(find.textContaining('3. '), findsOneWidget);
  });

  testWidgets('ohne verwertbare Daten erscheint gar nichts', (tester) async {
    await _pumpe(
      tester,
      _frage(typ: 'zuordnung'),
      const AntwortZustand(korrekt: true),
    );

    expect(find.text('Lösung'), findsNothing);
  });
}
