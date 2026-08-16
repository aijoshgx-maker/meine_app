import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/backup_store.dart';
import '../../quiz/providers/quiz_providers.dart' show fragenProvider;

// Aktuelle App-Version für den Backup-Header. Kein package_info_plus als
// zusätzliche Abhängigkeit nötig - einfacher String, der mit
// pubspec.yaml/version synchron gehalten wird.
const _appVersionFuerBackup = '1.1.0';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _exportLaeuft = false;
  bool _importLaeuft = false;
  String? _statusText;

  final _backupStore = BackupStore();

  Future<void> _exportieren() async {
    setState(() {
      _exportLaeuft = true;
      _statusText = null;
    });
    try {
      final daten = _backupStore.erstellen(appVersion: _appVersionFuerBackup);
      final datei = await _backupStore.alsDateiSchreiben(daten);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(datei.path)],
          subject: 'AP2 Trainer – Lernstand-Backup',
          text:
              'Lernstand-Export vom '
              '${daten.exportiertAm.toLocal().toString().split('.').first} '
              '(${daten.anzahlKarten} Karten).',
        ),
      );
      if (!mounted) return;
      setState(() => _statusText = '${daten.anzahlKarten} Karten exportiert.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusText = 'Export fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _exportLaeuft = false);
    }
  }

  Future<void> _importieren() async {
    final datei = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Backup', extensions: ['json']),
      ],
    );
    if (datei == null) return;

    setState(() {
      _importLaeuft = true;
      _statusText = null;
    });

    try {
      final text = await File(datei.path).readAsString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      final daten = BackupDaten.fromJson(json);

      if (!mounted) return;
      final modus = await _modusAbfragen(daten);
      if (modus == null) {
        setState(() => _importLaeuft = false);
        return;
      }

      final alleFragen = await ref.read(fragenProvider.future);
      final bekannteIds = alleFragen.map((f) => f.id).toSet();

      final ergebnis = await _backupStore.importieren(
        daten,
        modus: modus,
        bekannteFrageIds: bekannteIds,
      );

      if (!mounted) return;
      setState(() {
        _statusText =
            '${ergebnis.importiert} neu, ${ergebnis.aktualisiert} aktualisiert, '
            '${ergebnis.verlaufHinzugefuegt} Verlaufseinträge hinzugefügt'
            '${ergebnis.uebersprungenUnbekannt > 0 ? ', ${ergebnis.uebersprungenUnbekannt} unbekannte Fragen übersprungen' : ''}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusText = 'Import fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _importLaeuft = false);
    }
  }

  Future<ImportModus?> _modusAbfragen(BackupDaten daten) {
    final datum = daten.exportiertAm.toLocal().toString().split('.').first;
    return showDialog<ImportModus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup importieren'),
        content: Text(
          '${daten.anzahlKarten} Karten, exportiert am $datum '
          '(App-Version ${daten.appVersion}).\n\n'
          'Wie soll importiert werden?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(ImportModus.zusammenfuehren),
            child: const Text('Zusammenführen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ImportModus.ersetzen),
            child: const Text('Ersetzen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Sichere deinen Lernstand (FSRS-Kartenstände, Verlauf, '
            'Einstellungen) als Datei oder stelle ihn auf einem anderen '
            'Gerät wieder her.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: const Text('Exportieren'),
              subtitle: const Text('Lernstand als Datei teilen'),
              trailing: _exportLaeuft
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _exportLaeuft ? null : _exportieren,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Importieren'),
              subtitle: const Text(
                'Backup-Datei auswählen und wiederherstellen',
              ),
              trailing: _importLaeuft
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _importLaeuft ? null : _importieren,
            ),
          ),
          if (_statusText != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_statusText!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
