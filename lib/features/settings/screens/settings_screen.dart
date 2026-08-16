import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/settings_providers.dart';

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
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Erinnerung an fällige Karten'),
            subtitle: const Text(
              'Tägliche Erinnerung um 18 Uhr, wenn Karten fällig sind.',
            ),
            value: remindersEnabled,
            onChanged: remindersController.setzen,
          ),
          const SizedBox(height: 24),
          Text('Daten', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup'),
              subtitle: const Text(
                'Lernstand exportieren oder wiederherstellen',
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
