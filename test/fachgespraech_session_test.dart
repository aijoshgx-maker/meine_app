// Der Fachgespräch-Screen war mit 543 Zeilen die größte ungetestete Datei
// im Projekt - und der einzige Ablauf, der lokalen setState-Zustand über
// mehrere Schritte führt statt Riverpod zu nutzen.
//
// Getestet wird der komplette Durchlauf: antworten, aufdecken, weiter,
// Abschluss, neu starten.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/fachgespraech/screens/fachgespraech_session_screen.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/models/fachgespraech_szenario.dart';

import 'hilfen/test_kurs.dart';

const _szenarioId = 'fg-test-001';

final _szenario = FachgespraechSzenario(
  id: _szenarioId,
  titel: 'Instandhaltung einer Pumpe',
  kontext: 'Du stehst vor einer undichten Kreiselpumpe.',
  fertigungsauftrag: 'Ursache eingrenzen und Vorgehen erläutern.',
  kategorien: const ['Instandhaltung'],
  fragen: const [
    FachgespraechFrage(
      id: 'f1',
      pruefer: 'Woran erkennen Sie einen Lagerschaden?',
      musterloesung: 'An erhöhter Temperatur und veränderten Laufgeräuschen.',
      schluesselwoerter: ['Temperatur', 'Geräusch'],
      erklaerung: 'Beides sind Frühindikatoren.',
      schwierigkeit: 2,
    ),
    FachgespraechFrage(
      id: 'f2',
      pruefer: 'Welche Dichtung setzen Sie ein?',
      musterloesung: 'Eine Gleitringdichtung.',
      schluesselwoerter: ['Gleitringdichtung'],
      erklaerung: 'Standard bei Kreiselpumpen.',
      schwierigkeit: 2,
    ),
  ],
);

