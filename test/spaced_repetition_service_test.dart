import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/models/karteikarte.dart';
import 'package:meine_app/services/spaced_repetition_service.dart';

void main() {
  final service = SpacedRepetitionService();

  Karteikarte neueKarte() => Karteikarte(
        id: 'test_001',
        frage: 'Frage?',
        antwort: 'Antwort.',
        themenbereich: 'Test',
        modulId: 'test_modul',
      );

  test('"Nochmal" setzt Wiederholungen und Intervall zurück', () {
    var karte = neueKarte();
    karte = service.bewerten(karte, Bewertung.gut);
    karte = service.bewerten(karte, Bewertung.gut);
    expect(karte.wiederholungen, greaterThan(0));

    karte = service.bewerten(karte, Bewertung.nochmal);

    expect(karte.wiederholungen, 0);
    expect(karte.intervallTage, 0);
  });

  test('"Leicht" lässt das Intervall stärker wachsen als "Gut"', () {
    final karteGut = service.bewerten(neueKarte(), Bewertung.gut);
    final zweiteBewertungGut = service.bewerten(karteGut, Bewertung.gut);

    final karteLeicht = service.bewerten(neueKarte(), Bewertung.leicht);
    final zweiteBewertungLeicht =
        service.bewerten(karteLeicht, Bewertung.leicht);

    expect(
      zweiteBewertungLeicht.intervallTage,
      greaterThan(zweiteBewertungGut.intervallTage),
    );
  });

  test('Ease-Faktor fällt nie unter 1.3', () {
    var karte = neueKarte();
    for (var i = 0; i < 20; i++) {
      karte = service.bewerten(karte, Bewertung.nochmal);
    }
    expect(karte.easeFactor, greaterThanOrEqualTo(1.3));
  });

  test('istFaellig erkennt eine frische Karte als sofort fällig', () {
    final karte = neueKarte();
    expect(service.istFaellig(karte), true);
  });
}
