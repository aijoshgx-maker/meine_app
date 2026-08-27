// Die Fragen gegen den Bestand: kein Bezug auf einen konkreten Prüfungssatz.
//
// Die Fragen waren immer in eigenen Worten formuliert. Was sie mit den
// Prüfungssätzen verband, war die Konstruktion — Einstellantrieb,
// Werkzeugspindelkasten, Verladeanlage, Schaltvorrichtung, Bohrstation,
// Verzinkungsanlage — mit Positionsnummern und Bauteilkennzeichen aus genau
// diesen Blättern. Im August 2026 sind diese Bezüge herausgenommen worden.
//
// Der Test hält das fest. Ohne ihn schliche sich der Bezug mit der nächsten
// Frage wieder ein, und niemand würde es merken.
//
// Ausgenommen sind die Fragen mit `bildAsset`: Sie gehören zu einer
// Zeichnung und bleiben vorerst zusammen mit ihr bestehen. Gehen die
// Zeichnungen, müssen auch sie gelöst werden — dann fällt die Ausnahme hier
// weg und der Test zeigt, welche Fragen noch offen sind.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';

/// Namen und Kennzeichen aus den Prüfungssätzen.
///
/// Bewusst eng gefasst: Fachwörter wie „Schaltplan" oder „Stückliste" stehen
/// nicht darin, sie sind allgemeine Begriffe. Getroffen werden soll, was nur
/// im Zusammenhang mit einem bestimmten Prüfungsbogen Sinn ergibt.
final _pruefungsbezug = RegExp(
  r'Pos\.\s*\d'
  r'|\(S1[789]\)|\(W22\)'
  r'|Einstellantrieb|Werkzeugspindelkasten|Verladeanlage'
  r'|Schaltvorrichtung|Bohrstation|Verzinkungsanlage'
  r'|Coil-Haspel|Materialkorb|Richtzylinder|ECA 16'
  r'|IHK-Schaltplan'
  // Bauteil- und Sensorkennzeichen: -RM1, QN1, BP2, BG7, BT1 …
  r'|-[A-Z]{2}\d'
  r'|\b[BQGHMP][A-Z]\d\b',
);

/// Alles, was ein Lernender an einer Frage zu lesen bekommt.
String _volltext(Frage f) => [
  f.frage,
  ...f.optionen,
  f.erklaerung,
  f.kurzerklaerung ?? '',
  f.workedExample ?? '',
  ...f.paare.map((p) => '${p.links} ${p.rechts}'),
  ...f.luecken.expand((l) => l),
  ...f.akzeptierteKurzantworten,
  ...f.freieAntwort,
  f.varianten?.frage ?? '',
  f.varianten?.erklaerung ?? '',
].join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Frage> alle;

  setUpAll(() async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );
    alle = paket.fragen;
  });

  test('der Bestand ist überhaupt geladen', () {
    // Sonst prüfte alles Folgende still eine leere Liste.
    expect(alle.length, greaterThan(600));
  });

  test('keine Frage ohne Zeichnung nennt einen Prüfungssatz', () {
    final treffer = <String>[];
    for (final frage in alle) {
      if (frage.bildAsset != null) continue;
      final gefunden = _pruefungsbezug.firstMatch(_volltext(frage));
      if (gefunden != null) {
        treffer.add('${frage.id}: "${gefunden.group(0)}"');
      }
    }

    expect(
      treffer,
      isEmpty,
      reason:
          'Diese Fragen nennen noch einen konkreten Prüfungssatz. Die '
          'Konstruktion neutral beschreiben (siehe '
          'tool/pruefungsbezug_loesen.py):\n${treffer.join('\n')}',
    );
  });

  // Die Ausnahme soll nicht stillschweigend wachsen: Wer eine neue Frage mit
  // Prüfungsbezug anlegt, müsste ihr dafür erst ein bildAsset geben - und
  // spätestens diese Zahl fällt dann auf.
  test('die Ausnahme umfasst genau die bekannten Zeichnungsfragen', () {
    final mitBezug = alle
        .where((f) => f.bildAsset != null)
        .where((f) => _pruefungsbezug.hasMatch(_volltext(f)))
        .toList();

    expect(
      mitBezug,
      hasLength(27),
      reason:
          'Erwartet werden die 27 Fragen, die zu einer Prüfungszeichnung '
          'gehören. Weniger heißt: eine ist gelöst worden, dann diese Zahl '
          'senken. Mehr heißt: eine neue Frage bringt einen Prüfungsbezug '
          'mit.',
    );
  });
}