Future<void> _pumpe(
  WidgetTester tester, {
  String szenarioId = _szenarioId,
  List<FachgespraechSzenario>? szenarien,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aktivesPaketProvider.overrideWith(
          (_) async => testPaket(const [], szenarien: szenarien ?? [_szenario]),
        ),
      ],
      child: MaterialApp(
        home: FachgespraechSessionScreen(szenarioId: szenarioId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tippt auf [text], nachdem sichergestellt ist, dass er sichtbar ist.
///
/// Nach dem Aufdecken liegt der Weiter-Knopf unterhalb des Sichtbereichs -
/// ein blindes tap() landet dort im Leeren.
Future<void> _tippe(WidgetTester tester, String text) async {
  final ziel = find.text(text);
  await tester.ensureVisible(ziel);
  await tester.pumpAndSettle();
  await tester.tap(ziel);
  await tester.pumpAndSettle();
}

/// Beantwortet die aktuelle Frage mit [antwort] und deckt auf.
Future<void> _antworten(WidgetTester tester, String antwort) async {
  await tester.enterText(find.byType(TextField).first, antwort);
  await _tippe(tester, 'Antwort bestätigen');
}

/// Zählt die Schlüsselbegriff-Chips, die als getroffen markiert sind.
///
/// Der Screen zeigt IMMER alle Schlüsselwörter als Chip; ob einer erkannt
/// wurde, steckt im Avatar-Icon.
int _treffer() =>
    find.widgetWithIcon(Chip, Icons.check_circle).evaluate().length;

void main() {
  testWidgets('zeigt die erste Prüferfrage und den Fortschritt', (
    tester,
  ) async {
    await _pumpe(tester);

    expect(find.text('Instandhaltung einer Pumpe'), findsOneWidget);
    expect(find.text('Woran erkennen Sie einen Lagerschaden?'), findsWidgets);
    expect(find.text('Frage 1 / 2'), findsOneWidget);
  });

  testWidgets('erkannte Schlüsselbegriffe werden nach dem Aufdecken gezeigt', (
    tester,
  ) async {
    await _pumpe(tester);
    await _antworten(
      tester,
      'Die Temperatur steigt und das Geräusch verändert sich.',
    );

    expect(find.text('Musterlösung'), findsOneWidget);
    expect(_treffer(), 2, reason: 'Beide Schlüsselwörter kommen vor.');
  });

  // Der Matcher normalisiert Umlaute und arbeitet tokenweise - hier zahlt
  // sich aus, dass beides über AntwortMatcher läuft und nicht über einen
  // rohen Teilstring-Vergleich.
  testWidgets('Umlaute in der Antwort werden toleriert', (tester) async {
    await _pumpe(tester);
    await _antworten(tester, 'hoehere temperatur, lautes geraeusch');

    expect(_treffer(), 2, reason: 'Umlautschreibweise muss zählen.');
  });

  testWidgets('eine leere Antwort findet keine Begriffe', (tester) async {
    await _pumpe(tester);
    await _antworten(tester, '   ');

    expect(find.text('Musterlösung'), findsOneWidget);
    // Die Chips stehen trotzdem da - aber keiner ist als getroffen markiert.
    expect(find.byType(Chip), findsNWidgets(2));
    expect(_treffer(), 0);
  });

  testWidgets('der Knopf heißt bei der letzten Frage anders', (tester) async {
    await _pumpe(tester);

    await _antworten(tester, 'Temperatur');
    expect(find.text('Nächste Frage'), findsOneWidget);

    await _tippe(tester, 'Nächste Frage');
    expect(find.text('Frage 2 / 2'), findsOneWidget);

    await _antworten(tester, 'Gleitringdichtung');
    expect(find.text('Fachgespräch beenden'), findsOneWidget);
  });

  testWidgets('der Abschluss zählt die Treffer', (tester) async {
    await _pumpe(tester);

    // Erste Frage treffen, zweite bewusst danebenliegen.
    await _antworten(tester, 'Temperatur und Geräusch');
    await _tippe(tester, 'Nächste Frage');
    await _antworten(tester, 'weiß ich nicht');
    await _tippe(tester, 'Fachgespräch beenden');

    expect(find.text('Fachgespräch abgeschlossen!'), findsOneWidget);
    expect(
      find.text('1 / 2 Fragen mit Schlüsselbegriffen beantwortet'),
      findsOneWidget,
    );
  });

  // Regression: Beim Neustart müssen Index, Eingabefeld UND die gesammelten
  // Ergebnisse zurückgesetzt werden - sonst zählt der zweite Durchlauf die
  // Treffer des ersten mit.
  testWidgets('"Nochmal üben" setzt den Durchlauf vollständig zurück', (
    tester,
  ) async {
    await _pumpe(tester);

    await _antworten(tester, 'Temperatur und Geräusch');
    await _tippe(tester, 'Nächste Frage');
    await _antworten(tester, 'Gleitringdichtung');
    await _tippe(tester, 'Fachgespräch beenden');

    expect(
      find.text('2 / 2 Fragen mit Schlüsselbegriffen beantwortet'),
      findsOneWidget,
    );

    await _tippe(tester, 'Nochmal üben');

    expect(find.text('Frage 1 / 2'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      isEmpty,
    );

    // Zweiter Durchlauf, diesmal beide daneben: Wären die alten Ergebnisse
    // noch da, stünde hier 2 / 4.
    await _antworten(tester, 'keine Ahnung');
    await _tippe(tester, 'Nächste Frage');
    await _antworten(tester, 'auch nicht');
    await _tippe(tester, 'Fachgespräch beenden');

    expect(
      find.text('0 / 2 Fragen mit Schlüsselbegriffen beantwortet'),
      findsOneWidget,
    );
  });

  testWidgets('ein unbekanntes Szenario führt nicht zum Absturz', (
    tester,
  ) async {
    await _pumpe(tester, szenarioId: 'gibt-es-nicht');

    expect(find.text('Szenario nicht gefunden.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
