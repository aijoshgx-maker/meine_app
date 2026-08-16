import 'dart:math';

import '../../../data/fsrs_card_store.dart';
import '../../../models/frage.dart';
import 'quiz_modus.dart';

// Maximale Kartenzahl pro "Heute fällig"-Session. Verhindert, dass sich
// verpasste Tage aufaddieren und die nächste Session überschwemmen.
const int _tageslimit = 30;

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
        // Tageslimit: Karten, die gestern oder früher fällig wurden, zählen
        // nicht doppelt – wir servieren einfach nur die ersten N.
        return faellige.take(_tageslimit).toList();
      case QuizArt.themenVertiefung:
        final auswahl =
            alle.where((f) => f.kategorie == modus.kategorie).toList();
        auswahl.shuffle(zufall);
        return auswahl;
      case QuizArt.pruefungssimulation:
        // Nur die Fragen der gewählten Prüfung, in der originalen Reihenfolge.
        final pruefungsId = modus.pruefungsId!;
        final pruefungsFragen = alle
            .where((f) => f.pruefung == pruefungsId)
            .toList()
          ..sort((a, b) =>
              (a.pruefungReihenfolge ?? 0).compareTo(b.pruefungReihenfolge ?? 0));
        return pruefungsFragen;
    }
  }
}
