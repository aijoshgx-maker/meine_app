import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/kurs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Der gebündelte Kurs ist vorhanden und vollständig beschrieben',
    () async {
      final kurse = await KursRepository().alleKurse();

      expect(kurse, isNotEmpty);
      final ap2 = kurse.firstWhere(
        (k) => k.id == KursRepository.standardKursId,
      );

      expect(ap2.quelle, KursQuelle.gebuendelt);
      expect(ap2.bereiche, hasLength(3));
      expect(ap2.pruefungen, hasLength(4));
      expect(ap2.features.pruefungssimulation, isTrue);
      // Gewichte müssen sich immer zu 1 summieren, sonst wäre der Lernstand
      // systematisch verzerrt.
      final summe = ap2.normalisierteGewichte.values.reduce((a, b) => a + b);
      expect(summe, closeTo(1.0, 0.0001));
    },
  );

  test('Der gebündelte Kurs lädt alle Fragen mit allen 8 Fragetypen', () async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );

    expect(paket.fragen, isNotEmpty);

    final vorhandeneTypen = paket.fragen.map((f) => frageTypVon(f.typ)).toSet();
    expect(vorhandeneTypen, FrageTyp.values.toSet());

    final rechnung = paket.fragen.firstWhere((f) => f.typ == 'rechnung');
    expect(rechnung.loesungswert, isNotNull);
    expect(rechnung.toleranz, isNotNull);
    expect(rechnung.workedExample, isNotNull);

    // Jede Frage muss auf einen im Kurs deklarierten Bereich zeigen -
    // sonst taucht sie in Themenauswahl und Lernstand nicht auf.
    final bereichsIds = paket.kurs.bereiche.map((b) => b.id).toSet();
    for (final f in paket.fragen) {
      expect(bereichsIds, contains(f.bereich));
    }
  });

  test('Fachgespräch-Szenarien werden mitgeladen', () async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );
    expect(paket.szenarien, isNotEmpty);
  });

  // Regression: die Kategorienliste stand früher fest im Themenauswahl-Screen
  // und wich von den Daten ab - 21 Fragen waren dadurch unerreichbar.
  test('Kategorien lassen sich vollständig aus den Fragen ableiten', () async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );

    final ausGruppen = paket.kategorienProBereich.values
        .expand((k) => k)
        .toSet();
    final ausFragen = paket.fragen.map((f) => f.kategorie).toSet();

    expect(ausGruppen, ausFragen);
  });

  test('Ein unbekannter Kurs wirft statt still leer zu laden', () {
    expect(
      () => KursRepository().paketFuer('gibt-es-nicht'),
      throwsA(isA<StateError>()),
    );
  });

  _glossarTests();
}

// Das Glossar entscheidet sich am echten Bestand: Ein Nachschlagewerk, das
// bei kaum einer Frage anschlaegt, ist wirkungslos - eines, das bei jeder
// anschlaegt, ist Laerm.
void _glossarTests() {
  test('das Glossar des gebündelten Kurses wird geladen', () async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );

    expect(paket.glossar.istLeer, isFalse);
    expect(paket.glossar.eintraege.length, greaterThan(10));

    for (final e in paket.glossar.eintraege) {
      expect(e.begriff.trim(), isNotEmpty);
      expect(e.kurz.trim(), isNotEmpty, reason: '${e.begriff} ohne Kurztext');
    }
  });

  test('kein Begriff kommt doppelt vor', () async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );

    final begriffe = paket.glossar.eintraege.map((e) => e.begriff).toList();
    expect(begriffe.toSet().length, begriffe.length);
  });

  test('das Glossar greift bei einem sinnvollen Anteil der Fragen', () async {
    final paket = await KursRepository().paketFuer(
      KursRepository.standardKursId,
    );

    var mitTipp = 0;
    var maxProFrage = 0;
    for (final frage in paket.fragen) {
      final treffer = paket.glossar.findeIn(
        frage.frage,
        ausnahmen: frage.tippsAus.toSet(),
      );
      if (treffer.isNotEmpty) mitTipp++;
      if (treffer.length > maxProFrage) maxProFrage = treffer.length;
    }

    final anteil = mitTipp / paket.fragen.length;

    // Untergrenze: sonst waere die Funktion Zierde.
    expect(
      anteil,
      greaterThan(0.05),
      reason: 'Nur ${(anteil * 100).round()}% der Fragen bekommen einen Tipp.',
    );
    // Obergrenze: schlaegt es ueberall an, wird der Knopf ignoriert.
    expect(
      anteil,
      lessThan(0.75),
      reason: '${(anteil * 100).round()}% der Fragen - das ist Laerm.',
    );
    // Und keine Frage darf mit Begriffen zugeschuettet werden.
    expect(maxProFrage, lessThanOrEqualTo(8));
  });
}
