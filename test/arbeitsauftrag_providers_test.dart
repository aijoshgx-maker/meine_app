import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/arbeitsauftrag_store.dart';
import 'package:meine_app/features/arbeitsauftrag/providers/arbeitsauftrag_providers.dart';

class _FakeArbeitsauftragStore implements ArbeitsauftragStore {
  final Map<String, bool> _checklist = {};
  final Map<String, String> _dokumentation = {};
  final Map<String, String> _fachgespraech = {};

  @override
  Map<String, bool> checklistStatus() => Map.of(_checklist);

  @override
  Future<void> checklistSetzen(String itemId, bool erledigt) async {
    _checklist[itemId] = erledigt;
  }

  @override
  Map<String, String> dokumentationLaden() => Map.of(_dokumentation);

  @override
  Future<void> dokumentationSpeichern(Map<String, String> felder) async {
    _dokumentation
      ..clear()
      ..addAll(felder);
  }

  @override
  Map<String, String> fachgespraechAntworten() => Map.of(_fachgespraech);

  @override
  Future<void> fachgespraechAntwortSetzen(String fragId, String text) async {
    _fachgespraech[fragId] = text;
  }
}

void main() {
  test(
    'checklistFortschrittProvider berechnet den Anteil erledigter Items',
    () async {
      final store = _FakeArbeitsauftragStore();
      final container = ProviderContainer(
        overrides: [arbeitsauftragStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(container.read(checklistFortschrittProvider), 0.0);

      await container.read(checklistProvider.notifier).umschalten('info-1');

      final erwarteterAnteil =
          1 / 20; // 1 von 20 Items aus arbeitsauftrag_inhalte.dart
      expect(
        container.read(checklistFortschrittProvider),
        closeTo(erwarteterAnteil, 0.001),
      );
      expect(store.checklistStatus()['info-1'], true);
    },
  );

  test('dokumentationProvider persistiert Feldänderungen im Store', () async {
    final store = _FakeArbeitsauftragStore();
    final container = ProviderContainer(
      overrides: [arbeitsauftragStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container
        .read(dokumentationProvider.notifier)
        .feldSetzen('ergebnis', 'Funktioniert wie erwartet.');

    expect(
      container.read(dokumentationProvider)['ergebnis'],
      'Funktioniert wie erwartet.',
    );
    expect(
      store.dokumentationLaden()['ergebnis'],
      'Funktioniert wie erwartet.',
    );
  });
}
