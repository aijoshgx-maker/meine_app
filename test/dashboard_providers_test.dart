import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/features/dashboard/providers/dashboard_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';

class _FakeAttemptHistoryStore implements AttemptHistoryStore {
  final List<Attempt> _eintraege;
  _FakeAttemptHistoryStore(this._eintraege);

  @override
  Future<void> anhaengen(Attempt attempt) async => _eintraege.add(attempt);

  @override
  List<Attempt> alle() => List.of(_eintraege);
}

void main() {
  Attempt versuch({
    required String kategorie,
    required Konfidenz konfidenz,
    required bool korrekt,
    DateTime? zeitpunkt,
  }) => Attempt(
    frageId: 'x',
    zeitpunkt: zeitpunkt ?? DateTime.now(),
    konfidenz: konfidenz,
    korrekt: korrekt,
    bereich: 'fertigungstechnik',
    kategorie: kategorie,
  );

  test('kalibrierungProvider berechnet Trefferquote je Konfidenz', () {
    final container = ProviderContainer(
      overrides: [
        attemptHistoryStoreProvider.overrideWithValue(
          _FakeAttemptHistoryStore([
            versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: true),
            versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: true),
            versuch(
              kategorie: 'a',
              konfidenz: Konfidenz.sicher,
              korrekt: false,
            ),
            versuch(
              kategorie: 'a',
              konfidenz: Konfidenz.geraten,
              korrekt: false,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final ergebnis = container.read(kalibrierungProvider);

    expect(ergebnis[Konfidenz.sicher], closeTo(2 / 3, 0.001));
    expect(ergebnis[Konfidenz.geraten], 0.0);
    expect(ergebnis[Konfidenz.unsicher], 0.0);
  });

  test('hochkonfidentFalschAnzahlProvider zählt nur sicher+falsch', () {
    final container = ProviderContainer(
      overrides: [
        attemptHistoryStoreProvider.overrideWithValue(
          _FakeAttemptHistoryStore([
            versuch(
              kategorie: 'a',
              konfidenz: Konfidenz.sicher,
              korrekt: false,
            ),
            versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: true),
            versuch(
              kategorie: 'a',
              konfidenz: Konfidenz.geraten,
              korrekt: false,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(hochkonfidentFalschAnzahlProvider), 1);
  });

  test('schwacheThemenProvider sortiert nach Fehlerquote absteigend', () {
    final container = ProviderContainer(
      overrides: [
        attemptHistoryStoreProvider.overrideWithValue(
          _FakeAttemptHistoryStore([
            versuch(
              kategorie: 'gut',
              konfidenz: Konfidenz.sicher,
              korrekt: true,
            ),
            versuch(
              kategorie: 'gut',
              konfidenz: Konfidenz.sicher,
              korrekt: true,
            ),
            versuch(
              kategorie: 'schlecht',
              konfidenz: Konfidenz.geraten,
              korrekt: false,
            ),
            versuch(
              kategorie: 'schlecht',
              konfidenz: Konfidenz.geraten,
              korrekt: true,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final ergebnis = container.read(schwacheThemenProvider);

    expect(ergebnis.first.kategorie, 'schlecht');
    expect(ergebnis.first.fehlerquote, closeTo(0.5, 0.001));
    expect(ergebnis.last.kategorie, 'gut');
    expect(ergebnis.last.fehlerquote, 0.0);
  });

  test(
    'behaltensquoteVerlaufProvider liefert 30 Tage, heute mit korrekter Quote',
    () {
      final heute = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          attemptHistoryStoreProvider.overrideWithValue(
            _FakeAttemptHistoryStore([
              versuch(
                kategorie: 'a',
                konfidenz: Konfidenz.sicher,
                korrekt: true,
                zeitpunkt: heute,
              ),
              versuch(
                kategorie: 'a',
                konfidenz: Konfidenz.sicher,
                korrekt: false,
                zeitpunkt: heute,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final verlauf = container.read(behaltensquoteVerlaufProvider);

      expect(verlauf, hasLength(30));
      expect(verlauf.last.quote, closeTo(0.5, 0.001));
    },
  );
}
