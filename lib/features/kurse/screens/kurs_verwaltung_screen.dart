import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/kurse/paket_parser.dart';
import '../../../models/kurs.dart';
import '../providers/kurs_providers.dart';

// Kursverwaltung: installierte Lernpakete anzeigen, wechseln, importieren
// und entfernen. Der Einstiegspunkt, der die App vom AP2-Trainer zum
// allgemeinen Lernwerkzeug macht.
class KursVerwaltungScreen extends ConsumerStatefulWidget {
  const KursVerwaltungScreen({super.key});

  @override
  ConsumerState<KursVerwaltungScreen> createState() =>
      _KursVerwaltungScreenState();
}

class _KursVerwaltungScreenState extends ConsumerState<KursVerwaltungScreen> {
  bool _importLaeuft = false;

  @override
  Widget build(BuildContext context) {
    final kurseAsync = ref.watch(alleKurseProvider);
    final aktiveId = ref.watch(aktiverKursIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurse'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importLaeuft ? null : _importieren,
        icon: _importLaeuft
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_importLaeuft ? 'Wird geprüft…' : 'Paket importieren'),
      ),
      body: kurseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Kurse nicht ladbar: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (kurse) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              'Installierte Lernpakete',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Ein Paket bringt Fragen, Bereiche und optionale Testläufe mit. '
              'Der Lernfortschritt wird je Kurs getrennt geführt.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final kurs in kurse)
              _KursKarte(
                kurs: kurs,
                istAktiv:
                    kurs.id == aktiveId ||
                    (aktiveId == null && kurs == kurse.first),
                onAktivieren: () =>
                    ref.read(aktiverKursIdProvider.notifier).wechseln(kurs.id),
                onEntfernen: kurs.quelle == KursQuelle.importiert
                    ? () => _entfernenBestaetigen(kurs)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _importieren() async {
    const typen = XTypeGroup(label: 'Lernpaket', extensions: ['json', 'zip']);
    final datei = await openFile(acceptedTypeGroups: const [typen]);
    if (datei == null) return;

    setState(() => _importLaeuft = true);
    try {
      final bytes = await datei.readAsBytes();
      // Das Einlesen ist reine Rechenarbeit und darf den Frame nicht
      // blockieren, wenn jemand ein sehr großes Paket wählt.
      final ergebnis = await Future(
        () => PaketParser().ausDatei(datei.name, Uint8List.fromList(bytes)),
      );

      if (!mounted) return;
      final bestaetigt = await _vorschauZeigen(ergebnis);
      if (bestaetigt != true || !mounted) return;

      await ref.read(kursVerwaltungProvider).installieren(ergebnis.paket);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${ergebnis.paket.kurs.titel}" importiert – '
            '${ergebnis.paket.fragen.length} Fragen.',
          ),
        ),
      );
    } on PaketFormatException catch (e) {
      if (mounted) await _fehlerZeigen(e.nachricht);
    } catch (e) {
      if (mounted) await _fehlerZeigen('Unerwarteter Fehler: $e');
    } finally {
      if (mounted) setState(() => _importLaeuft = false);
    }
  }

  /// Zeigt vor dem Installieren, was im Paket steckt - inklusive der beim
  /// Einlesen aufgefallenen Auffälligkeiten.
  Future<bool?> _vorschauZeigen(PaketErgebnis ergebnis) {
    final paket = ergebnis.paket;
    final kurs = paket.kurs;
    final ersetzt = ref.read(kursStoreProvider).kennt(kurs.id);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(kurs.titel),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kurs.kurzbeschreibung.isNotEmpty) ...[
                Text(kurs.kurzbeschreibung),
                const SizedBox(height: 12),
              ],
              _Zeile('Fragen', '${paket.fragen.length}'),
              _Zeile('Bereiche', '${kurs.bereiche.length}'),
              if (paket.szenarien.isNotEmpty)
                _Zeile('Dialog-Szenarien', '${paket.szenarien.length}'),
              if (kurs.pruefungen.isNotEmpty)
                _Zeile('Testläufe', '${kurs.pruefungen.length}'),
              if (paket.bilder.isNotEmpty)
                _Zeile('Bilder', '${paket.bilder.length}'),
              if (kurs.autor != null) _Zeile('Autor', kurs.autor!),
              if (ersetzt) ...[
                const SizedBox(height: 12),
                Text(
                  'Ein Kurs mit dieser ID ist bereits installiert und wird '
                  'ersetzt. Dein Lernfortschritt bleibt erhalten.',
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.primary,
                  ),
                ),
              ],
              if (ergebnis.warnungen.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Hinweise',
                  style: Theme.of(dialogContext).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                for (final warnung in ergebnis.warnungen.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $warnung',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ),
                if (ergebnis.warnungen.length > 8)
                  Text(
                    '… und ${ergebnis.warnungen.length - 8} weitere.',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(ersetzt ? 'Ersetzen' : 'Importieren'),
          ),
        ],
      ),
    );
  }

  Future<void> _fehlerZeigen(String nachricht) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Import nicht möglich'),
      content: Text(nachricht),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  Future<void> _entfernenBestaetigen(Kurs kurs) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('"${kurs.titel}" entfernen?'),
        content: const Text(
          'Der Kurs und der zugehörige Lernfortschritt werden gelöscht. '
          'Das lässt sich nicht rückgängig machen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (bestaetigt != true || !mounted) return;

    final ergebnis = await ref.read(kursVerwaltungProvider).entfernen(kurs.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Entfernt – ${ergebnis.geloeschteKarten} Karten und '
          '${ergebnis.geloeschteVersuche} Verlaufseinträge gelöscht.',
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  final String label;
  final String wert;
  const _Zeile(this.label, this.wert);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          wert,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _KursKarte extends StatelessWidget {
  final Kurs kurs;
  final bool istAktiv;
  final VoidCallback onAktivieren;
  final VoidCallback? onEntfernen;

  const _KursKarte({
    required this.kurs,
    required this.istAktiv,
    required this.onAktivieren,
    required this.onEntfernen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: istAktiv
          ? RoundedRectangleBorder(
              side: BorderSide(color: cs.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: istAktiv ? null : onAktivieren,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kurs.titel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (istAktiv)
                    Chip(
                      label: const Text('Aktiv'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: cs.primaryContainer,
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (onEntfernen != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Kurs entfernen',
                      onPressed: onEntfernen,
                    ),
                ],
              ),
              if (kurs.kurzbeschreibung.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  kurs.kurzbeschreibung,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Marke(
                    icon: kurs.quelle == KursQuelle.gebuendelt
                        ? Icons.inventory_2_outlined
                        : Icons.download_done_outlined,
                    text: kurs.quelle == KursQuelle.gebuendelt
                        ? 'Mitgeliefert'
                        : 'Importiert',
                  ),
                  _Marke(
                    icon: Icons.category_outlined,
                    text:
                        '${kurs.bereiche.length} '
                        '${kurs.bereiche.length == 1 ? 'Bereich' : 'Bereiche'}',
                  ),
                  if (kurs.features.pruefungssimulation &&
                      kurs.pruefungen.isNotEmpty)
                    _Marke(
                      icon: Icons.timer_outlined,
                      // "2x Testlauf" statt "2 Testlauf": Der Begriff kommt
                      // aus dem Kurs, eine Pluralform laesst sich daraus
                      // nicht zuverlaessig bilden.
                      text:
                          '${kurs.pruefungen.length}× ${kurs.begriffe.testlauf}',
                    ),
                  if (kurs.version != null)
                    _Marke(icon: Icons.tag, text: kurs.version!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marke extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Marke({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
