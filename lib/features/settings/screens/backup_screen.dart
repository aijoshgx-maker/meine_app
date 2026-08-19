import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../main.dart' show appVersion;
import '../../../data/backup_store.dart';
import '../../../data/fsrs_card_store.dart';
import '../../kurse/providers/kurs_providers.dart'
    show alleKurseProvider, kursRepositoryProvider;

// Version kommt aus main.dart - dort wird sie auch für die automatische
// Sicherung gebraucht, und zwei Stellen liefen sonst auseinander.

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
      final daten = _backupStore.erstellen(appVersion: appVersion);
      final name = _backupStore.dateinameFuer(daten.exportiertAm);

      // Über die Bytes statt über einen Dateipfad: funktioniert so auf
      // Android genauso wie auf Web, wo es kein Dateisystem gibt.
      final datei = XFile.fromData(
        _backupStore.alsBytes(daten),
        name: name,
        mimeType: 'application/json',
      );

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [datei],
          fileNameOverrides: [name],
          subject: 'Lernstand-Backup',
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
      // readAsString() vom XFile statt über dart:io - auf Web liefert der
      // Dateiauswahl-Dialog nur Bytes, keinen benutzbaren Pfad.
      final text = await datei.readAsString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      final daten = BackupDaten.fromJson(json);

      if (!mounted) return;
      final modus = await _modusAbfragen(daten);
      if (modus == null) {
        setState(() => _importLaeuft = false);
        return;
      }

      // Ein Backup enthält den Lernstand aller Kurse. Bekannt ist eine Karte
      // nur, wenn ihr Kurs installiert ist UND die Frage darin noch existiert
      // - alles andere wird übersprungen und im Ergebnis ausgewiesen.
      final kurse = await ref.read(alleKurseProvider.future);
      final repository = ref.read(kursRepositoryProvider);
      final bekannteSchluessel = <String>{};
      for (final kurs in kurse) {
        final paket = await repository.paketFuer(kurs.id);
        for (final frage in paket.fragen) {
          bekannteSchluessel.add(FsrsCardStore.schluessel(kurs.id, frage.id));
        }
      }

      final ergebnis = await _backupStore.importieren(
        daten,
        modus: modus,
        bekannteSchluessel: bekannteSchluessel,
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
