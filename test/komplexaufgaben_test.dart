// Die mehrstufigen Rechenaufgaben gegen den echten Bestand.
//
// Sie sind der einzige Fragentyp, bei dem eine falsche Formel nicht auffällt,
// solange man das Ergebnis nicht nachrechnet: Ein plausibler Zahlenwert steht
// auch dann da, wenn ein Schritt fehlt. Deshalb hier ein Gurt, der jede
// Aufgabe mit ihren Originalwerten durchrechnet und mit dem gespeicherten
// Ergebnis vergleicht.
//
// Der Varianten-Validator prüft dasselbe beim Autorenlauf; dieser Test hängt
// es an die Testsuite, damit eine kaputte Aufgabe auch dann auffällt, wenn
// jemand den Validator vergisst.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/quiz/frage_variante.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Frage> komplex;

  setUpAll(() async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );
    komplex = paket.fragen.where((f) => f.komplex).toList();
  });

  test('es gibt überhaupt Komplexaufgaben', () {
    // Sonst prüfte alles Folgende still eine leere Liste. Eine pro Tag heißt
    // auch: Unter zwei Wochen Vorrat wiederholt sich das zu schnell.
    expect(komplex.length, greaterThanOrEqualTo(14));
  });

  test('jede ist eine variierende Rechenaufgabe mit Lösungsweg', () {
    for (final f in komplex) {
      expect(f.typ, 'rechnung', reason: f.id);
      expect(f.varianten, isNotNull, reason: f.id);
      expect(f.loesungswert, isNotNull, reason: f.id);
      expect(f.workedExample, isNotNull, reason: f.id);
      expect(f.workedExample!.trim(), isNotEmpty, reason: f.id);
    }
  });

  // Der Kern: Mit den Originalwerten muss genau der gespeicherte Text und
  // genau der gespeicherte Wert herauskommen.
  test('mit den Originalwerten steht jede Aufgabe wie gespeichert da', () {
    for (final f in komplex) {
      final gebaut = baueVariante(f, f.varianten!.original);

      expect(gebaut.frage, f.frage, reason: f.id);
      expect(gebaut.loesungswert, closeTo(f.loesungswert!, 1e-9), reason: f.id);
      expect(gebaut.erklaerung, f.erklaerung, reason: f.id);
      expect(gebaut.workedExample, f.workedExample, reason: f.id);
    }
  });

  // Eine Aufgabe ist erst mehrstufig, wenn zwischen Angabe und Ergebnis
  // etwas liegt, das die Aufgabe nicht nennt. Weniger als zwei
  // Zwischenschritte heißt: eine Formel einsetzen, und das kann der Bestand
  // schon.
  test('jede hat mindestens zwei Zwischenschritte', () {
    for (final f in komplex) {
      expect(
        f.varianten!.zwischen.length,
        greaterThanOrEqualTo(2),
        reason: '${f.id} hat nur ${f.varianten!.zwischen.length}',
      );
    }
  });

  test('der Lösungsweg nennt die Schritte einzeln', () {
    for (final f in komplex) {
      final zeilen = f.workedExample!.split('\n');
      expect(
        zeilen.where((z) => z.startsWith('Schritt ')).length,
        greaterThanOrEqualTo(3),
        reason: '${f.id}: zu wenige benannte Schritte',
      );
    }
  });

  // 200 Ziehungen je Aufgabe: Was bei den Originalwerten aufgeht, kann bei
  // einer ungünstigen Kombination trotzdem Unsinn ergeben - eine negative
  // Fläche, eine Division durch null, eine Sicherheit unter 1.
  test('keine Ziehung erzeugt ein unbrauchbares Ergebnis', () {
    final zufall = Random(20260827);
    for (final f in komplex) {
      for (var i = 0; i < 200; i++) {
        final gezogen = wuerfleVariante(f, zufall);
        final wert = gezogen.loesungswert;

        expect(wert, isNotNull, reason: f.id);
        expect(wert!.isFinite, isTrue, reason: '${f.id}: $wert');
        expect(
          wert,
          greaterThan(0),
          reason: '${f.id}: $wert bei "${gezogen.frage}"',
        );
        expect(gezogen.toleranz, greaterThan(0), reason: f.id);
        // Ein Platzhalter, der stehen bleibt, wäre im Fragetext sichtbar.
        expect(gezogen.frage, isNot(contains('{')), reason: f.id);
        expect(gezogen.workedExample, isNot(contains('{')), reason: f.id);
      }
    }
  });

  test('sie verteilen sich über mehrere Themen', () {
    // Eine Aufgabe pro Tag aus immer derselben Ecke wäre kein Querschnitt.
    final kategorien = komplex.map((f) => f.kategorie).toSet();
    expect(kategorien.length, greaterThanOrEqualTo(8));

    final bereiche = komplex.map((f) => f.bereich).toSet();
    expect(bereiche.length, greaterThanOrEqualTo(2));
  });
}
