// Import ist der Weg, auf dem fremde Daten in die App kommen - hier muss
// jede Fehlform zu einer verständlichen Meldung führen statt zu einem
// halbfertigen Kurs.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/kurse/paket_parser.dart';
import 'package:meine_app/models/kurs.dart';

Map<String, dynamic> _frage(
  String id, {
  String bereich = 'vokabeln',
  String kategorie = 'Begrüßung',
  String typ = 'single',
}) => {
  'id': id,
  'bereich': bereich,
  'kategorie': kategorie,
  'typ': typ,
  'frage': 'Testfrage $id',
  'optionen': ['A', 'B'],
  'richtigeIndizes': [0],
  'reihenfolge': [],
  'paare': [],
  'luecken': [],
  'akzeptierteKurzantworten': [],
  'erklaerung': 'Weil.',
  'schwierigkeit': 1,
};

Map<String, dynamic> _kurs({
  String id = 'spanisch-a1',
  List<Map<String, dynamic>>? bereiche,
  List<Map<String, dynamic>>? fragen,
  Map<String, dynamic>? extra,
}) => {
  'schemaVersion': 1,
  'id': id,
  'titel': 'Spanisch A1',
  'bereiche':
      bereiche ??
      [
        {'id': 'vokabeln', 'titel': 'Vokabeln'},
      ],
  'fragen': ?fragen,
  ...?extra,
};

