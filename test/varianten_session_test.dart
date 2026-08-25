// Wo die Varianten in der Session entstehen - und wo ausdrücklich nicht.
//
// Die eine Regel, die sich nicht von selbst versteht: Im Testlauf steht der
// authentische Prüfungsbogen, überall sonst wird gewürfelt. Ginge das
// verloren, übte man im Testlauf eine Prüfung, die es nie gab.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/frage_varianten.dart';
import 'package:meine_app/models/kurs.dart';

import 'hilfen/test_kurs.dart';

const _aufgabe = Frage(
  id: 'sim-001',
  bereich: 'allgemein',
  kategorie: 'Zerspanung',
  typ: 'rechnung',
  frage: 'Ein Motor liefert P₁ = 5,5 kW bei η = 0,92. Berechne P₂.',
  optionen: [],
  richtigeIndizes: [],
  reihenfolge: [],
  paare: [],
  luecken: [],
  loesungswert: 5.06,
  einheit: 'kW',
  toleranz: 0.05,
  akzeptierteKurzantworten: [],
  erklaerung: 'P₂ = η · P₁.',
  schwierigkeit: 2,
  pruefung: 'S18',
  pruefungReihenfolge: 1,
  varianten: FrageVarianten(
    variablen: {
      'P1': VariablenQuelle(von: 1.5, bis: 22.0, schritt: 0.1),
      'eta': VariablenQuelle(werte: [0.8, 0.85, 0.9, 0.92, 0.95]),
    },
    original: {'P1': 5.5, 'eta': 0.92},
    frage: 'Ein Motor liefert P₁ = {P1} kW bei η = {eta}. Berechne P₂.',
    loesung: 'eta * P1',
    rundung: 2,
    toleranzProzent: 1.0,
  ),
);

ProviderContainer _container(int seed) => ProviderContainer(
  overrides: [
    fsrsCardStoreProvider.overrideWithValue(FakeFsrsCardStore()),
    attemptHistoryStoreProvider.overrideWithValue(FakeAttemptHistoryStore()),
    // Fester Seed statt Hoffnung darauf, dass zwei Ziehungen verschieden
    // ausfallen.
    variantenZufallProvider.overrideWithValue(() => Random(seed)),
    aktivesPaketProvider.overrideWith(
      (_) async => testPaket(
        [_aufgabe],
        kurs: testKurs(
          pruefungen: const [
            PruefungsDefinition(code: 'S18', titel: 'Sommer 2018'),
          ],
          features: const KursFeatures(pruefungssimulation: true),
        ),
      ),
    ),
  ],
);

Future<Frage> _ersteFrage(ProviderContainer container, QuizModus modus) async {
  final zustand = await container.read(quizSessionProvider(modus).future);
  return zustand.fragen.first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('freie Übung würfelt', () async {
    final a = _container(1);
    final b = _container(2);
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    final erste = await _ersteFrage(a, const QuizModus.freiUebung());
    final zweite = await _ersteFrage(b, const QuizModus.freiUebung());

    expect(erste.frage, isNot(zweite.frage));
    expect(erste.frage, isNot(contains('{')));
  });

  test('der Testlauf zeigt den Prüfungsbogen im Original', () async {
    final a = _container(1);
    final b = _container(2);
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    const modus = QuizModus.pruefungssimulation(
      pruefungsId: 'S18',
      zeitlimitMinuten: 90,
    );

    final erste = await _ersteFrage(a, modus);
    final zweite = await _ersteFrage(b, modus);

    expect(erste.frage, _aufgabe.frage);
    expect(zweite.frage, _aufgabe.frage);
    expect(erste.loesungswert, closeTo(5.06, 1e-9));
  });

  test('die Frage-ID bleibt gleich - der Lernfortschritt hängt daran', () async {
    final container = _container(5);
    addTearDown(container.dispose);

    final frage = await _ersteFrage(container, const QuizModus.freiUebung());

    expect(frage.id, _aufgabe.id);
  });
}
