import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/frage_repository.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'FrageRepository lädt alle Startfragen mit allen 6 Fragetypen',
    () async {
      final fragen = await FrageRepository().laden();

      expect(fragen, isNotEmpty);

      final vorhandeneTypen = fragen.map((f) => frageTypVon(f.typ)).toSet();
      expect(vorhandeneTypen, FrageTyp.values.toSet());

      final rechnung = fragen.firstWhere((f) => f.typ == 'rechnung');
      expect(rechnung.loesungswert, isNotNull);
      expect(rechnung.toleranz, isNotNull);
      expect(rechnung.workedExample, isNotNull);

      for (final f in fragen) {
        expect([
          'auftragsanalyse',
          'fertigungstechnik',
          'wiso',
        ], contains(f.bereich));
      }
    },
  );
}
