// P12b: Bewertungslogik für jeden der acht Fragetypen, ohne Widget-Pumping
// (direkt über ProviderContainer + QuizSessionController-API). Insbesondere
// die rechnung-Toleranzgrenze inklusive Rand (siehe au-ih-013).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/app/settings_providers.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/models/frage.dart';

import 'hilfen/test_kurs.dart';

const _modus = QuizModus.freiUebung();

/// Baut einen ProviderContainer mit genau [frage] als einziger Frage im
/// Katalog und liefert Controller + State-Getter zurück, nachdem die
/// Session initial geladen wurde.
Future<(ProviderContainer, QuizSessionController)> _session(Frage frage) async {
  final container = ProviderContainer(
    overrides: [
      fsrsCardStoreProvider.overrideWithValue(FakeFsrsCardStore()),
      settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
      attemptHistoryStoreProvider.overrideWithValue(FakeAttemptHistoryStore()),
      aktivesPaketProvider.overrideWith((_) async => testPaket([frage])),
    ],
  );
  addTearDown(container.dispose);
  await container.read(quizSessionProvider(_modus).future);
  final controller = container.read(quizSessionProvider(_modus).notifier);
  return (container, controller);
}

bool? _korrekt(ProviderContainer container) =>
    container.read(quizSessionProvider(_modus)).value?.antwort.korrekt;

Frage _basis({
  required String typ,
  List<String> optionen = const [],
  List<int> richtigeIndizes = const [],
  List<int> reihenfolge = const [],
  List<Paar> paare = const [],
  List<List<String>> luecken = const [],
  double? loesungswert,
  String? einheit,
  double? toleranz,
  List<String> akzeptierteKurzantworten = const [],
  bool? wahr,
}) => Frage(
  id: 'test-$typ',
  bereich: 'allgemein',
  kategorie: 'Test',
  typ: typ,
  frage: 'Testfrage ($typ)',
  optionen: optionen,
  richtigeIndizes: richtigeIndizes,
  reihenfolge: reihenfolge,
  paare: paare,
  luecken: luecken,
  loesungswert: loesungswert,
  einheit: einheit,
  toleranz: toleranz,
  akzeptierteKurzantworten: akzeptierteKurzantworten,
  wahr: wahr,
  erklaerung: 'Erklärung.',
  schwierigkeit: 1,
);

