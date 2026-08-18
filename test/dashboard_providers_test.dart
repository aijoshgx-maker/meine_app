import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/features/dashboard/providers/dashboard_providers.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';

import 'hilfen/test_kurs.dart';

void main() {
  Attempt versuch({
    required String kategorie,
    required Konfidenz konfidenz,
    required bool korrekt,
    DateTime? zeitpunkt,
    String kursId = testKursId,
  }) => Attempt(
    kursId: kursId,
    frageId: 'x',
    zeitpunkt: zeitpunkt ?? DateTime.now(),
    konfidenz: konfidenz,
    korrekt: korrekt,
    bereich: 'allgemein',
    kategorie: kategorie,
  );

  /// Container mit genau [versuche] im Verlauf und einem Testkurs als
  /// aktivem Kurs.
  ProviderContainer container(List<Attempt> versuche) {
    final verlauf = FakeAttemptHistoryStore()..eintraege.addAll(versuche);
    final c = ProviderContainer(
      overrides: [
        attemptHistoryStoreProvider.overrideWithValue(verlauf),
        aktivesPaketProvider.overrideWith((_) async => testPaket(const [])),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('kalibrierungProvider berechnet Trefferquote je Konfidenz', () async {
    final c = container([
      versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: true),
      versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: true),
      versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: false),
      versuch(kategorie: 'a', konfidenz: Konfidenz.geraten, korrekt: false),
    ]);

    final ergebnis = await c.read(kalibrierungProvider.future);

    expect(ergebnis[Konfidenz.sicher], closeTo(2 / 3, 0.001));
    expect(ergebnis[Konfidenz.geraten], 0.0);
    expect(ergebnis[Konfidenz.unsicher], 0.0);
  });

  test('hochkonfidentFalschAnzahlProvider zählt nur sicher+falsch', () async {
    final c = container([
      versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: false),
      versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: true),
      versuch(kategorie: 'a', konfidenz: Konfidenz.geraten, korrekt: false),
    ]);

    expect(await c.read(hochkonfidentFalschAnzahlProvider.future), 1);
  });

  // Kernzusage der Mehrkurs-Fähigkeit: Auswertungen dürfen sich nicht über
  // Kurse hinweg vermischen.
  test('Auswertungen zählen nur Versuche des aktiven Kurses', () async {
    final c = container([
      versuch(kategorie: 'a', konfidenz: Konfidenz.sicher, korrekt: false),
      versuch(
        kategorie: 'a',
        konfidenz: Konfidenz.sicher,
        korrekt: false,
        kursId: 'ein-anderer-kurs',
      ),
    ]);

    expect(await c.read(hochkonfidentFalschAnzahlProvider.future), 1);
  });

  test('schwacheThemenProvider sortiert nach Fehlerquote absteigend', () async {
    final c = container([
      versuch(kategorie: 'gut', konfidenz: Konfidenz.sicher, korrekt: true),
      versuch(kategorie: 'gut', konfidenz: Konfidenz.sicher, korrekt: true),
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
    ]);

    final ergebnis = await c.read(schwacheThemenProvider.future);

    expect(ergebnis.first.kategorie, 'schlecht');
    expect(ergebnis.first.fehlerquote, closeTo(0.5, 0.001));
    expect(ergebnis.last.kategorie, 'gut');
    expect(ergebnis.last.fehlerquote, 0.0);
  });

  test(
    'behaltensquoteVerlaufProvider liefert 30 Tage, heute mit korrekter Quote',
    () async {
      final heute = DateTime.now();
      final c = container([
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
      ]);

      final verlauf = await c.read(behaltensquoteVerlaufProvider.future);

      expect(verlauf, hasLength(30));
      expect(verlauf.last.quote, closeTo(0.5, 0.001));
    },
  );
}
