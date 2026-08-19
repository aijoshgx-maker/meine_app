// Erkennung von Begriffen im Fragetext.
//
// Die Falle bei so einer Funktion ist nicht, zu wenig zu finden, sondern zu
// viel: Schlägt "Kraft" auch in "Kraftstoffpumpe" an, ist die Tippliste
// nach drei Fragen unbrauchbar und wird ignoriert.

import 'package:flutter_test/flutter_test.dart';
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
}
