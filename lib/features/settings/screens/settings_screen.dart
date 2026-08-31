import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/settings_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/settings_store.dart' show SettingsStore;
import '../../kurse/providers/kurs_providers.dart' show aktivesPaketProvider;

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
    final kartenProTag = ref.watch(kartenProTagProvider);
    final steigendeSchwierigkeit = ref.watch(steigendeSchwierigkeitProvider);
    // Ohne die Fragenzahl des Kurses bliebe der Regler eine abstrakte Zahl.
    final fragenImKurs = ref.watch(aktivesPaketProvider).value?.fragen.length;

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
          // Ein Budget für Wiederholungen UND neue Karten. Getrennt gedeckelt
          // standen an einem Tag achtzig Karten an - eine Zahl, vor der man
          // gar nicht erst anfängt.
          Text(
            kartenProTag == 0
                ? 'Pausiert – es kommen keine neuen Fragen dazu.'
                : '$kartenProTag neue Fragen pro Tag',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: kartenProTag.toDouble(),
            max: SettingsStore.kartenProTagMax.toDouble(),
            divisions: SettingsStore.kartenProTagMax ~/ 5,
            label: '$kartenProTag',
            onChanged: (wert) =>
                ref.read(kartenProTagProvider.notifier).setzen(wert.round()),
          ),
          Text(
            fragenImKurs == null || kartenProTag == 0
                ? 'So viele bisher ungesehene Fragen kommen täglich dazu. '
                      'Karten, die du mit „Nochmal" zurücklegst, kommen '
                      'obendrauf und zählen nicht dagegen.'
                : 'So viele bisher ungesehene Fragen kommen täglich dazu – '
                      'bei $fragenImKurs Fragen im Kurs läuft er damit in '
                      'etwa ${(fragenImKurs / kartenProTag).ceil()} Tagen '
                      'einmal durch. Karten, die du mit „Nochmal" '
                      'zurücklegst, kommen obendrauf und zählen nicht '
                      'dagegen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text('Erprobung', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // Eigener Abschnitt, damit erkennbar bleibt: Das ist ein Versuch,
          // keine fertige Funktion. Wer ihn ausschaltet, bekommt die App
          // exakt wie vorher.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Steigende Schwierigkeit'),
            subtitle: const Text(
              'Fragen, die du mehrmals sicher und richtig beantwortet hast, '
              'werden schrittweise härter gestellt – erst ohne Tipps, dann '
              'ohne Antwortauswahl. Ein Fehler nimmt eine Stufe zurück.',
            ),
            value: steigendeSchwierigkeit,
            onChanged: ref.read(steigendeSchwierigkeitProvider.notifier).setzen,
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
