// Die Kursverwaltung ist der Screen, der die App vom AP2-Trainer zum
// allgemeinen Lernwerkzeug macht. Parser, Store und Migration sind einzeln
// getestet - hier geht es um das Zusammenspiel in der Oberfläche:
// Vorschau vor dem Installieren, Warnungen, Fehlerbehandlung, Entfernen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/kurse/screens/kurs_verwaltung_screen.dart';
import 'package:meine_app/models/kurs.dart';

Kurs _kurs({
  required String id,
  required String titel,
  KursQuelle quelle = KursQuelle.importiert,
  String beschreibung = '',
  String? version,
  List<PruefungsDefinition> pruefungen = const [],
  KursFeatures features = const KursFeatures(),
}) => Kurs(
  id: id,
  titel: titel,
  kurzbeschreibung: beschreibung,
  version: version,
  bereiche: const [
    Bereich(id: 'a', titel: 'Bereich A'),
    Bereich(id: 'b', titel: 'Bereich B'),
  ],
  pruefungen: pruefungen,
  features: features,
  quelle: quelle,
);

Future<void> _pumpe(
  WidgetTester tester, {
  required List<Kurs> kurse,
  String? aktiv,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alleKurseProvider.overrideWith((_) async => kurse),
        // Immer überschreiben: Der echte Controller liest den SettingsStore
        // und damit Hive, das im Widget-Test nicht geöffnet ist.
        aktiverKursIdProvider.overrideWith(() => _FesterKurs(aktiv)),
      ],
      child: const MaterialApp(home: KursVerwaltungScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Ersetzt den persistierenden Controller - der Test soll nicht an Hive.
class _FesterKurs extends AktiverKursController {
  _FesterKurs(this._id);
  final String? _id;

  @override
  String? build() => _id;

  @override
  Future<void> wechseln(String kursId) async => state = kursId;
}

void main() {
  testWidgets('listet alle installierten Kurse', (tester) async {
    await _pumpe(
      tester,
      kurse: [
        _kurs(
          id: 'ap2',
          titel: 'AP2 Industriemechaniker',
          quelle: KursQuelle.gebuendelt,
        ),
        _kurs(id: 'spanisch', titel: 'Spanisch A1', version: '1.0.0'),
      ],
      aktiv: 'ap2',
    );

    expect(find.text('AP2 Industriemechaniker'), findsOneWidget);
    expect(find.text('Spanisch A1'), findsOneWidget);
    expect(find.text('Paket importieren'), findsOneWidget);
  });

  testWidgets('der aktive Kurs ist als solcher markiert', (tester) async {
    await _pumpe(
      tester,
      kurse: [
        _kurs(id: 'ap2', titel: 'AP2', quelle: KursQuelle.gebuendelt),
        _kurs(id: 'spanisch', titel: 'Spanisch A1'),
      ],
      aktiv: 'spanisch',
    );

    expect(find.widgetWithText(Chip, 'Aktiv'), findsOneWidget);
  });

  // Ein gebündelter Kurs liegt in den App-Assets und wäre beim nächsten
  // Start ohnehin wieder da - ihn löschen zu können wäre irreführend.
  testWidgets('nur importierte Kurse lassen sich entfernen', (tester) async {
    await _pumpe(
      tester,
      kurse: [
        _kurs(id: 'ap2', titel: 'AP2', quelle: KursQuelle.gebuendelt),
        _kurs(id: 'spanisch', titel: 'Spanisch A1'),
      ],
      aktiv: 'ap2',
    );

    // Genau ein Löschknopf, und zwar beim importierten Kurs.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('Herkunft und Umfang stehen an jeder Karte', (tester) async {
    await _pumpe(
      tester,
      kurse: [
        _kurs(id: 'ap2', titel: 'AP2', quelle: KursQuelle.gebuendelt),
        _kurs(id: 'spanisch', titel: 'Spanisch A1', version: '2.1.0'),
      ],
      aktiv: 'ap2',
    );

    expect(find.text('Mitgeliefert'), findsOneWidget);
    expect(find.text('Importiert'), findsOneWidget);
    expect(find.text('2 Bereiche'), findsNWidgets(2));
    expect(find.text('2.1.0'), findsOneWidget);
  });

  // Testläufe sollen nur auftauchen, wenn der Kurs sie auch mitbringt -
  // sonst verspricht die Karte etwas, das der Kurs nicht einlöst.
  testWidgets('Testläufe erscheinen nur bei passenden Kursen', (tester) async {
    await _pumpe(
      tester,
      kurse: [
        _kurs(id: 'ohne', titel: 'Ohne Testlauf'),
        _kurs(
          id: 'mit',
          titel: 'Mit Testlauf',
          features: const KursFeatures(pruefungssimulation: true),
          pruefungen: const [
            PruefungsDefinition(code: 't1', titel: 'Test 1'),
            PruefungsDefinition(code: 't2', titel: 'Test 2'),
          ],
        ),
      ],
      aktiv: 'ohne',
    );

    expect(find.text('2× Testlauf'), findsOneWidget);
  });

  testWidgets('das Entfernen fragt vorher nach', (tester) async {
    await _pumpe(
      tester,
      kurse: [_kurs(id: 'spanisch', titel: 'Spanisch A1')],
      aktiv: 'spanisch',
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('"Spanisch A1" entfernen?'), findsOneWidget);
    expect(
      find.textContaining('lässt sich nicht rückgängig machen'),
      findsOneWidget,
    );

    // Abbrechen darf nichts anfassen.
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Spanisch A1'), findsOneWidget);
  });

  testWidgets('eine leere Kursliste stürzt nicht ab', (tester) async {
    await _pumpe(tester, kurse: const []);

    expect(find.text('Installierte Lernpakete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ein Ladefehler wird angezeigt statt verschluckt', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alleKurseProvider.overrideWith(
            (_) async => throw StateError('Box kaputt'),
          ),
          aktiverKursIdProvider.overrideWith(() => _FesterKurs(null)),
        ],
        child: const MaterialApp(home: KursVerwaltungScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Kurse nicht ladbar'), findsOneWidget);
  });
}
