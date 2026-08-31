import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_service.dart';
import '../data/settings_store.dart';

final settingsStoreProvider = Provider((ref) => SettingsStore());
final notificationServiceProvider = Provider((ref) => NotificationService());

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final gespeichert = ref.read(settingsStoreProvider).themeModeLaden();
    return _vonText(gespeichert);
  }

  Future<void> setzen(ThemeMode modus) async {
    state = modus;
    await ref.read(settingsStoreProvider).themeModeSpeichern(modus.name);
  }

  ThemeMode _vonText(String? wert) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == wert,
      orElse: () => ThemeMode.system,
    );
  }
}

/// Wie viele bisher ungesehene Fragen pro Tag drankommen.
///
/// Bestimmt das Tempo, mit dem der Kurs einmal durchläuft. Zurückgelegte
/// Karten ("Nochmal") kommen obendrauf und zählen nicht dagegen.
final kartenProTagProvider = NotifierProvider<KartenProTagController, int>(
  KartenProTagController.new,
);

class KartenProTagController extends Notifier<int> {
  @override
  int build() => ref.read(settingsStoreProvider).kartenProTagLaden();

  Future<void> setzen(int anzahl) async {
    state = anzahl.clamp(0, SettingsStore.kartenProTagMax);
    await ref.read(settingsStoreProvider).kartenProTagSpeichern(state);
  }
}

/// Ob Fragen, die mehrfach sicher richtig beantwortet wurden, in einer
/// haerteren Fassung gestellt werden.
///
/// Erprobung. Der Schalter steht in den Einstellungen unter "Erprobung"; ist
/// er aus, verhaelt sich die App wie vorher. Der Zaehler an der Karte laeuft
/// trotzdem weiter, damit ein spaeteres Einschalten nicht bei null beginnt.
final steigendeSchwierigkeitProvider =
    NotifierProvider<SteigendeSchwierigkeitController, bool>(
      SteigendeSchwierigkeitController.new,
    );

class SteigendeSchwierigkeitController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).steigendeSchwierigkeitLaden();

  Future<void> setzen(bool aktiv) async {
    state = aktiv;
    await ref.read(settingsStoreProvider).steigendeSchwierigkeitSpeichern(aktiv);
  }
}

// Erinnerungen sind standardmäßig aus; die Android-13-Berechtigung wird erst
// angefragt, wenn der Nutzer sie hier aktiv einschaltet (kein ungefragter
// Permission-Dialog beim ersten App-Start).
final remindersEnabledProvider =
    NotifierProvider<RemindersEnabledController, bool>(
      RemindersEnabledController.new,
    );

class RemindersEnabledController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).remindersAktiviert();

  Future<void> setzen(bool aktiviert) async {
    if (aktiviert) {
      final erlaubt = await ref
          .read(notificationServiceProvider)
          .berechtigungAnfragen();
      if (!erlaubt) return;
    } else {
      await ref.read(notificationServiceProvider).erinnerungAbbrechen();
    }
    state = aktiviert;
    await ref
        .read(settingsStoreProvider)
        .remindersAktiviertSpeichern(aktiviert);
  }
}
