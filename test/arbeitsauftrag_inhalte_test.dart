import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/arbeitsauftrag_inhalte.dart';

void main() {
  test('alle 4 Phasen sind in der Checkliste vertreten', () {
    final phasen = checklistenEintraege.map((e) => e.phase).toSet();
    expect(phasen, ArbeitsauftragPhase.values.toSet());
  });

  test('keine doppelten Checklisten-IDs', () {
    final ids = checklistenEintraege.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('8-12 Fachgespräch-Fragen, keine doppelten IDs', () {
    expect(fachgespraechFragen.length, inInclusiveRange(8, 12));
    final ids = fachgespraechFragen.map((f) => f.$1).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('Dokumentationsfelder haben eindeutige Feld-IDs', () {
    final ids = dokumentationsFelder.map((f) => f.$1).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, isNotEmpty);
  });
}
