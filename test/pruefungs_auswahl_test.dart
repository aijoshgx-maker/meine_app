// Die Auswahl der Testläufe.
//
// Der Anlass: Die Karte meldete „unvollständiger Datensatz", indem sie jeden
// Testlauf gegen den GRÖSSTEN der vorhandenen verglich. Da nur einer der
// größte sein kann, waren drei von vier immer rot — die Meldung behauptete
// ein Datenproblem, das es nicht gab.
//
// Verglichen wird jetzt gegen eine Sollzahl aus dem Kurs. Wo der Kurs keine
// kennt, gibt es nichts zu vergleichen und also auch nichts zu melden.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/pruefungssimulation/screens/pruefungs_auswahl_screen.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/kurs.dart';

import 'hilfen/test_kurs.dart';

Frage _frage(String id, String pruefung) => Frage(
  id: id,
  bereich: 'allgemein',
  kategorie: 'Test',
  typ: 'single',
  frage: 'Testfrage $id',
  optionen: const ['A', 'B'],
  richtigeIndizes: const [0],
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'Weil.',
  schwierigkeit: 1,
  pruefung: pruefung,
);

/// [anzahlProCode] legt fest, wie viele Fragen es je Testlauf gibt.
Future<void> _pumpe(
  WidgetTester tester, {
  required Map<String, int> anzahlProCode,
  Map<String, int?> sollProCode = const {},
}) async {
  final fragen = <Frage>[];
  anzahlProCode.forEach((code, anzahl) {
    for (var i = 0; i < anzahl; i++) {
      fragen.add(_frage('$code-$i', code));
    }
  });

  final kurs = testKurs(
    features: const KursFeatures(pruefungssimulation: true),
    pruefungen: [
      for (final code in anzahlProCode.keys)
        PruefungsDefinition(
          code: code,
          titel: 'Testlauf $code',
          aufgabenAnzahl: sollProCode[code],
        ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aktivesPaketProvider.overrideWith(
          (_) async => testPaket(fragen, kurs: kurs),
        ),
      ],
      child: const MaterialApp(home: PruefungsAuswahlScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Der eigentliche Fehler: Ohne Sollzahl gibt es keinen Maßstab. Vorher
  // wurden hier zwei von drei Testläufen rot markiert.
  testWidgets('ohne Sollzahl meldet kein Testlauf einen Mangel', (
    tester,
  ) async {
    await _pumpe(tester, anzahlProCode: const {'A': 20, 'B': 38, 'C': 36});

    expect(find.textContaining('unvollständiger Datensatz'), findsNothing);
    expect(find.text('20 Aufgaben verfügbar'), findsOneWidget);
    expect(find.text('38 Aufgaben verfügbar'), findsOneWidget);
    expect(find.text('36 Aufgaben verfügbar'), findsOneWidget);
  });

  testWidgets('mit erreichter Sollzahl bleibt die Karte unauffällig', (
    tester,
  ) async {
    await _pumpe(
      tester,
      anzahlProCode: const {'A': 40},
      sollProCode: const {'A': 40},
    );

    expect(find.text('40 Aufgaben verfügbar'), findsOneWidget);
    expect(find.textContaining('unvollständiger Datensatz'), findsNothing);
  });

  testWidgets('mit verfehlter Sollzahl steht der Hinweis da', (tester) async {
    await _pumpe(
      tester,
      anzahlProCode: const {'A': 31},
      sollProCode: const {'A': 40},
    );

    expect(
      find.textContaining('31 von 40 Aufgaben verfügbar'),
      findsOneWidget,
    );
    expect(find.textContaining('unvollständiger Datensatz'), findsOneWidget);
  });

  // Die Sollzahl gilt je Testlauf, nicht für alle gemeinsam.
  testWidgets('ein Testlauf ohne Sollzahl bleibt neben einem mit ruhig', (
    tester,
  ) async {
    await _pumpe(
      tester,
      anzahlProCode: const {'A': 12, 'B': 31},
      sollProCode: const {'B': 40},
    );

    expect(find.text('12 Aufgaben verfügbar'), findsOneWidget);
    expect(find.textContaining('31 von 40'), findsOneWidget);
    expect(find.textContaining('unvollständiger Datensatz'), findsOneWidget);
  });

  testWidgets('Testläufe ohne Aufgaben erscheinen gar nicht', (tester) async {
    await _pumpe(tester, anzahlProCode: const {'A': 5});

    expect(find.text('Testlauf A'), findsOneWidget);
    expect(find.text('Testlauf B'), findsNothing);
  });
}
