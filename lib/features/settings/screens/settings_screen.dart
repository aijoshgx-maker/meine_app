import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/settings_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/settings_store.dart' show SettingsStore;

// Lädt nur das "stand"-Datum aus _rechtsstand.json - der Rest der Datei
// (Beitragssätze etc.) wird direkt in den Fragetexten verwendet, siehe
// assets/fragen/_rechtsstand.json.
final _wisoRechtsstandProvider = FutureProvider<String?>((ref) async {
  try {
    final text = await rootBundle.loadString('assets/fragen/_rechtsstand.json');
    final json = jsonDecode(text) as Map<String, dynamic>;
    return json['stand'] as String?;
  } catch (_) {
    return null;
  }
});

String? _formatiertesDatum(String? isoDatum) {
  if (isoDatum == null) return null;
  final teile = isoDatum.split('-');
  if (teile.length != 3) return isoDatum;
  return '${teile[2]}.${teile[1]}.${teile[0]}';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeController = ref.read(themeModeProvider.notifier);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final remindersController = ref.read(remindersEnabledProvider.notifier);
    final rechtsstand = ref.watch(_wisoRechtsstandProvider);
    final neueProTag = ref.watch(neueProTagProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Darstellung', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Hell')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dunkel')),
            ],
            selected: {themeMode},
            onSelectionChanged: (auswahl) =>
                themeController.setzen(auswahl.first),
          ),
          // Erinnerungen gibt es nur auf Android - auf Web und Desktop wäre
          // der Schalter ein Versprechen, das die Plattform nicht hält.
          if (NotificationService.unterstuetzt) ...[
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Erinnerung an das Tagespensum'),
              subtitle: const Text(
                'Tägliche Erinnerung um 18 Uhr, wenn noch etwas ansteht.',
              ),
              value: remindersEnabled,
              onChanged: remindersController.setzen,
            ),
          ],
          const SizedBox(height: 24),
          Text('Lerntempo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // Der Regler steuert nur die NEUEN Karten. Wiederholungen richten
          // sich nach dem Terminplan und lassen sich nicht wegdrehen - was
          // man angefangen hat, kommt zurück.
          Text(
            neueProTag == 0
                ? 'Keine neuen Karten – es wird nur wiederholt.'
                : '$neueProTag neue Karten pro Tag',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: neueProTag.toDouble(),
            max: SettingsStore.neueProTagMax.toDouble(),
            divisions: SettingsStore.neueProTagMax ~/ 5,
            label: '$neueProTag',
            onChanged: (wert) =>
                ref.read(neueProTagProvider.notifier).setzen(wert.round()),
          ),
          Text(
            'Bestimmt, wie viele bisher ungesehene Fragen täglich dazukommen. '
            'Wiederholungen kommen obendrauf, sobald ihr Termin erreicht ist.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text('Daten', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: const Text('Kurse'),
              subtitle: const Text(
                'Lernpakete importieren, wechseln oder entfernen',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/kurse'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup'),
              subtitle: const Text(
                'Lernstand aller Kurse sichern oder wiederherstellen',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/backup'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Über', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          rechtsstand.when(
            data: (stand) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('WISO-Rechtsstand'),
              subtitle: Text(_formatiertesDatum(stand) ?? 'nicht ermittelbar'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
