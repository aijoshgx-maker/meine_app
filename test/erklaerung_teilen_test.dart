// Aufteilung der Erklärung in Kurzfassung und Rest.
//
// Die Funktion entscheidet, was direkt nach dem Aufdecken zu sehen ist -
// eine schlechte Trennung fällt sofort auf, etwa wenn mitten im Wort
// abgebrochen oder an einer Abkürzung getrennt wird.

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/quiz/erklaerung_teilen.dart';

void main() {
  test('kurze Erklärungen bleiben ungeteilt', () {
    const text = 'vc = π · d · n / 1000 = 100,5 m/min.';
    final geteilt = teileErklaerung(text);

    expect(geteilt.kurz, text);
    expect(geteilt.rest, isEmpty);
    expect(geteilt.hatMehr, isFalse);
  });

  test('leerer Text ergibt nichts zum Aufklappen', () {
    final geteilt = teileErklaerung('   ');
    expect(geteilt.kurz, isEmpty);
    expect(geteilt.hatMehr, isFalse);
  });

  test('lange Erklärungen werden an der Satzgrenze getrennt', () {
    const text =
        'Lauftoleranzen umfassen Rundlauf, Planlauf, Gesamtrundlauf und '
        'Gesamtplanlauf. Neigung dagegen ist eine Richtungstoleranz und '
        'gehört damit zu den Lagetoleranzen, nicht zu den Lauftoleranzen.';

    final geteilt = teileErklaerung(text);

    expect(geteilt.hatMehr, isTrue);
    expect(geteilt.kurz, endsWith('.'));
    expect(geteilt.kurz, startsWith('Lauftoleranzen umfassen'));
    expect(geteilt.rest, startsWith('Neigung dagegen'));
    // Zusammen wieder der ganze Text - es darf nichts verschwinden.
    expect('${geteilt.kurz} ${geteilt.rest}', text);
  });

  // Ohne diese Prüfung würde "z.B." als Satzende gelten und die Kurzfassung
  // mitten im Satz abbrechen.
  test('Abkürzungen beenden den Satz nicht', () {
    const text =
        'Das Oberflächenzeichen enthält den Rauheitskennwert, z.B. Ra 1,6, '
        'sowie das Fertigungsverfahren und die Rillenrichtung. Die '
        'Werkstoffhärte gehört nicht dazu, sie steht in der '
        'Wärmebehandlungsvorschrift.';

    final geteilt = teileErklaerung(text);

    expect(geteilt.kurz, contains('z.B. Ra 1,6'));
    expect(geteilt.kurz, endsWith('Rillenrichtung.'));
  });

  test('Dezimalzahlen werden nicht als Satzende gelesen', () {
    const text =
        'Der Kolbendurchmesser beträgt 80.5 mm und der Druck liegt bei 6 bar, '
        'woraus sich die Kolbenkraft ergibt. Bei größeren Durchmessern steigt '
        'die Kraft quadratisch, weshalb die Auslegung sorgfältig erfolgen '
        'muss.';

    final geteilt = teileErklaerung(text);

    expect(geteilt.kurz, contains('80.5 mm'));
    expect(geteilt.hatMehr, isTrue);
  });

  test('Text ohne Satzzeichen wird am Wort getrennt und markiert', () {
    final text = 'Wort ' * 60;
    final geteilt = teileErklaerung(text);

    expect(geteilt.hatMehr, isTrue);
    expect(geteilt.kurz, endsWith('…'));
    // Nicht mitten im Wort abgeschnitten.
    expect(geteilt.kurz.replaceAll('…', '').trim(), endsWith('Wort'));
    // Der Rest trägt den vollständigen Text, damit nichts verloren geht.
    expect(geteilt.rest, text.trim());
  });

  group('kurzerklaerung hat Vorrang', () {
    test(
      'gesetzt: bildet die Kurzfassung, voller Text wandert nach hinten',
      () {
        const kurz = 'Neigung ist eine Lagetoleranz.';
        const voll =
            'Lauftoleranzen sind Rundlauf, Planlauf, Gesamtrundlauf und '
            'Gesamtplanlauf. Neigung gehört zu den Richtungstoleranzen.';

        final geteilt = teileErklaerung(voll, kurzerklaerung: kurz);

        expect(geteilt.kurz, kurz);
        expect(geteilt.rest, voll);
        expect(geteilt.hatMehr, isTrue);
      },
    );

    test('leer oder null: die Ableitung greift', () {
      const voll = 'Ein kurzer Satz.';
      expect(teileErklaerung(voll, kurzerklaerung: '  ').kurz, voll);
      expect(teileErklaerung(voll, kurzerklaerung: null).kurz, voll);
    });

    test('identisch zur Erklärung: kein Aufklapper', () {
      const text = 'Kurz und vollständig.';
      final geteilt = teileErklaerung(text, kurzerklaerung: text);

      expect(geteilt.hatMehr, isFalse);
    });
  });

  // Eine Untergrenze gibt es bewusst nicht: Endet der erste Satz früh, ist
  // das eine gute Kurzfassung. Nach oben muss sie aber gedeckelt bleiben,
  // sonst hat das Aufklappen keinen Zweck.
  test('die Kurzfassung überschreitet die Obergrenze nicht', () {
    const text =
        'Die Schnittgeschwindigkeit ist die Relativgeschwindigkeit zwischen '
        'Schneide und Werkstück. Sie wird in m/min angegeben und hängt vom '
        'Werkstoff sowie vom Schneidstoff ab. Zu hohe Werte führen zu '
        'vorzeitigem Verschleiß.';

    final geteilt = teileErklaerung(text);

    expect(geteilt.kurz.length, lessThanOrEqualTo(185));
    expect(geteilt.kurz, endsWith('.'));
  });

  test('ein sehr kurzer erster Satz wird trotzdem genommen', () {
    const text =
        'Nein. Der Grund liegt darin, dass die Zustellung bei diesem '
        'Verfahren senkrecht zur Vorschubrichtung wirkt und die Schnittkraft '
        'dadurch anders verteilt wird als beim Längsdrehen und sich damit '
        'auch die Standzeit des Werkzeugs verändert. Deshalb müssen die '
        'Schnittwerte gesondert bestimmt werden.';

    final geteilt = teileErklaerung(text);

    // Der zweite Satz würde die Obergrenze sprengen - dann ist "Nein."
    // allein die bessere Kurzfassung als ein Schnitt mittendrin.
    expect(geteilt.kurz, 'Nein.');
    expect(geteilt.rest, startsWith('Der Grund'));
  });
}
