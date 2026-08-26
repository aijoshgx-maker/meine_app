import 'dart:math';

import '../../../data/fsrs_card_store.dart';
import '../../../models/frage.dart';
import 'quiz_modus.dart';

/// Das Tagespensum: was heute an Wiederholungen und neuen Karten ansteht.
///
/// Bewusst ein eigener Typ und nicht nur eine Zahl: Dashboard und Session
/// müssen dasselbe meinen, und die Aufteilung gehört in den Text auf dem
/// Dashboard ("7 Wiederholungen + 20 neue Karten"). Eine reine Summe hätte
/// sich früher oder später auseinanderentwickelt.
class Tagespensum {
  /// Karten mit gespeichertem Stand, deren Termin erreicht ist - gedeckelt.
  final List<Frage> wiederholungen;

  /// Bisher ungesehene Karten, soweit das Tagesbudget noch reicht.
  final List<Frage> neue;

  /// Wie viele Wiederholungen heute überfällig sind, aber nicht mehr ins
  /// Pensum passen. Nur zur Anzeige - sie kommen morgen wieder.
  final int zurueckgestellt;

  const Tagespensum({
    required this.wiederholungen,
    required this.neue,
    this.zurueckgestellt = 0,
  });

  static const leer = Tagespensum(wiederholungen: [], neue: []);

  int get gesamt => wiederholungen.length + neue.length;

  /// Wiederholungen zuerst: Was man schon einmal wusste, ist am ehesten
  /// wieder zu verlieren. Neue Karten kommen danach.
  List<Frage> get fragen => [...wiederholungen, ...neue];
}

// Reine, von Riverpod/Hive entkoppelte Auswahllogik: welche Fragen kommen in
// welcher Reihenfolge in eine Session, je nach QuizModus. Dadurch bleibt der
// QuizSessionController mode-agnostisch und diese Klasse ist ohne
// Provider-Setup unit-testbar.
class QuizFragenAuswahl {
  /// Obergrenze der Wiederholungen, als Vielfaches des Tagesbudgets.
  ///
  /// Wer eine Woche aussetzt, hat sonst dreihundert fällige Karten vor sich
  /// und macht gar nichts mehr. Der Rest bleibt fällig und kommt morgen -
  /// nur eben nicht alles an einem Tag. Als Vielfaches, damit die Grenze mit
  /// dem gewählten Tempo mitwächst und keinen zweiten Regler braucht.
  static const int wiederholungsFaktor = 3;

  /// Auch bei "0 neue Karten pro Tag" soll noch wiederholt werden können.
  static const int mindestWiederholungen = 20;

  /// Stellt das Tagespensum zusammen.
  ///
  /// [neueHeuteSchon] sind die heute bereits angefangenen neuen Karten; sie
  /// gehen vom Budget ab, damit eine zweite Session am selben Tag nicht
  /// wieder zwanzig neue auftischt.
  Tagespensum tagespensum(
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    required int neueProTag,
    required int neueHeuteSchon,
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

    faellige.shuffle(zufall);
    ungesehen.shuffle(zufall);

    final wLimit = max(
      mindestWiederholungen,
      neueProTag * wiederholungsFaktor,
    );
    final wiederholungen = faellige.take(wLimit).toList();

    final budget = max(0, neueProTag - neueHeuteSchon);
    final neue = ungesehen.take(budget).toList();

    return Tagespensum(
      wiederholungen: wiederholungen,
      neue: neue,
      zurueckgestellt: faellige.length - wiederholungen.length,
    );
  }

  List<Frage> waehleFragen(
    QuizModus modus,
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    int neueProTag = 20,
    int neueHeuteSchon = 0,
  }) {
    switch (modus.art) {
      case QuizArt.freiUebung:
        return List.of(alle);
      case QuizArt.heuteFaellig:
        return tagespensum(
          alle,
          kartenstaende: kartenstaende,
          zufall: zufall,
          neueProTag: neueProTag,
          neueHeuteSchon: neueHeuteSchon,
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
