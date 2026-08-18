import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings_providers.dart';
import '../../../data/attempt_history_store.dart';
import '../../../data/fsrs_card_store.dart';
import '../../../data/kurs_repository.dart';
import '../../../data/kurs_store.dart';
import '../../../data/store_providers.dart';
import '../../../models/kurs.dart';
import '../../../models/lernpaket.dart';

final kursStoreProvider = Provider((ref) => KursStore());

final kursRepositoryProvider = Provider(
  (ref) => KursRepository(store: ref.read(kursStoreProvider)),
);

/// Liste aller installierten Kurse (gebündelt + importiert).
///
/// Wird nach jedem Import/Deinstallieren invalidiert, damit die
/// Kursverwaltung sofort den neuen Stand zeigt.
final alleKurseProvider = FutureProvider<List<Kurs>>(
  (ref) => ref.read(kursRepositoryProvider).alleKurse(),
);

/// Id des aktiven Kurses, in den Einstellungen persistiert.
///
/// Alles Inhaltliche hängt hieran: wechselt die Id, laden Fragen, Themen,
/// Testläufe und Dashboard automatisch neu.
final aktiverKursIdProvider = NotifierProvider<AktiverKursController, String?>(
  AktiverKursController.new,
);

class AktiverKursController extends Notifier<String?> {
  @override
  String? build() => ref.read(settingsStoreProvider).aktiverKursLaden();

  Future<void> wechseln(String kursId) async {
    if (state == kursId) return;
    state = kursId;
    await ref.read(settingsStoreProvider).aktiverKursSpeichern(kursId);
  }
}

/// Das vollständige Paket des aktiven Kurses - die zentrale Datenquelle.
final aktivesPaketProvider = FutureProvider<Lernpaket>((ref) async {
  final gewuenscht = ref.watch(aktiverKursIdProvider);
  final repository = ref.read(kursRepositoryProvider);

  final kurs = await repository.aufloesen(gewuenscht);
  if (kurs == null) {
    throw StateError(
      'Es ist kein Kurs installiert. Bitte ein Lernpaket importieren.',
    );
  }
  return repository.paketFuer(kurs.id);
});

/// Nur die Kursbeschreibung des aktiven Kurses.
final aktiverKursProvider = FutureProvider<Kurs>(
  (ref) async => (await ref.watch(aktivesPaketProvider.future)).kurs,
);

/// Wird nach jeder gespeicherten Bewertung hochgezählt. Die Auswertungen im
/// Dashboard lesen ihre Daten direkt aus Hive und würden sonst innerhalb
/// einer Session nie aktualisieren - sie beobachten stattdessen diesen
/// Zähler.
final lernfortschrittVersionProvider =
    NotifierProvider<LernfortschrittVersion, int>(LernfortschrittVersion.new);

class LernfortschrittVersion extends Notifier<int> {
  @override
  int build() => 0;

  void melden() => state++;
}

/// Installiert und entfernt Kurse. Kapselt das Aufräumen des zugehörigen
/// Lernfortschritts, damit kein verwaister Zustand zurückbleibt.
final kursVerwaltungProvider = Provider(
  (ref) => KursVerwaltung(
    store: ref.read(kursStoreProvider),
    karten: ref.read(fsrsCardStoreProvider),
    verlauf: ref.read(attemptHistoryStoreProvider),
    ref: ref,
  ),
);

class KursVerwaltung {
  final KursStore store;
  final FsrsCardStore karten;
  final AttemptHistoryStore verlauf;
  final Ref ref;

  const KursVerwaltung({
    required this.store,
    required this.karten,
    required this.verlauf,
    required this.ref,
  });

  /// Schreibt ein geprüftes Paket in den Store und macht es zum aktiven Kurs.
  Future<void> installieren(Lernpaket paket, {bool aktivieren = true}) async {
    await store.installieren(paket);
    ref.invalidate(alleKurseProvider);
    if (aktivieren) {
      await ref.read(aktiverKursIdProvider.notifier).wechseln(paket.kurs.id);
    }
    ref.invalidate(aktivesPaketProvider);
  }

  /// Entfernt einen importierten Kurs samt Lernfortschritt.
  ///
  /// Gebündelte Kurse lassen sich nicht deinstallieren - sie liegen in den
  /// App-Assets und wären beim nächsten Start ohnehin wieder da.
  Future<KursEntferntErgebnis> entfernen(String kursId) async {
    final geloeschteKarten = await karten.kursLoeschen(kursId);
    final geloeschteVersuche = await verlauf.kursLoeschen(kursId);
    await store.entfernen(kursId);

    ref.invalidate(alleKurseProvider);
    if (ref.read(aktiverKursIdProvider) == kursId) {
      // Auf den Standardkurs zurückfallen, statt ohne aktiven Kurs
      // dazustehen.
      await ref
          .read(aktiverKursIdProvider.notifier)
          .wechseln(KursRepository.standardKursId);
    }
    ref.invalidate(aktivesPaketProvider);

    return KursEntferntErgebnis(
      geloeschteKarten: geloeschteKarten,
      geloeschteVersuche: geloeschteVersuche,
    );
  }
}

class KursEntferntErgebnis {
  final int geloeschteKarten;
  final int geloeschteVersuche;

  const KursEntferntErgebnis({
    required this.geloeschteKarten,
    required this.geloeschteVersuche,
  });
}
