import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeController = ref.read(themeModeProvider.notifier);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final remindersController = ref.read(remindersEnabledProvider.notifier);

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
        ],
      ),
    );
  }
}
