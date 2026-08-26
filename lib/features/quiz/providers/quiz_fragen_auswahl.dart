import 'dart:math';

import '../../../data/fsrs_card_store.dart';
import '../../../models/frage.dart';
import 'quiz_modus.dart';

/// Das Tagespensum: die Karten, die heute anstehen.
///
/// Ein einziges Budget fuer beides. Wiederholungen und neue Karten getrennt
/// zu deckeln hiess in der Praxis, dass an einem Tag achtzig Karten
/// vorlagen - eine Zahl, vor der man gar nicht erst anfaengt.
///
/// Bewusst ein eigener Typ und nicht nur eine Zahl: Dashboard und Session
/// muessen dasselbe meinen, und die Aufteilung gehoert in den Text auf dem
/// Dashboard ("13 Wiederholungen · 7 neu").
class Tagespensum {
  /// Karten mit gespeichertem Stand, deren Termin erreicht ist.
  final List<Frage> wiederholungen;

  /// Bisher ungesehene Karten, soweit das Tagesbudget noch reicht.
  final List<Frage> neue;

  const Tagespensum({required this.wiederholungen, required this.neue});

  static const leer = Tagespensum(wiederholungen: [], neue: []);

  int get gesamt => wiederholungen.length + neue.length;

  /// Wiederholungen zuerst: Was man schon einmal wusste, ist am ehesten
  /// wieder zu verlieren. Neue Karten fuellen auf, was danach noch frei ist.
  List<Frage> get fragen => [...wiederholungen, ...neue];
}

// Reine, von Riverpod/Hive entkoppelte Auswahllogik: welche Fragen kommen in
// welcher Reihenfolge in eine Session, je nach QuizModus. Dadurch bleibt der
// QuizSessionController mode-agnostisch und diese Klasse ist ohne
// Provider-Setup unit-testbar.
class QuizFragenAuswahl {
  /// Stellt das Tagespensum zusammen.
  ///
  /// [kartenProTag] ist die Obergrenze fuer den ganzen Tag, nicht je Topf.
  /// [heuteSchonBearbeitet] geht davon ab: Was heute schon beantwortet
  /// wurde, zaehlt aufs Tagessoll, damit eine zweite Session nicht noch
  /// einmal das volle Pensum auftischt.
  ///
  /// Ueberfaellige Wiederholungen summieren sich nicht auf. Wer eine Woche
  /// aussetzt, findet am achten Tag genauso [kartenProTag] Karten vor wie am
  /// ersten - nur eben die am laengsten faelligen zuerst. Alles andere fuehrt
  /// zu einem Berg, vor dem man kapituliert.
  Tagespensum tagespensum(
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    required int kartenProTag,
    required int heuteSchonBearbeitet,
    DateTime? jetzt,
  }) {
    final zeitpunkt = jetzt ?? DateTime.now();

    final faellige = <Frage>[];
    final ungesehen = <Frage>[];
    for (final frage in alle) {
      final stand = kartenstaende[frage.id];
      if (stand == null) {
        ungesehen.add(frage);
      } else if (!stand.card.due.isAfter(zeitpunkt)) {
        faellige.add(frage);
      }
    }

    // Die am laengsten ueberfaellige Karte zuerst: Sie ist am ehesten wieder
    // verloren. Gemischt wird nur, was am selben Termin haengt.
    faellige.shuffle(zufall);
    faellige.sort(
      (a, b) => kartenstaende[a.id]!.card.due.compareTo(
        kartenstaende[b.id]!.card.due,
      ),
    );
    ungesehen.shuffle(zufall);

    final budget = max(0, kartenProTag - heuteSchonBearbeitet);
    final wiederholungen = faellige.take(budget).toList();
    final neue = ungesehen.take(budget - wiederholungen.length).toList();

    return Tagespensum(wiederholungen: wiederholungen, neue: neue);
  }

  List<Frage> waehleFragen(
    QuizModus modus,
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    int kartenProTag = 20,
    int heuteSchonBearbeitet = 0,
  }) {
    switch (modus.art) {
      case QuizArt.freiUebung:
        return List.of(alle);
      case QuizArt.heuteFaellig:
        return tagespensum(
          alle,
          kartenstaende: kartenstaende,
          zufall: zufall,
          kartenProTag: kartenProTag,
          heuteSchonBearbeitet: heuteSchonBearbeitet,
        ).fragen;
      case QuizArt.fehlerquellen:
        // Karten, die beim letzten Mal "sicher, aber falsch" waren. Das Flag
        // wird bei jeder Bewertung neu gesetzt - eine richtig beantwortete
        // Frage faellt also von selbst wieder heraus, die Menge leert sich.
        final schwachstellen = alle
            .where((f) => kartenstaende[f.id]?.hochkonfidentFalsch == true)
            .toList();
        schwachstellen.shuffle(zufall);
        return schwachstellen;
      case QuizArt.themenVertiefung:
        final auswahl = alle
            .where((f) => f.kategorie == modus.kategorie)
            .toList();
        auswahl.shuffle(zufall);
        return auswahl;
      case QuizArt.pruefungssimulation:
        // Nur die Fragen der gewählten Prüfung, in der originalen Reihenfolge.
        final pruefungsId = modus.pruefungsId!;
        final pruefungsFragen =
            alle.where((f) => f.pruefung == pruefungsId).toList()..sort(
              (a, b) => (a.pruefungReihenfolge ?? 0).compareTo(
                b.pruefungReihenfolge ?? 0,
              ),
            );
        return pruefungsFragen;
    }
  }
}
