import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/kurse/kurs_bilder.dart';
import 'core/notifications/notification_service.dart';
import 'core/plattform/datei_ablage.dart';
import 'data/attempt_history_store.dart';
import 'data/auto_backup.dart';
import 'data/fsrs_card_store.dart';
import 'data/kurs_store.dart';
import 'data/migrationen.dart';
import 'data/settings_store.dart';

/// App-Version für Backup-Dateien.
///
/// Muss mit `version:` in pubspec.yaml synchron gehalten werden - dafür
/// package_info_plus als weitere Abhängigkeit einzuziehen wäre für einen
/// String übertrieben. Steht hier statt im Backup-Screen, weil sie
/// inzwischen an zwei Stellen gebraucht wird.
const appVersion = '1.2.0';

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

  // Wöchentliche Sicherung des Lernstands - bewusst NACH runApp und ohne
  // await: Die App startet dadurch keine Millisekunde später, und eine
  // fehlgeschlagene Sicherung kann den Start nicht aufhalten.
  // AutoBackup schluckt Fehler selbst.
  unawaited(AutoBackup().ausfuehrenWennFaellig(appVersion: appVersion));
}
