// Erkennung von Begriffen im Fragetext.
//
// Die Falle bei so einer Funktion ist nicht, zu wenig zu finden, sondern zu
// viel: Schlägt "Kraft" auch in "Kraftstoffpumpe" an, ist die Tippliste
// nach drei Fragen unbrauchbar und wird ignoriert.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/glossar.dart';

const _omega = GlossarEintrag(
  begriff: 'ω',
  alias: ['omega', 'Winkelgeschwindigkeit'],
  kurz: 'Wie schnell sich etwas dreht, in rad/s.',
  mehr: 'ω = 2·π·n',
);

const _kraft = GlossarEintrag(
  begriff: 'Kraft',
  alias: ['F'],
  kurz: 'Wirkt auf einen Körper, in Newton.',
);

const _durchmesser = GlossarEintrag(
  begriff: 'Ø',
  alias: ['Durchmesser'],
  kurz: 'Breite eines Kreises durch den Mittelpunkt.',
);

final _glossar = Glossar(const [_omega, _kraft, _durchmesser]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('findet ein Formelzeichen im Text', () {
    final treffer = _glossar.findeIn('Berechne ω bei n = 1500 min⁻¹.');
    expect(treffer.map((e) => e.begriff), ['ω']);
  });

  test('findet ein Zeichen auch direkt an einer Zahl', () {
    // "Ø32" hat keine Wortgrenze - Symbole muessen trotzdem anschlagen.
    final treffer = _glossar.findeIn('Die Welle hat Ø32 mm.');
    expect(treffer.map((e) => e.begriff), ['Ø']);
  });

  test('findet einen Begriff über sein Alias', () {
    final treffer = _glossar.findeIn('Wie hoch ist die Winkelgeschwindigkeit?');
    expect(treffer.map((e) => e.begriff), ['ω']);
  });

  test('ignoriert Groß-/Kleinschreibung und Umlautschreibweise', () {
    expect(_glossar.findeIn('WINKELGESCHWINDIGKEIT'), hasLength(1));
    expect(_glossar.findeIn('durchmesser der bohrung'), hasLength(1));
  });

  // Der wichtigste Test: Ohne Wortgrenzen wuerde die Liste zumuellen.
  test('schlägt nicht innerhalb längerer Wörter an', () {
    expect(_glossar.findeIn('Die Kraftstoffpumpe fördert.'), isEmpty);
    expect(_glossar.findeIn('Der Kraftaufwand ist hoch.'), isEmpty);
  });

  test('findet denselben Begriff nur einmal', () {
    final treffer = _glossar.findeIn(
      'Die Kraft F wirkt, wobei die Kraft konstant bleibt.',
    );
    expect(treffer, hasLength(1));
  });

  test('sortiert nach dem ersten Auftreten im Text', () {
    final treffer = _glossar.findeIn(
      'Bei Durchmesser 50 mm und ω = 100 rad/s wirkt eine Kraft.',
    );
    expect(treffer.map((e) => e.begriff), ['Ø', 'ω', 'Kraft']);
  });

  test('ohne Treffer kommt eine leere Liste', () {
    expect(_glossar.findeIn('Welches Werkzeug eignet sich?'), isEmpty);
    expect(_glossar.findeIn('   '), isEmpty);
    expect(Glossar.leer.findeIn('Berechne ω.'), isEmpty);
  });

  // Ohne Ausnahme wäre der Tipp bei manchen Fragen die Antwort.
  test('Ausnahmen blenden einzelne Einträge aus', () {
    const frage = 'Welche Einheit hat die Winkelgeschwindigkeit?';

    expect(_glossar.findeIn(frage), hasLength(1));
    expect(_glossar.findeIn(frage, ausnahmen: {'ω'}), isEmpty);
  });

  test('Roundtrip über JSON erhält alle Felder', () {
    final json = _glossar.toJson();
    final zurueck = Glossar.fromJson(json);

    expect(zurueck.eintraege, hasLength(3));
    final o = zurueck.eintraege.first;
    expect(o.begriff, 'ω');
    expect(o.alias, contains('Winkelgeschwindigkeit'));
    expect(o.mehr, 'ω = 2·π·n');
    // Ohne "mehr" bleibt das Feld auch nach dem Roundtrip leer.
    expect(zurueck.eintraege[1].mehr, isNull);
  });
  group('Formeln im echten Glossar', () {
    late Glossar glossar;
    late List<Frage> fragen;

    setUpAll(() async {
      final paket = await KursRepository().paketFuer(
        KursRepository.standardKursId,
      );
      glossar = paket.glossar;
      fragen = paket.fragen;
    });

    test('es gibt überhaupt Formeln', () {
      // Sonst prüfte alles Folgende still eine leere Menge.
      expect(
        glossar.eintraege.where((e) => e.formeln.isNotEmpty).length,
        greaterThanOrEqualTo(20),
      );
    });

    test('jede Formel ist eine Gleichung', () {
      for (final e in glossar.eintraege) {
        for (final f in e.formeln) {
          expect(f.trim(), isNotEmpty, reason: e.begriff);
          expect(f, contains('='), reason: '${e.begriff}: "$f"');
        }
      }
    });

    // Der Tipp erklärt, was gemeint ist - er gibt nicht die Antwort. Eine
    // Formel, in der die richtige Antwort wörtlich steht, täte genau das.
    test('keine Formel enthält die richtige Antwort einer Frage', () {
      String schluessel(String t) =>
          t.toLowerCase().replaceAll(RegExp(r'[^a-zä-ü0-9]'), '');

      final verdacht = <String>[];
      for (final frage in fragen) {
        final treffer = glossar.findeIn(
          frage.frage,
          ausnahmen: frage.tippsAus.toSet(),
        );
        final formeltext = schluessel(
          treffer.expand((e) => e.formeln).join(' '),
        );
        if (formeltext.isEmpty) continue;

        final antworten = <String>[
          for (final i in frage.richtigeIndizes)
            if (i >= 0 && i < frage.optionen.length) frage.optionen[i],
          ...frage.akzeptierteKurzantworten,
        ];
        for (final a in antworten) {
          final na = schluessel(a);
          if (na.length >= 6 && formeltext.contains(na)) {
            verdacht.add('${frage.id}: "$a"');
            break;
          }
        }
      }

      expect(
        verdacht,
        isEmpty,
        reason:
            'Der Tipp verrät hier die Antwort. Entweder die Formel anders '
            'fassen oder den Begriff per "tippsAus" ausblenden: '
            '${verdacht.join(" · ")}',
      );
    });

    // Der Punkt der ganzen Sache: Wer rechnen soll, bekommt die Formel.
    test('die mehrstufigen Aufgaben bekommen alle eine Formel', () {
      final ohne = [
        for (final f in fragen.where((f) => f.komplex))
          if (glossar
              .findeIn(f.frage, ausnahmen: f.tippsAus.toSet())
              .every((e) => e.formeln.isEmpty))
            f.id,
      ];

      expect(ohne, isEmpty, reason: 'Ohne Formel im Tipp: ${ohne.join(", ")}');
    });
  });

}
