import '../models/karteikarte.dart';

// Wie gut der Nutzer eine Karte beim Lernen wusste. Anki-Konvention,
// da diese Selbsteinschätzung in der Lernforschung am besten dokumentiert ist.
enum Bewertung { nochmal, schwer, gut, leicht }

const double _minEaseFactor = 1.3;

// Vereinfachter SM-2-Algorithmus: bestimmt anhand der Selbsteinschätzung,
// wie sich Ease-Faktor, Intervall und Fälligkeitsdatum einer Karte ändern.
// Bewusst vereinfacht (feste Multiplikatoren statt feingetunter SM-2-Tabelle),
// damit der Ablauf für einen Programmier-Anfänger nachvollziehbar bleibt.
class SpacedRepetitionService {
  Karteikarte bewerten(Karteikarte karte, Bewertung bewertung) {
    final jetzt = DateTime.now();
    double neueEase = karte.easeFactor;
    int neuesIntervall;
    int neueWiederholungen = karte.wiederholungen;

    switch (bewertung) {
      case Bewertung.nochmal:
        neueWiederholungen = 0;
        neuesIntervall = 0;
        neueEase = _begrenzeEase(karte.easeFactor - 0.2);
        break;
      case Bewertung.schwer:
        neueWiederholungen += 1;
        neuesIntervall = karte.intervallTage <= 0
            ? 1
            : (karte.intervallTage * 1.2).round();
        neueEase = _begrenzeEase(karte.easeFactor - 0.15);
        break;
      case Bewertung.gut:
        neueWiederholungen += 1;
        neuesIntervall = karte.intervallTage <= 0
            ? 1
            : (karte.intervallTage * karte.easeFactor).round();
        break;
      case Bewertung.leicht:
        neueWiederholungen += 1;
        neuesIntervall = karte.intervallTage <= 0
            ? 4
            : (karte.intervallTage * karte.easeFactor * 1.3).round();
        neueEase = karte.easeFactor + 0.15;
        break;
    }

    karte.easeFactor = neueEase;
    karte.intervallTage = neuesIntervall;
    karte.wiederholungen = neueWiederholungen;
    karte.zuletztGelernt = jetzt;
    karte.faelligAm = jetzt.add(Duration(days: neuesIntervall));
    return karte;
  }

  bool istFaellig(Karteikarte karte) => !karte.faelligAm.isAfter(DateTime.now());

  double _begrenzeEase(double ease) =>
      ease < _minEaseFactor ? _minEaseFactor : ease;
}