void main() {
  final parser = PaketParser();

  group('JSON-Pakete', () {
    test('ein gültiges Minimalpaket wird eingelesen', () {
      final ergebnis = parser.ausJson(
        jsonEncode(_kurs(fragen: [_frage('v1'), _frage('v2')])),
      );

      expect(ergebnis.paket.kurs.id, 'spanisch-a1');
      expect(ergebnis.paket.kurs.quelle, KursQuelle.importiert);
      expect(ergebnis.paket.fragen, hasLength(2));
      expect(ergebnis.warnungen, isEmpty);
    });

    test(
      'Gewichte werden normalisiert, auch wenn sie nicht auf 1 summieren',
      () {
        final ergebnis = parser.ausJson(
          jsonEncode(
            _kurs(
              bereiche: [
                {'id': 'a', 'titel': 'A', 'gewicht': 3},
                {'id': 'b', 'titel': 'B', 'gewicht': 1},
              ],
              fragen: [_frage('v1', bereich: 'a')],
            ),
          ),
        );

        final gewichte = ergebnis.paket.kurs.normalisierteGewichte;
        expect(gewichte['a'], closeTo(0.75, 0.0001));
        expect(gewichte['b'], closeTo(0.25, 0.0001));
      },
    );

    test('ohne Gewichte zählen alle Bereiche gleich', () {
      final ergebnis = parser.ausJson(
        jsonEncode(
          _kurs(
            bereiche: [
              {'id': 'a', 'titel': 'A'},
              {'id': 'b', 'titel': 'B'},
              {'id': 'c', 'titel': 'C'},
            ],
            fragen: [_frage('v1', bereich: 'a')],
          ),
        ),
      );

      for (final wert in ergebnis.paket.kurs.normalisierteGewichte.values) {
        expect(wert, closeTo(1 / 3, 0.0001));
      }
    });

    test('Kategorien werden nach Bereich gruppiert', () {
      final ergebnis = parser.ausJson(
        jsonEncode(
          _kurs(
            bereiche: [
              {'id': 'a', 'titel': 'A'},
              {'id': 'b', 'titel': 'B'},
            ],
            fragen: [
              _frage('1', bereich: 'a', kategorie: 'Zwei'),
              _frage('2', bereich: 'a', kategorie: 'Eins'),
              _frage('3', bereich: 'b', kategorie: 'Drei'),
            ],
          ),
        ),
      );

      final gruppen = ergebnis.paket.kategorienProBereich;
      expect(gruppen.keys, ['a', 'b']);
      expect(gruppen['a'], ['Eins', 'Zwei']); // alphabetisch
      expect(gruppen['b'], ['Drei']);
    });
  });

  group('Abweisungen', () {
    void wirft(String beschreibung, Object paketJson, Matcher nachricht) {
      test(beschreibung, () {
        expect(
          () => parser.ausJson(
            paketJson is String ? paketJson : jsonEncode(paketJson),
          ),
          throwsA(
            isA<PaketFormatException>().having(
              (e) => e.nachricht,
              'nachricht',
              nachricht,
            ),
          ),
        );
      });
    }

    wirft('kein JSON', 'das ist kein json {{{', contains('kein gültiges JSON'));

    wirft('JSON-Array statt Objekt', '[1, 2, 3]', contains('kein JSON-Objekt'));

    wirft('fehlende schemaVersion', {
      'id': 'x',
      'titel': 'X',
      'bereiche': [],
      'fragen': [],
    }, contains('schemaVersion'));

    wirft('zu neue schemaVersion', {
      'schemaVersion': paketSchemaVersion + 1,
      'id': 'x',
      'titel': 'X',
      'bereiche': [
        {'id': 'a', 'titel': 'A'},
      ],
      'fragen': [_frage('1', bereich: 'a')],
    }, contains('App aktualisieren'));

    wirft('fehlende id', {
      'schemaVersion': 1,
      'titel': 'X',
      'bereiche': [
        {'id': 'a', 'titel': 'A'},
      ],
      'fragen': [_frage('1')],
    }, contains("'id'"));

    // Die Kurs-id wird als Hive-Schlüsselpräfix und als Ordnername benutzt -
    // Pfadtrenner darin wären ein echtes Problem.
    wirft(
      'Kurs-id mit Pfadtrennern',
      _kurs(id: '../../etc', fragen: [_frage('1')]),
      contains('unerlaubte Zeichen'),
    );

    wirft('keine Bereiche', {
      'schemaVersion': 1,
      'id': 'x',
      'titel': 'X',
      'bereiche': [],
      'fragen': [_frage('1')],
    }, contains('mindestens einen Bereich'));

    wirft(
      'doppelte Bereichs-id',
      _kurs(
        bereiche: [
          {'id': 'a', 'titel': 'A'},
          {'id': 'a', 'titel': 'Nochmal A'},
        ],
        fragen: [_frage('1', bereich: 'a')],
      ),
      contains('mehrfach'),
    );

    wirft('fehlende Fragen', _kurs(), contains("'fragen'"));

    wirft(
      'nur unbrauchbare Fragen',
      _kurs(
        fragen: [
          {'id': 'kaputt'},
        ],
      ),
      contains('Keine einzige Frage'),
    );
  });

  group('Toleranz gegenüber Teilschäden', () {
    test('eine kaputte Frage kippt nicht das ganze Paket', () {
      final ergebnis = parser.ausJson(
        jsonEncode(
          _kurs(
            fragen: [
              _frage('gut'),
              {'id': 'unvollstaendig'},
            ],
          ),
        ),
      );

      expect(ergebnis.paket.fragen, hasLength(1));
      expect(ergebnis.warnungen, isNotEmpty);
    });

    test('unbekannter Fragetyp wird übersprungen und gemeldet', () {
      final ergebnis = parser.ausJson(
        jsonEncode(
          _kurs(
            fragen: [
              _frage('gut'),
              _frage('seltsam', typ: 'hologramm'),
            ],
          ),
        ),
      );

      expect(ergebnis.paket.fragen.map((f) => f.id), ['gut']);
      expect(ergebnis.warnungen.any((w) => w.contains('hologramm')), isTrue);
    });

    test('doppelte Frage-id: nur die erste zählt', () {
      final ergebnis = parser.ausJson(
        jsonEncode(_kurs(fragen: [_frage('gleich'), _frage('gleich')])),
      );

      expect(ergebnis.paket.fragen, hasLength(1));
      expect(ergebnis.warnungen.any((w) => w.contains('mehrfach')), isTrue);
    });

    test('Frage mit unbekanntem Bereich wird gemeldet, aber behalten', () {
      final ergebnis = parser.ausJson(
        jsonEncode(_kurs(fragen: [_frage('x', bereich: 'gibt-es-nicht')])),
      );

      expect(ergebnis.paket.fragen, hasLength(1));
      expect(
        ergebnis.warnungen.any((w) => w.contains('gibt-es-nicht')),
        isTrue,
      );
    });

    test('aktiviertes Feature ohne Inhalt wird gemeldet', () {
      final ergebnis = parser.ausJson(
        jsonEncode(
          _kurs(
            fragen: [_frage('1')],
            extra: {
              'features': {'fachgespraech': true, 'pruefungssimulation': true},
            },
          ),
        ),
      );

      expect(ergebnis.warnungen, hasLength(greaterThanOrEqualTo(2)));
    });
  });

  group('ZIP-Pakete', () {
    Uint8List zipMit(Map<String, String> dateien) {
      final archiv = Archive();
      for (final e in dateien.entries) {
        final bytes = utf8.encode(e.value);
        archiv.addFile(ArchiveFile(e.key, bytes.length, bytes));
      }
      return Uint8List.fromList(ZipEncoder().encode(archiv));
    }

    test('kurs.json plus verteilte Fragendateien', () {
      final bytes = zipMit({
        'kurs.json': jsonEncode(
          _kurs(
            extra: {
              'fragenDateien': ['fragen/teil1.json', 'fragen/teil2.json'],
            },
          ),
        ),
        'fragen/teil1.json': jsonEncode([_frage('a')]),
        'fragen/teil2.json': jsonEncode([_frage('b')]),
      });

      final ergebnis = parser.ausZip(bytes);
      expect(ergebnis.paket.fragen.map((f) => f.id), ['a', 'b']);
    });

    test('Bilder werden mitgenommen, JSON-Dateien nicht', () {
      final bytes = zipMit({
        'kurs.json': jsonEncode(_kurs(fragen: [_frage('a')])),
        'bilder/skizze.png': 'so-tun-als-waere-das-ein-png',
      });

      final ergebnis = parser.ausZip(bytes);
      expect(ergebnis.paket.bilder.keys, ['bilder/skizze.png']);
    });

    // Wer einen Ordner zippt statt dessen Inhalt, bekommt sonst eine
    // unverständliche "kurs.json fehlt"-Meldung.
    test('ein umschließender Wurzelordner wird transparent entpackt', () {
      final bytes = zipMit({
        'mein-paket/kurs.json': jsonEncode(_kurs(fragen: [_frage('a')])),
      });

      final ergebnis = parser.ausZip(bytes);
      expect(ergebnis.paket.kurs.id, 'spanisch-a1');
    });

    test('fehlende kurs.json wird verständlich gemeldet', () {
      final bytes = zipMit({'irgendwas.json': '[]'});
      expect(
        () => parser.ausZip(bytes),
        throwsA(
          isA<PaketFormatException>().having(
            (e) => e.nachricht,
            'nachricht',
            contains('kurs.json'),
          ),
        ),
      );
    });

    test('eine fehlende Fragendatei wird gemeldet, blockiert aber nicht', () {
      final bytes = zipMit({
        'kurs.json': jsonEncode(
          _kurs(
            fragen: [_frage('inline')],
            extra: {
              'fragenDateien': ['fehlt.json'],
            },
          ),
        ),
      });

      final ergebnis = parser.ausZip(bytes);
      expect(ergebnis.paket.fragen, hasLength(1));
      expect(ergebnis.warnungen.any((w) => w.contains('fehlt.json')), isTrue);
    });

    test('kaputtes Archiv wird abgewiesen', () {
      expect(
        () => parser.ausZip(Uint8List.fromList([1, 2, 3, 4, 5])),
        throwsA(isA<PaketFormatException>()),
      );
    });
  });

  test('unbekannte Dateiendung wird abgewiesen', () {
    expect(
      () => parser.ausDatei('paket.txt', Uint8List.fromList(utf8.encode('{}'))),
      throwsA(
        isA<PaketFormatException>().having(
          (e) => e.nachricht,
          'nachricht',
          contains('.json'),
        ),
      ),
    );
  });
}
