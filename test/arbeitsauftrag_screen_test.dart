import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/arbeitsauftrag_store.dart';
import 'package:meine_app/features/arbeitsauftrag/providers/arbeitsauftrag_providers.dart';
import 'package:meine_app/features/arbeitsauftrag/screens/arbeitsauftrag_screen.dart';

class _FakeArbeitsauftragStore implements ArbeitsauftragStore {
  final Map<String, bool> checklist = {};
  final Map<String, String> dokumentation = {};
  final Map<String, String> fachgespraech = {};

  @override
  Map<String, bool> checklistStatus() => Map.of(checklist);

  @override
  Future<void> checklistSetzen(String itemId, bool erledigt) async {
    checklist[itemId] = erledigt;
  }

  @override
  Map<String, String> dokumentationLaden() => Map.of(dokumentation);

  @override
  Future<void> dokumentationSpeichern(Map<String, String> felder) async {
    dokumentation
      ..clear()
      ..addAll(felder);
  }

  @override
  Map<String, String> fachgespraechAntworten() => Map.of(fachgespraech);

  @override
  Future<void> fachgespraechAntwortSetzen(String fragId, String text) async {
    fachgespraech[fragId] = text;
  }
}

void main() {
  testWidgets('Checkliste abhaken persistiert im Store', (tester) async {
    final store = _FakeArbeitsauftragStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [arbeitsauftragStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: ArbeitsauftragScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arbeitsauftrag vollständig gelesen'), findsOneWidget);

    await tester.tap(find.text('Arbeitsauftrag vollständig gelesen'));
    await tester.pumpAndSettle();

    expect(store.checklist['info-1'], true);
  });

  testWidgets('Tab-Wechsel zur Dokumentation zeigt die Doku-Felder', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          arbeitsauftragStoreProvider.overrideWithValue(
            _FakeArbeitsauftragStore(),
          ),
        ],
        child: const MaterialApp(home: ArbeitsauftragScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dokumentation'));
    await tester.pumpAndSettle();

    expect(find.text('Auftragsbeschreibung'), findsOneWidget);
  });
}
