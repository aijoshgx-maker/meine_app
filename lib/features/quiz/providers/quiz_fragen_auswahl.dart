import 'dart:math';

import '../../../data/fsrs_card_store.dart';
import '../../../models/frage.dart';
import 'quiz_modus.dart';

// Reine, von Riverpod/Hive entkoppelte Auswahllogik: welche Fragen kommen in
// welcher Reihenfolge in eine Session, je nach QuizModus. Dadurch bleibt der
// QuizSessionController mode-agnostisch und diese Klasse ist ohne
// Provider-Setup unit-testbar.
class QuizFragenAuswahl {
  List<Frage> waehleFragen(
    QuizModus modus,
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
  }) {
    switch (modus.art) {
      case QuizArt.freiUebung:
        return List.of(alle);
      case QuizArt.heuteFaellig:
        final jetzt = DateTime.now();
        final faellige = alle.where((f) {
          final stand = kartenstaende[f.id];
          if (stand == null) return true; // nie gelernt -> sofort fällig
          return !stand.card.due.isAfter(jetzt);
        }).toList();
        faellige.shuffle(zufall);
        return faellige;
      case QuizArt.pruefungssimulation:
        final auswahl = alle.where((f) => f.bereich == modus.bereich).toList();
        auswahl.shuffle(zufall);
        return auswahl;
    }
  }
}
