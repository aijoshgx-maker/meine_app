// Die variierenden Aufgaben gegen den echten Bestand.
//
// Der Validator prüft dasselbe beim Autorenlauf; dieser Test hängt es an die
// Testsuite, damit eine kaputte Aufgabe auch dann auffällt, wenn jemand den
// Validator vergisst. Was hier grün ist, kann in der App keine unlösbare
// Aufgabe erzeugen.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/quiz/frage_variante.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Frage> variabel;

  setUpAll(() async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );
    variabel = paket.fragen.where((f) => f.varianten != null).toList();
  });

  test('es gibt überhaupt variierende Aufgaben', () {
    // Sonst prüfte alles Folgende still eine leere Liste.
    expect(variabel, isNotEmpty);
  });

  test('mit den Originalwerten steht jede Aufgabe wie gespeichert da', () {
    final fehler = <String>[];

    for (final frage in variabel) {
      final original = wuerfleVariante(frage, Random(0), originalwerte: true);

      if (frage.varianten!.frage != null && original.frage != frage.frage) {
        fehler.add('${frage.id}: Fragetext weicht ab\n  ${original.frage}');
      }
      if (frage.varianten!.loesung != null && frage.loesungswert != null) {
        final abweichung =
            (original.loesungswert! - frage.loesungswert!).abs();
        // Auf die Stellenzahl der Aufgabe gerundet muss exakt der Wert
        // herauskommen, der seit jeher hinterlegt ist.
        final spielraum = 0.5 / pow(10, frage.varianten!.rundung);
        if (abweichung > spielraum) {
          fehler.add(
            '${frage.id}: Formel ergibt ${original.loesungswert}, '
            'gespeichert ist ${frage.loesungswert}',
          );
        }
      }
    }

    expect(fehler, isEmpty, reason: fehler.join('\n'));
  });

  test('keine Ziehung erzeugt eine unlösbare Aufgabe', () {
    final fehler = <String>[];
    // Fester Seed: Ein Fehler, der nur jede zwanzigste Ziehung trifft, wäre
    // sonst nicht zu reproduzieren.
    final zufall = Random(20260825);

    for (final frage in variabel) {
      final original = wuerfleVariante(frage, Random(0), originalwerte: true);
      final originalPositiv = (original.loesungswert ?? 1) > 0;

      for (var i = 0; i < 100; i++) {
        final Frage gezogen;
        try {
          gezogen = wuerfleVariante(frage, zufall);
        } catch (e) {
          fehler.add('${frage.id}: Ziehung $i schlägt fehl - $e');
          break;
        }

        if (gezogen.frage.contains('{')) {
          fehler.add('${frage.id}: Platzhalter bleibt stehen - ${gezogen.frage}');
          break;
        }
        if (gezogen.workedExample?.contains('{') ?? false) {
          fehler.add('${frage.id}: Platzhalter im Lösungsweg');
          break;
        }
        if (gezogen.erklaerung.contains('{')) {
          fehler.add('${frage.id}: Platzhalter in der Erklärung');
          break;
        }

        if (frage.varianten!.loesung == null) continue;

        final wert = gezogen.loesungswert;
        if (wert == null || !wert.isFinite) {
          fehler.add('${frage.id}: Ziehung $i ohne Zahlenwert');
          break;
        }
        if (originalPositiv && wert <= 0) {
          fehler.add('${frage.id}: Ziehung $i ergibt $wert - Original war positiv');
          break;
        }
        // Die Toleranz muss die eigene Rundung überdecken, sonst ist der
        // angezeigte Lösungsweg nicht als Antwort zugelassen.
        final rundungsSpielraum = 0.5 / pow(10, frage.varianten!.rundung);
        if ((gezogen.toleranz ?? 0) < rundungsSpielraum) {
          fehler.add('${frage.id}: Toleranz ${gezogen.toleranz} deckt die Rundung nicht');
          break;
        }
      }
    }

    expect(fehler, isEmpty, reason: fehler.join('\n'));
  });

  test('jede variierende Aufgabe variiert auch wirklich', () {
    final unbeweglich = <String>[];

    for (final frage in variabel) {
      final texte = {
        for (var i = 0; i < 40; i++) wuerfleVariante(frage, Random(i)).frage,
      };
      if (texte.length < 5) unbeweglich.add('${frage.id} (${texte.length})');
    }

    expect(
      unbeweglich,
      isEmpty,
      reason:
          'Zu enge Wertebereiche - die Aufgabe sieht praktisch immer gleich '
          'aus:\n${unbeweglich.join('\n')}',
    );
  });

  // Zeichnungsgebundene Aufgaben lesen ihre Zahlen aus dem Bild ab. Würden
  // sie variieren, stünde im Text eine andere Zahl als in der Zeichnung.
  test('keine Aufgabe mit Zeichnungsbezug variiert', () {
    for (final frage in variabel) {
      expect(
        frage.bildAsset,
        isNull,
        reason: '${frage.id} hat ein Bild und darf nicht variieren',
      );
    }
  });
}
