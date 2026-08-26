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

  int _neueProTag = SettingsStore.neueProTagStandard;

  @override
  int neueProTagLaden() => _neueProTag;

  @override
  Future<void> neueProTagSpeichern(int anzahl) async {
    _neueProTag = anzahl;
  }

  bool _steigendeSchwierigkeit = true;

  @override
  bool steigendeSchwierigkeitLaden() => _steigendeSchwierigkeit;

  @override
  Future<void> steigendeSchwierigkeitSpeichern(bool aktiv) async {
    _steigendeSchwierigkeit = aktiv;
  }
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

  group('neueProTagProvider', () {
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
        container.read(neueProTagProvider),
        SettingsStore.neueProTagStandard,
      );
    });

    test('setzen() persistiert im Store', () async {
      final store = _FakeSettingsStore();
      final container = mitStore(store);

      await container.read(neueProTagProvider.notifier).setzen(35);

      expect(container.read(neueProTagProvider), 35);
      expect(store.neueProTagLaden(), 35);
    });

    // Der Regler kann nicht über das Maximum hinaus, ein manipulierter oder
    // aus einer späteren Version stammender Wert schon.
    test('Werte außerhalb der Grenzen werden geklemmt', () async {
      final store = _FakeSettingsStore();
      final container = mitStore(store);
      final controller = container.read(neueProTagProvider.notifier);

      await controller.setzen(SettingsStore.neueProTagMax + 30);
      expect(container.read(neueProTagProvider), SettingsStore.neueProTagMax);

      await controller.setzen(-5);
      expect(container.read(neueProTagProvider), 0);
      expect(store.neueProTagLaden(), 0);
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
}
