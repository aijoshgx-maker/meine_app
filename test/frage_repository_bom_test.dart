// P1a/P12b: Eine Datei mit BOM (bzw. generell eine kaputte Themendatei)
// darf die übrigen Themen nicht mitreißen - frage_repository.dart fängt
// Ladefehler pro Datei ab statt die gesamte Liste abzubrechen.
//
// rootBundle wird über den 'flutter/assets'-Kanal gemockt, damit der Test
// unabhängig von den echten Projekt-Assets ist.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/frage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mitGemocktenAssets(
    Map<String, String> assets,
    Future<void> Function() run,
  ) async {
    // rootBundle cached Strings über Testgrenzen hinweg (dieselben Asset-
    // Keys wie '_manifest.json' werden in mehreren Tests wiederverwendet) -
    // ohne clear() würde ein Test den gemockten Inhalt eines vorherigen
    // Tests sehen statt seines eigenen.
    rootBundle.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          final inhalt = assets[key];
          if (inhalt == null) {
            throw Exception('Asset nicht gefunden (Mock): $key');
          }
          return ByteData.sublistView(Uint8List.fromList(utf8.encode(inhalt)));
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });
    await run();
  }

  const gueltigeFrage = '''
[
  {
    "id": "test-ok-001",
    "bereich": "test",
    "kategorie": "Test",
    "typ": "wahrfalsch",
    "frage": "Test?",
    "optionen": [],
    "richtigeIndizes": [],
    "reihenfolge": [],
    "paare": [],
    "luecken": [],
    "loesungswert": null,
    "einheit": null,
    "toleranz": null,
    "akzeptierteKurzantworten": [],
    "wahr": true,
    "erklaerung": "...",
    "selfExplanationPrompt": null,
    "bildAsset": null,
    "workedExample": null,
    "schwierigkeit": 1
  }
]
''';

  test(
    'eine kaputte Themendatei (kein valides JSON) reißt die übrigen Themen nicht mit',
    () async {
      await mitGemocktenAssets(
        {
          'assets/fragen/_manifest.json': jsonEncode([
            'gut.json',
            'kaputt.json',
          ]),
          'assets/fragen/gut.json': gueltigeFrage,
          'assets/fragen/kaputt.json': '{ das ist kein gueltiges JSON [[[',
        },
        () async {
          final fragen = await FrageRepository().laden();
          expect(fragen, hasLength(1));
          expect(fragen.first.id, 'test-ok-001');
        },
      );
    },
  );

  test('eine Datei mit UTF-8-BOM wird trotzdem korrekt geladen', () async {
    final mitBom = '﻿$gueltigeFrage';
    await mitGemocktenAssets(
      {
        'assets/fragen/_manifest.json': jsonEncode(['mit_bom.json']),
        'assets/fragen/mit_bom.json': mitBom,
      },
      () async {
        final fragen = await FrageRepository().laden();
        expect(fragen, hasLength(1));
        expect(fragen.first.id, 'test-ok-001');
      },
    );
  });

  test(
    'eine BOM-Datei UND eine kaputte Datei zusammen lassen die gute Datei trotzdem laden',
    () async {
      await mitGemocktenAssets(
        {
          'assets/fragen/_manifest.json': jsonEncode([
            'mit_bom.json',
            'kaputt.json',
            'gut.json',
          ]),
          'assets/fragen/mit_bom.json': '﻿$gueltigeFrage',
          'assets/fragen/kaputt.json': 'nicht mal json',
          'assets/fragen/gut.json': gueltigeFrage,
        },
        () async {
          final fragen = await FrageRepository().laden();
          // 2 gültige Dateien liefern je 1 Frage mit derselben id (Testdaten) -
          // FrageRepository dedupliziert IDs nicht (das macht der Validator),
          // hier zählt nur: keine Exception, kaputt.json wird übersprungen.
          expect(fragen, hasLength(2));
        },
      );
    },
  );
}
