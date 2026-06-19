import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/lernplan_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'LernplanLoader lädt alle 5 Themenbereiche aus den JSON-Dateien',
    () async {
      final lernplan = await LernplanLoader().laden();

      expect(lernplan.themenbereiche.length, 5);

      final fertigungstechnik = lernplan.themenbereiche.firstWhere(
        (tb) => tb.id == 'fertigungstechnik',
      );
      expect(fertigungstechnik.module.length, 2);
      expect(
        fertigungstechnik.module
            .map((m) => m.karteikarten.length)
            .reduce((a, b) => a + b),
        16,
      );
      expect(fertigungstechnik.module.every((m) => m.hatInhalt), true);

      final platzhalterBereiche = lernplan.themenbereiche.where(
        (tb) => tb.id != 'fertigungstechnik',
      );
      for (final tb in platzhalterBereiche) {
        expect(tb.module.single.hatInhalt, false);
        expect(tb.module.single.karteikarten, isEmpty);
      }
    },
  );
}
