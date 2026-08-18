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
}
