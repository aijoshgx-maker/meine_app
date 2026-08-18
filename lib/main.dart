import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/kurse/kurs_bilder.dart';
import 'core/notifications/notification_service.dart';
import 'core/plattform/datei_ablage.dart';
import 'data/attempt_history_store.dart';
import 'data/fsrs_card_store.dart';
import 'data/kurs_store.dart';
import 'data/migrationen.dart';
import 'data/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive läuft auf Web über IndexedDB - das Kursmodell funktioniert dort
  // vollständig, nur der Datei-Teil weiter unten nicht.
  await Hive.initFlutter();
  await Hive.openBox(FsrsCardStore.boxName);
  await Hive.openBox(AttemptHistoryStore.boxName);
  await Hive.openBox(SettingsStore.boxName);
  await Hive.openBox(KursStore.boxName);

  // Muss vor dem ersten Frame laufen: schlüsselt Bestandsdaten auf das
  // Mehrkurs-Schema um. Ohne das wäre bisheriger Lernfortschritt unsichtbar.
  await Migrationen().ausfuehren();

  // Basispfad für Bilder importierter Kurse. Auf Web null - dort zeigen
  // solche Bilder einen Platzhalter.
  KursBilder.basisPfadSetzen(await DateiAblage.basisPfad());

  // Benachrichtigungen gibt es nur auf Android; der Service steigt auf allen
  // anderen Plattformen selbst früh aus.
  await NotificationService().init();

  runApp(const ProviderScope(child: Ap2App()));
}
