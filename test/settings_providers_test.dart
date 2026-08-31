import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/app/settings_providers.dart';
import 'package:meine_app/data/settings_store.dart';

class _FakeSettingsStore implements SettingsStore {
  String? _themeMode;
  bool _remindersEnabled = false;

  @override
  String? themeModeLaden() => _themeMode;

  @override
  Future<void> themeModeSpeichern(String wert) async {
    _themeMode = wert;
  }

  @override
  bool remindersAktiviert() => _remindersEnabled;

  @override
  Future<void> remindersAktiviertSpeichern(bool aktiviert) async {
    _remindersEnabled = aktiviert;
  }

  String? _aktiverKurs;
  int _datenVersion = 0;

  @override
  String? aktiverKursLaden() => _aktiverKurs;

  @override
  Future<void> aktiverKursSpeichern(String kursId) async {
    _aktiverKurs = kursId;
  }

  @override
  int datenVersionLaden() => _datenVersion;

  @override
  Future<void> datenVersionSpeichern(int version) async {
    _datenVersion = version;
  }

  DateTime? _letztesAutoBackup;

  @override
  DateTime? letztesAutoBackupLaden() => _letztesAutoBackup;

  @override
  Future<void> letztesAutoBackupSpeichern(DateTime zeitpunkt) async {
    _letztesAutoBackup = zeitpunkt;
  }

  int _kartenProTag = SettingsStore.kartenProTagStandard;

  @override
  int kartenProTagLaden() => _kartenProTag;

  @override
  Future<void> kartenProTagSpeichern(int anzahl) async {
    _kartenProTag = anzahl;
  }

  bool _steigendeSchwierigkeit = true;

  @override
  bool steigendeSchwierigkeitLaden() => _steigendeSchwierigkeit;

  @override
  Future<void> steigendeSchwierigkeitSpeichern(bool aktiv) async {
    _steigendeSchwierigkeit = aktiv;
  }

  int einfuehrungsFenster = SettingsStore.einfuehrungsFensterStandard;

  @override
  int einfuehrungsFensterLaden() => einfuehrungsFenster;

  @override
  Future<void> einfuehrungsFensterSpeichern(int tage) async =>
      einfuehrungsFenster = tage;
}

void main() {
  test('themeModeProvider startet mit System, wenn nichts gespeichert ist', () {
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('themeModeProvider persistiert die Auswahl im Store', () async {
    final store = _FakeSettingsStore();
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).setzen(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(store.themeModeLaden(), 'dark');
  });

  group('kartenProTagProvider', () {
    ProviderContainer mitStore(_FakeSettingsStore store) {
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('startet auf dem Standardtempo', () {
      final container = mitStore(_FakeSettingsStore());

      expect(
        container.read(kartenProTagProvider),
        SettingsStore.kartenProTagStandard,
      );
    });

    test('setzen() persistiert im Store', () async {
      final store = _FakeSettingsStore();
      final container = mitStore(store);

      await container.read(kartenProTagProvider.notifier).setzen(35);

      expect(container.read(kartenProTagProvider), 35);
      expect(store.kartenProTagLaden(), 35);
    });

    // Der Regler kann nicht über das Maximum hinaus, ein manipulierter oder
    // aus einer späteren Version stammender Wert schon.
    test('Werte außerhalb der Grenzen werden geklemmt', () async {
      final store = _FakeSettingsStore();
      final container = mitStore(store);
      final controller = container.read(kartenProTagProvider.notifier);

      await controller.setzen(SettingsStore.kartenProTagMax + 30);
      expect(container.read(kartenProTagProvider), SettingsStore.kartenProTagMax);

      await controller.setzen(-5);
      expect(container.read(kartenProTagProvider), 0);
      expect(store.kartenProTagLaden(), 0);
    });
  });

  group('steigendeSchwierigkeitProvider', () {
    test('ist standardmäßig eingeschaltet', () {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(steigendeSchwierigkeitProvider), isTrue);
    });

    test('setzen() persistiert im Store', () async {
      final store = _FakeSettingsStore();
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(steigendeSchwierigkeitProvider.notifier).setzen(false);

      expect(container.read(steigendeSchwierigkeitProvider), isFalse);
      expect(store.steigendeSchwierigkeitLaden(), isFalse);
    });
  });

  group('einfuehrungsFensterProvider', () {
    test('startet auf dem Standardfenster', () {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(einfuehrungsFensterProvider),
        SettingsStore.einfuehrungsFensterStandard,
      );
    });

    test('setzen() persistiert und klemmt an den Grenzen', () async {
      final store = _FakeSettingsStore();
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final controller = container.read(einfuehrungsFensterProvider.notifier);

      await controller.setzen(60);
      expect(container.read(einfuehrungsFensterProvider), 60);
      expect(store.einfuehrungsFensterLaden(), 60);

      await controller.setzen(5);
      expect(
        container.read(einfuehrungsFensterProvider),
        SettingsStore.einfuehrungsFensterMin,
      );

      await controller.setzen(9999);
      expect(
        container.read(einfuehrungsFensterProvider),
        SettingsStore.einfuehrungsFensterMax,
      );
    });
  });
}