void main() {
  // aufdecken() löst HapticFeedback aus, das das Flutter-Binding braucht -
  // auch in reinen (nicht-Widget-)Tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('single: richtige Auswahl -> korrekt, falsche -> inkorrekt', () async {
    final frage = _basis(
      typ: 'single',
      optionen: ['A', 'B', 'C'],
      richtigeIndizes: [1],
    );
    final (container, controller) = await _session(frage);
    controller.auswahlUmschalten(1);
    controller.aufdecken();
    expect(_korrekt(container), isTrue);
  });

  test('single: falsche Auswahl -> inkorrekt', () async {
    final frage = _basis(
      typ: 'single',
      optionen: ['A', 'B', 'C'],
      richtigeIndizes: [1],
    );
    final (container, controller) = await _session(frage);
    controller.auswahlUmschalten(0);
    controller.aufdecken();
    expect(_korrekt(container), isFalse);
  });

  test('multi: alle richtigen Indizes ausgewählt -> korrekt', () async {
    final frage = _basis(
      typ: 'multi',
      optionen: ['A', 'B', 'C', 'D'],
      richtigeIndizes: [0, 2],
    );
    final (container, controller) = await _session(frage);
    controller.auswahlUmschalten(0);
    controller.auswahlUmschalten(2);
    controller.aufdecken();
    expect(_korrekt(container), isTrue);
  });

  test('multi: nur teilweise ausgewählt -> inkorrekt', () async {
    final frage = _basis(
      typ: 'multi',
      optionen: ['A', 'B', 'C', 'D'],
      richtigeIndizes: [0, 2],
    );
    final (container, controller) = await _session(frage);
    controller.auswahlUmschalten(0);
    controller.aufdecken();
    expect(_korrekt(container), isFalse);
  });

  test('wahrfalsch: 1=Wahr passend zu wahr:true -> korrekt', () async {
    final frage = _basis(typ: 'wahrfalsch', wahr: true);
    final (container, controller) = await _session(frage);
    controller.auswahlUmschalten(1);
    controller.aufdecken();
    expect(_korrekt(container), isTrue);
  });

  test('wahrfalsch: 0=Falsch bei wahr:true -> inkorrekt', () async {
    final frage = _basis(typ: 'wahrfalsch', wahr: true);
    final (container, controller) = await _session(frage);
    controller.auswahlUmschalten(0);
    controller.aufdecken();
    expect(_korrekt(container), isFalse);
  });

  group('rechnung: Toleranzgrenze inklusive Rand (au-ih-013-Fall)', () {
    // loesungswert 196, toleranz 4 -> Fenster [192, 200] INKLUSIVE.
    final frage = _basis(
      typ: 'rechnung',
      loesungswert: 196,
      einheit: 'h',
      toleranz: 4,
    );

    test('exakter Wert -> korrekt', () async {
      final (container, controller) = await _session(frage);
      controller.freitextSetzen('196');
      controller.aufdecken();
      expect(_korrekt(container), isTrue);
    });

    test('oberer Rand (loesungswert + toleranz) -> korrekt', () async {
      final (container, controller) = await _session(frage);
      controller.freitextSetzen('200');
      controller.aufdecken();
      expect(_korrekt(container), isTrue);
    });

    test('unterer Rand (loesungswert - toleranz) -> korrekt', () async {
      final (container, controller) = await _session(frage);
      controller.freitextSetzen('192');
      controller.aufdecken();
      expect(_korrekt(container), isTrue);
    });

    test('knapp außerhalb -> inkorrekt', () async {
      final (container, controller) = await _session(frage);
      controller.freitextSetzen('200.1');
      controller.aufdecken();
      expect(_korrekt(container), isFalse);
    });

    test('Komma als Dezimaltrennzeichen wird akzeptiert', () async {
      final (container, controller) = await _session(frage);
      controller.freitextSetzen('196,0');
      controller.aufdecken();
      expect(_korrekt(container), isTrue);
    });
  });

  test(
    'kurzantwort: Umlaut-/Groß-Kleinschreibungs-Variante -> korrekt',
    () async {
      final frage = _basis(
        typ: 'kurzantwort',
        akzeptierteKurzantworten: ['Höchstmaß'],
      );
      final (container, controller) = await _session(frage);
      controller.freitextSetzen('HOECHSTMASS');
      controller.aufdecken();
      expect(_korrekt(container), isTrue);
    },
  );

  test('lueckentext: alle Lücken korrekt ausgefüllt -> korrekt', () async {
    final frage = _basis(
      typ: 'lueckentext',
      luecken: [
        ['Spanwinkel'],
        ['Freiwinkel'],
      ],
    );
    final (container, controller) = await _session(frage);
    controller.lueckeSetzen(0, 'spanwinkel');
    controller.lueckeSetzen(1, 'Freiwinkel');
    controller.aufdecken();
    expect(_korrekt(container), isTrue);
  });

  test('lueckentext: eine Lücke falsch -> inkorrekt', () async {
    final frage = _basis(
      typ: 'lueckentext',
      luecken: [
        ['Spanwinkel'],
        ['Freiwinkel'],
      ],
    );
    final (container, controller) = await _session(frage);
    controller.lueckeSetzen(0, 'Spanwinkel');
    controller.lueckeSetzen(1, 'Keilwinkel');
    controller.aufdecken();
    expect(_korrekt(container), isFalse);
  });

  test(
    'zuordnung: korrekte Zuordnung über Original-Indizes -> korrekt',
    () async {
      final frage = _basis(
        typ: 'zuordnung',
        paare: const [
          Paar(links: 'Festlager', rechts: 'axial fixiert'),
          Paar(links: 'Loslager', rechts: 'axial verschiebbar'),
        ],
      );
      final (container, controller) = await _session(frage);
      controller.zuordnungAuswaehlen(0, 0);
      controller.zuordnungAuswaehlen(1, 1);
      controller.aufdecken();
      expect(_korrekt(container), isTrue);
    },
  );

  test('zuordnung: vertauschte Zuordnung -> inkorrekt', () async {
    final frage = _basis(
      typ: 'zuordnung',
      paare: const [
        Paar(links: 'Festlager', rechts: 'axial fixiert'),
        Paar(links: 'Loslager', rechts: 'axial verschiebbar'),
      ],
    );
    final (container, controller) = await _session(frage);
    controller.zuordnungAuswaehlen(0, 1);
    controller.zuordnungAuswaehlen(1, 0);
    controller.aufdecken();
    expect(_korrekt(container), isFalse);
  });

  // Mehrere Paare duerfen auf denselben Wert zeigen (wi-av-005: fuenf
  // Pflichten, zwei Vertragsparteien). Gezaehlt wird der Text, nicht der
  // Index - sonst waere eine inhaltlich richtige Zuordnung falsch, nur weil
  // man den Eintrag aus der falschen Zeile angetippt hat.
  test('zuordnung: textgleiche Wahl ueber einen anderen Index -> korrekt', () async {
    final frage = _basis(
      typ: 'zuordnung',
      paare: const [
        Paar(links: 'Arbeitspflicht', rechts: 'Arbeitnehmer'),
        Paar(links: 'Verguetungspflicht', rechts: 'Arbeitgeber'),
        Paar(links: 'Treuepflicht', rechts: 'Arbeitnehmer'),
      ],
    );
    final (container, controller) = await _session(frage);
    // Zeile 0 nimmt "Arbeitnehmer" aus Paar 2 statt aus Paar 0.
    controller.zuordnungAuswaehlen(0, 2);
    controller.zuordnungAuswaehlen(1, 1);
    controller.zuordnungAuswaehlen(2, 0);
    controller.aufdecken();
    expect(_korrekt(container), isTrue);
  });

  test('reihenfolge: korrekte Sortierung -> korrekt', () async {
    final frage = _basis(
      typ: 'reihenfolge',
      optionen: ['Vorbohren', 'Bohren', 'Reiben'],
      reihenfolge: [0, 1, 2],
    );
    final (container, controller) = await _session(frage);
    controller.reihenfolgeAktualisieren([0, 1, 2]);
    controller.aufdecken();
    expect(_korrekt(container), isTrue);
  });

  test('reihenfolge: falsche Sortierung -> inkorrekt', () async {
    final frage = _basis(
      typ: 'reihenfolge',
      optionen: ['Vorbohren', 'Bohren', 'Reiben'],
      reihenfolge: [0, 1, 2],
    );
    final (container, controller) = await _session(frage);
    controller.reihenfolgeAktualisieren([2, 1, 0]);
    controller.aufdecken();
    expect(_korrekt(container), isFalse);
  });
}
