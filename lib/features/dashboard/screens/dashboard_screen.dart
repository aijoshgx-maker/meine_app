import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/settings_providers.dart';
import '../../kurse/providers/kurs_providers.dart';
import '../../quiz/providers/quiz_modus.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/behaltensquote_chart.dart';
import '../widgets/kalibrierung_chart.dart';
import '../widgets/pruefungsreife_chart.dart';
import '../widgets/schwache_themen_chart.dart';

// Zentrale Übersicht: Behaltensquote, Lernstand, Kalibrierung, fällige
// Wiederholungen, schwache Themen - immer bezogen auf den aktiven Kurs.
//
// Welche Aktionen angeboten werden, hängt am Kurs: ein Paket ohne Testläufe
// oder Dialog-Szenarien zeigt die Knöpfe gar nicht erst.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faelligeAnzahl = ref.watch(faelligeAnzahlProvider);
    final paketAsync = ref.watch(aktivesPaketProvider);
    final fehlerquellen = ref.watch(fehlerquellenAnzahlProvider).value ?? 0;

    // Erinnerung bei jedem Dashboard-Aufbau opportunistisch neu planen (nur
    // wenn der Nutzer Erinnerungen aktiviert hat). Bewusst direkt im Build
    // statt nur via ref.listen, damit es auch beim allerersten Aufbau läuft
    // und nicht erst bei einer späteren Änderung des Fällig-Werts.
    if (ref.read(remindersEnabledProvider)) {
      faelligeAnzahl.whenData(
        (anzahl) => ref
            .read(notificationServiceProvider)
            .faelligeErinnerungPlanen(anzahl),
      );
    }

    final paket = paketAsync.value;
    final kurs = paket?.kurs;

    // Modi nur anbieten, wenn der Kurs sie mitbringt UND auch Inhalt dafür da
    // ist - sonst landet man in einem leeren Screen.
    final zeigeDialog =
        (kurs?.features.fachgespraech ?? false) &&
        (paket?.szenarien.isNotEmpty ?? false);
    final zeigeTestlauf =
        (kurs?.features.pruefungssimulation ?? false) &&
        (paket?.fragenProPruefung.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(kurs?.titel ?? 'Lernen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Kurs wechseln',
            onPressed: () => context.go('/kurse'),
          ),
        ],
      ),
      body: paketAsync.hasError
          ? _KeinKurs(fehler: paketAsync.error!)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PensumKarte(
                  pensum: ref.watch(tagespensumProvider),
                  onStarten: () => context.go(
                    '/quiz',
                    extra: const QuizModus.heuteFaellig(),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go(
                        '/quiz',
                        extra: const QuizModus.freiUebung(),
                      ),
                      child: const Text('Frei üben'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go(
                        '/quiz',
                        extra: const QuizModus.heuteFaellig(),
                      ),
                      child: const Text('Heute fällig'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/themenauswahl'),
                      child: const Text('Thema vertiefen'),
                    ),
                    // Erscheint nur, wenn es wirklich etwas zu korrigieren
                    // gibt - ein Knopf, der in eine leere Session fuehrt,
                    // waere ein leeres Versprechen.
                    if (fehlerquellen > 0)
                      FilledButton.tonalIcon(
                        onPressed: () => context.go(
                          '/quiz',
                          extra: const QuizModus.fehlerquellen(),
                        ),
                        icon: const Icon(Icons.error_outline, size: 16),
                        label: Text('Fehlerquellen ($fehlerquellen)'),
                      ),
                    if (zeigeDialog)
                      ElevatedButton.icon(
                        onPressed: () => context.go('/fachgespraech'),
                        icon: const Icon(Icons.record_voice_over, size: 16),
                        label: Text(kurs!.begriffe.dialog),
                      ),
                    if (zeigeTestlauf)
                      ElevatedButton.icon(
                        onPressed: () => context.go('/pruefungssimulation'),
                        icon: const Icon(Icons.assignment_outlined, size: 16),
                        label: Text(kurs!.begriffe.testlauf),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const BehaltensquoteChart(),
                const SizedBox(height: 12),
                const PruefungsreifeChart(),
                const SizedBox(height: 12),
                const KalibrierungChart(),
                const SizedBox(height: 12),
                const SchwacheThemenChart(),
              ],
            ),
    );
  }
}

/// Das heutige Pensum, aufgeteilt in Wiederholungen und neue Karten.
///
/// Die Aufteilung steht bewusst da: Eine reine Gesamtzahl sagt nicht, ob
/// heute viel zu wiederholen ist oder ob nur neues Material ansteht - und
/// genau das entscheidet, wie anstrengend die Session wird.
///
/// Die Karte ist der kuerzeste Weg ins Pensum: Wer sie liest, will loslegen
/// und soll dafuer nicht erst den passenden Knopf darunter suchen.
class _PensumKarte extends StatelessWidget {
  final AsyncValue<Tagespensum> pensum;
  final VoidCallback onStarten;

  const _PensumKarte({required this.pensum, required this.onStarten});

  @override
  Widget build(BuildContext context) {
    final farben = Theme.of(context).colorScheme;
    final offen = pensum.value?.gesamt ?? 0;

    return Card(
      color: farben.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Nur antippbar, wenn es etwas zu tun gibt - ein Tippen, das in eine
        // leere Session fuehrt, waere ein leeres Versprechen.
        onTap: offen > 0 ? onStarten : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: pensum.when(
            loading: () => const Text('Tagespensum wird geladen …'),
            error: (_, _) => const Text('Tagespensum nicht verfügbar'),
            data: (p) {
              if (p.gesamt == 0) {
                return Text(
                  'Heute nichts mehr offen – gut gemacht!',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              }

              final teile = [
                if (p.wiederholungen.isNotEmpty)
                  '${p.wiederholungen.length} '
                      '${p.wiederholungen.length == 1 ? "Wiederholung" : "Wiederholungen"}',
                if (p.neue.isNotEmpty) '${p.neue.length} neu',
              ];

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heute ${p.gesamt} '
                          '${p.gesamt == 1 ? "Karte" : "Karten"}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teile.join(' · '),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.play_arrow, color: farben.onPrimaryContainer),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KeinKurs extends StatelessWidget {
  final Object fehler;
  const _KeinKurs({required this.fehler});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.library_books_outlined, size: 40),
          const SizedBox(height: 12),
          Text('$fehler', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/kurse'),
            icon: const Icon(Icons.add),
            label: const Text('Lernpaket importieren'),
          ),
        ],
      ),
    ),
  );
}
