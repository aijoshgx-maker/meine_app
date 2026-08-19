import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/kurse/kurs_bilder.dart';
import '../../../core/quiz/erklaerung_teilen.dart';
import '../../../core/spaced_repetition/fsrs_scheduler.dart' show Rating;
import '../../../models/frage.dart';
import '../../../models/kurs.dart';
import '../../kurse/providers/kurs_providers.dart';
import '../providers/quiz_providers.dart';
import '../providers/session_break_provider.dart';
import '../providers/session_timer_provider.dart';
import '../widgets/antwort_eingabe.dart';
import '../widgets/bewertungs_buttons.dart';
import '../widgets/illustrationen/technische_illustration.dart';
import '../widgets/loesungs_ansicht.dart';
import '../widgets/konfidenz_auswahl.dart';

enum _SimAktion { pausieren, fortsetzen, beenden }

class QuizScreen extends ConsumerWidget {
  final QuizModus modus;

  const QuizScreen({super.key, required this.modus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(quizSessionProvider(modus));
    final istSim = modus.art == QuizArt.pruefungssimulation;
    final timer = istSim ? ref.watch(sessionTimerProvider(modus)) : null;

    ref.listen(sessionBreakProvider, (_, jetzt) {
      if (jetzt) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text('Du lernst schon eine Weile – kurze Pause?'),
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: const Text('Okay'),
              ),
            ],
          ),
        );
      }
    });

    final inSession = sessionAsync.value != null && !sessionAsync.value!.fertig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          if (timer != null && inSession) ...[
            _TimerAnzeige(timerZustand: timer),
            PopupMenuButton<_SimAktion>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Prüfungsmenü',
              onSelected: (aktion) => _handleSimAktion(context, ref, aktion),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: timer.pausiert
                      ? _SimAktion.fortsetzen
                      : _SimAktion.pausieren,
                  child: Row(
                    children: [
                      Icon(
                        timer.pausiert
                            ? Icons.play_arrow_outlined
                            : Icons.pause_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(timer.pausiert ? 'Fortsetzen' : 'Pausieren'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _SimAktion.beenden,
                  child: Row(
                    children: [
                      Icon(
                        Icons.stop_circle_outlined,
                        size: 20,
                        color: Colors.red,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Prüfung beenden',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (inSession) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${sessionAsync.value!.richtigBeantwortet}/'
                  '${sessionAsync.value!.index}',
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: (istSim && inSession && modus.pruefungsId != null)
          ? FloatingActionButton.small(
              onPressed: () =>
                  _zeigeZeichnungen(context, ref, modus.pruefungsId!),
              tooltip: 'Zeichnungen anzeigen',
              child: const Icon(Icons.map_outlined),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _QuizBody(modus: modus, sessionAsync: sessionAsync),
          if (timer?.pausiert == true)
            _PauseOverlay(
              onResume: () =>
                  ref.read(sessionTimerProvider(modus).notifier).fortsetzen(),
            ),
        ],
      ),
    );
  }

  void _handleSimAktion(
    BuildContext context,
    WidgetRef ref,
    _SimAktion aktion,
  ) {
    switch (aktion) {
      case _SimAktion.pausieren:
        ref.read(sessionTimerProvider(modus).notifier).pausieren();
      case _SimAktion.fortsetzen:
        ref.read(sessionTimerProvider(modus).notifier).fortsetzen();
      case _SimAktion.beenden:
        _pruefungBeendenDialog(context, ref);
    }
  }

  void _pruefungBeendenDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prüfung abbrechen?'),
        content: const Text(
          'Die Simulation wird beendet. Beim nächsten Start beginnt sie '
          'von vorne.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Weiter üben'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Beenden'),
          ),
        ],
      ),
    ).then((bestaetigt) {
      if (bestaetigt == true && context.mounted) {
        ref.invalidate(quizSessionProvider(modus));
        ref.invalidate(sessionTimerProvider(modus));
        context.go('/pruefungssimulation');
      }
    });
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

void _zeigeZeichnungen(
  BuildContext context,
  WidgetRef ref,
  String pruefungsId,
) {
  final paket = ref.read(aktivesPaketProvider).value;
  final info = paket?.kurs.pruefungFuer(pruefungsId);
  if (paket == null || info == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ZeichnungsViewer(info: info, kurs: paket.kurs),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _QuizBody extends ConsumerWidget {
  final QuizModus modus;
  final AsyncValue<QuizSessionState> sessionAsync;

  const _QuizBody({required this.modus, required this.sessionAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return sessionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (fehler, _) => Center(child: Text('Fehler beim Laden: $fehler')),
      data: (session) {
        if (session.fertig) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.gesamtFragen == 0
                      ? 'Keine Fragen in diesem Modus.'
                      : '${session.richtigBeantwortet} von '
                            '${session.gesamtFragen} richtig',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Zum Dashboard'),
                ),
              ],
            ),
          );
        }
        if (session.fragen.isEmpty) {
          return const Center(child: Text('Keine Fragen in diesem Modus.'));
        }

        final frage = session.aktuelleFrage!;
        final controller = ref.read(quizSessionProvider(modus).notifier);
        final bereitsUebersprungen = session.uebersprungeneIds.contains(
          frage.id,
        );
        final zeigeSkip =
            session.antwort.phase == FragePhase.antworten &&
            session.fragen.length > 1;

        // Die Tastatur verdeckt sonst die unteren Eingabefelder und den
        // "Weiter"-Knopf: Bei Lückentexten mit mehreren Lücken war das letzte
        // Feld auf kleinen Bildschirmen nicht mehr erreichbar. Die
        // Tastaturhöhe kommt deshalb als zusätzliches Polster unten dazu -
        // innerhalb des Scrollbereichs, damit man wirklich hinscrollen kann.
        final tastaturHoehe = MediaQuery.viewInsetsOf(context).bottom;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + tastaturHoehe),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Frage ${session.index + 1} von ${session.gesamtFragen}'
                      ' · ${frage.kategorie}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (zeigeSkip)
                    TextButton.icon(
                      onPressed: controller.ueberspringen,
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: Text(
                        bereitsUebersprungen
                            ? 'Endgültig überspringen'
                            : 'Überspringen',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.outline,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (bereitsUebersprungen)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiaryContainer.withAlpha(160),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.replay,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Übersprungene Frage – jetzt beantworten',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                frage.frage.replaceAllMapped(
                  RegExp(r'\{\{\d+\}\}'),
                  (_) => '___',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (frage.bildAsset != null) ...[
                const SizedBox(height: 12),
                if (TechnischeIllustration.istDiagramm(frage.bildAsset))
                  TechnischeIllustration(
                    diagrammKey: TechnischeIllustration.keyAus(
                      frage.bildAsset!,
                    ),
                  )
                else
                  Image.asset(frage.bildAsset!),
              ],
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey('${frage.id}-${session.antwort.phase}'),
                  child: switch (session.antwort.phase) {
                    FragePhase.antworten => AntwortEingabe(
                      frage: frage,
                      antwort: session.antwort,
                      modus: modus,
                    ),
                    FragePhase.konfidenz => KonfidenzAuswahl(modus: modus),
                    FragePhase.aufgedeckt => _AufdeckungsAnsicht(
                      frage: frage,
                      session: session,
                      modus: modus,
                    ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerAnzeige extends StatelessWidget {
  final TimerZustand timerZustand;
  const _TimerAnzeige({required this.timerZustand});

  @override
  Widget build(BuildContext context) {
    final pausiert = timerZustand.pausiert;
    final kritisch = !pausiert && timerZustand.verbleibend.inMinutes < 5;
    final farbe = pausiert ? Colors.orange : (kritisch ? Colors.red : null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pausiert ? Icons.pause_circle_outline : Icons.timer_outlined,
              size: 16,
              color: farbe,
            ),
            const SizedBox(width: 4),
            Text(
              pausiert ? 'PAUSE' : formatiereDauer(timerZustand.verbleibend),
              style: TextStyle(fontWeight: FontWeight.w600, color: farbe),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  const _PauseOverlay({required this.onResume});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onResume,
      child: Container(
        color: Colors.black.withAlpha(160),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'PAUSIERT',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tippen zum Fortsetzen',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AufdeckungsAnsicht extends ConsumerWidget {
  final Frage frage;
  final QuizSessionState session;
  final QuizModus modus;

  const _AufdeckungsAnsicht({
    required this.frage,
    required this.session,
    required this.modus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizSessionProvider(modus).notifier);
    final korrekt = session.antwort.korrekt ?? false;
    final istSim = modus.art == QuizArt.pruefungssimulation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              korrekt ? Icons.check_circle : Icons.cancel,
              color: korrekt ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              korrekt ? 'Richtig' : 'Falsch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Zuerst die Lösung, dann erst das Warum: Nach dem Aufdecken will
        // man wissen, was richtig gewesen wäre - nicht einen Absatz lesen.
        LoesungsAnsicht(frage: frage, antwort: session.antwort),

        _ErklaerungsAnsicht(frage: frage),
        if (!istSim && frage.schwierigkeit == 3) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Erkläre kurz, WARUM (optional, wird nicht bewertet)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: controller.selbsterklaerungSetzen,
          ),
        ],
        const SizedBox(height: 24),
        if (istSim) ...[
          ElevatedButton.icon(
            onPressed: () => controller.bewerten(Rating.good),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Weiter'),
          ),
        ] else ...[
          const Text('Wie gut wusstest du es?'),
          const SizedBox(height: 8),
          BewertungsButtons(onBewertet: controller.bewerten),
        ],
      ],
    );
  }
}

class _ZeichnungsViewer extends StatelessWidget {
  final PruefungsDefinition info;
  final Kurs kurs;
  const _ZeichnungsViewer({required this.info, required this.kurs});

  @override
  Widget build(BuildContext context) {
    final zeigeEchteZeichnungen = info.zeichnungen.isNotEmpty;
    final anzahl = zeigeEchteZeichnungen
        ? info.zeichnungen.length
        : info.diagrammKeys.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zeichnungen',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        info.titel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: anzahl,
              itemBuilder: (context, i) {
                final label = zeigeEchteZeichnungen
                    ? (info.zeichnungen[i].label.isNotEmpty
                          ? info.zeichnungen[i].label
                          : 'Zeichnung ${i + 1}')
                    : info.diagrammKeys[i].replaceAll('_', ' ').toUpperCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (zeigeEchteZeichnungen)
                        _EchtesZeichnungsBild(
                          pfad: info.zeichnungen[i].pfad,
                          kurs: kurs,
                          stueckliste: info.stueckliste,
                        )
                      else
                        TechnischeIllustration(
                          diagrammKey: info.diagrammKeys[i],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EchtesZeichnungsBild extends StatelessWidget {
  final String pfad;
  final Kurs kurs;
  final Map<String, String> stueckliste;
  const _EchtesZeichnungsBild({
    required this.pfad,
    required this.kurs,
    this.stueckliste = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Gebündelte Kurse liefern Assets, importierte echte Dateien.
    final quelle = KursBilder.fuer(kurs, pfad);
    if (quelle == null) {
      return _Platzhalter(pfad: pfad, stueckliste: stueckliste);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 6.0,
        child: Image(
          image: quelle,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              _Platzhalter(pfad: pfad, stueckliste: stueckliste),
        ),
      ),
    );
  }
}

// Fallback, solange die echte Zeichnungsdatei fehlt (siehe P8b): zeigt die
// Positionsnummern der Stückliste als Textliste, damit Fragen, die sich auf
// "Pos. X" beziehen, trotzdem lösbar sind.
class _Platzhalter extends StatelessWidget {
  final String pfad;
  final Map<String, String> stueckliste;
  const _Platzhalter({required this.pfad, this.stueckliste = const {}});

  @override
  Widget build(BuildContext context) {
    final dateiname = pfad.split('/').last;
    final positionen = stueckliste.entries.toList()
      ..sort(
        (a, b) =>
            (int.tryParse(a.key) ?? 0).compareTo(int.tryParse(b.key) ?? 0),
      );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(80),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  'Zeichnung noch nicht hinterlegt',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  dateiname,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          if (positionen.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Stückliste (aus den Fragetexten):',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            for (final eintrag in positionen)
              Text(
                'Pos. ${eintrag.key} = ${eintrag.value}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

/// Erklärung in zwei Stufen: knapper Kern, Rest auf Wunsch.
///
/// Die Erklärungen sind im Median 280 Zeichen lang - direkt nach dem
/// Aufdecken ist das mehr, als man in dem Moment lesen will. Der Aufklapper
/// erscheint nur, wenn es wirklich etwas zu vertiefen gibt: bei kurzer
/// Erklärung ohne Lösungsweg und ohne Bild bliebe er leer.
class _ErklaerungsAnsicht extends StatelessWidget {
  final Frage frage;

  const _ErklaerungsAnsicht({required this.frage});

  @override
  Widget build(BuildContext context) {
    final geteilt = teileErklaerung(
      frage.erklaerung,
      kurzerklaerung: frage.kurzerklaerung,
    );
    final hatBild = frage.bildAsset != null;
    final hatWeg = frage.workedExample != null;
    final zeigeAufklapper = geteilt.hatMehr || hatWeg || hatBild;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (geteilt.kurz.isNotEmpty) Text(geteilt.kurz),
        if (zeigeAufklapper) ...[
          const SizedBox(height: 4),
          Theme(
            // Ohne das zieht ExpansionTile eigene Trennlinien ein, die hier
            // mitten im Fließtext stören.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                'Ausführlich',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (geteilt.hatMehr) Text(geteilt.rest),
                if (hatWeg) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Lösungsweg',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(frage.workedExample!),
                ],
                if (hatBild) ...[
                  const SizedBox(height: 12),
                  _FrageBild(bildAsset: frage.bildAsset!),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bild oder Diagramm zu einer Frage, in beiden Phasen gleich dargestellt.
class _FrageBild extends ConsumerWidget {
  final String bildAsset;

  const _FrageBild({required this.bildAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (TechnischeIllustration.istDiagramm(bildAsset)) {
      return TechnischeIllustration(
        diagrammKey: TechnischeIllustration.keyAus(bildAsset),
      );
    }

    // Importierte Kurse legen ihre Bilder als Dateien ab, gebündelte als
    // Assets - KursBilder kennt den Unterschied.
    final kurs = ref.watch(aktivesPaketProvider).value?.kurs;
    final quelle = kurs == null ? null : KursBilder.fuer(kurs, bildAsset);
    if (quelle == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image(
        image: quelle,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
