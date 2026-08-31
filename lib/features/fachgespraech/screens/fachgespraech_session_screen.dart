import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/matching/antwort_matcher.dart';
import '../../../core/sprache/spracheingabe.dart';
import '../../../models/fachgespraech_szenario.dart';
import '../../quiz/widgets/illustrationen/technische_illustration.dart';
import '../providers/fachgespraech_provider.dart';

class FachgespraechSessionScreen extends ConsumerStatefulWidget {
  final String szenarioId;

  const FachgespraechSessionScreen({super.key, required this.szenarioId});

  @override
  ConsumerState<FachgespraechSessionScreen> createState() =>
      _FachgespraechSessionScreenState();
}

class _FachgespraechSessionScreenState
    extends ConsumerState<FachgespraechSessionScreen> {
  int _frageIndex = 0;
  bool _antwortetGegeben = false;
  bool _fertig = false;
  final TextEditingController _antwortCtrl = TextEditingController();
  final List<_FrageErgebnis> _ergebnisse = [];

  @override
  void dispose() {
    _antwortCtrl.dispose();
    super.dispose();
  }

  void _antwortBestaetigen(FachgespraechFrage frage) {
    final antwort = _antwortCtrl.text.trim();
    // Tokenweises Matching statt reinem Teilstring-Vergleich: bei
    // Mehrwort-Schlüsselwörtern ("Stöße dämpfen") müssen alle Wörter
    // vorkommen, Reihenfolge egal - und über denselben Normalisierer wie
    // Kurzantwort/Lückentext (Umlaute, Bindestriche, o.ä.), siehe P7a/P7b.
    final gefundeneSchluesselbegriffe = frage.schluesselwoerter
        .where((k) => AntwortMatcher.keywordGefunden(antwort, k))
        .toList();

    _ergebnisse.add(
      _FrageErgebnis(
        frage: frage,
        nutzerAntwort: antwort,
        gefundeneSchluesselbegriffe: gefundeneSchluesselbegriffe,
      ),
    );

    setState(() => _antwortetGegeben = true);
  }

  void _naechsteFrage(int gesamtFragen) {
    if (_frageIndex + 1 >= gesamtFragen) {
      setState(() => _fertig = true);
    } else {
      setState(() {
        _frageIndex++;
        _antwortetGegeben = false;
        _antwortCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final szenarien = ref.watch(fachgespraechSzenarienProvider);

    return szenarien.when(
      data: (list) {
        final szenario = list
            .where((s) => s.id == widget.szenarioId)
            .firstOrNull;
        if (szenario == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Fachgespräch'),
              leading: BackButton(onPressed: () => context.go('/')),
            ),
            body: const Center(child: Text('Szenario nicht gefunden.')),
          );
        }

        if (_fertig) return _buildAbschluss(context, szenario);

        final frage = szenario.fragen[_frageIndex];
        final gesamt = szenario.fragen.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(szenario.titel),
            leading: BackButton(onPressed: () => context.go('/')),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (_frageIndex + (_antwortetGegeben ? 1 : 0)) / gesamt,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    'Frage ${_frageIndex + 1} / $gesamt',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AuftragskarteMini(szenario: szenario),
              if (TechnischeIllustration.istDiagramm(frage.bildAsset))
                TechnischeIllustration(
                  diagrammKey: TechnischeIllustration.keyAus(frage.bildAsset!),
                ),
              const SizedBox(height: 16),
              _PrueferBubble(text: frage.pruefer),
              const SizedBox(height: 16),
              if (!_antwortetGegeben) ...[
                _AntwortEingabe(
                  controller: _antwortCtrl,
                  onBestaetigen: () => _antwortBestaetigen(frage),
                ),
              ] else ...[
                _NutzerAntwortBubble(text: _antwortCtrl.text),
                const SizedBox(height: 16),
                _MusterloesungKarte(
                  ergebnis: _ergebnisse.last,
                  onWeiter: () => _naechsteFrage(gesamt),
                  istLetztes: _frageIndex + 1 >= gesamt,
                ),
              ],
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fehler: $e'))),
    );
  }

  Widget _buildAbschluss(BuildContext context, FachgespraechSzenario szenario) {
    final treffer = _ergebnisse
        .where((e) => e.gefundeneSchluesselbegriffe.isNotEmpty)
        .length;
    final gesamt = _ergebnisse.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Abschluss: ${szenario.titel}'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Fachgespräch abgeschlossen!',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$treffer / $gesamt Fragen mit Schlüsselbegriffen beantwortet',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_ergebnisse.length, (i) {
            final e = _ergebnisse[i];
            final ok = e.gefundeneSchluesselbegriffe.isNotEmpty;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(
                  ok ? Icons.check_circle : Icons.info_outline,
                  color: ok ? Colors.green : Colors.orange,
                ),
                title: Text(
                  'Frage ${i + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  e.frage.pruefer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ihre Antwort:',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          e.nutzerAntwort.isEmpty
                              ? '(keine Antwort)'
                              : e.nutzerAntwort,
                        ),
                        const Divider(),
                        Text(
                          'Musterlösung:',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(e.frage.musterloesung),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: e.frage.schluesselwoerter.map((k) {
                            final found = e.gefundeneSchluesselbegriffe
                                .contains(k);
                            return Chip(
                              label: Text(k),
                              backgroundColor: found
                                  ? Colors.green.withAlpha(40)
                                  : Colors.red.withAlpha(25),
                              avatar: Icon(
                                found ? Icons.check : Icons.close,
                                size: 14,
                                color: found ? Colors.green : Colors.red,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _frageIndex = 0;
              _antwortetGegeben = false;
              _fertig = false;
              _antwortCtrl.clear();
              _ergebnisse.clear();
            }),
            icon: const Icon(Icons.replay),
            label: const Text('Nochmal üben'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
            label: const Text('Zum Hauptmenü'),
          ),
        ],
      ),
    );
  }
}

class _AuftragskarteMini extends StatelessWidget {
  final FachgespraechSzenario szenario;
  const _AuftragskarteMini({required this.szenario});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      dense: true,
      title: const Text('Fertigungsauftrag'),
      subtitle: Text(
        szenario.fertigungsauftrag,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                szenario.kontext,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                szenario.fertigungsauftrag,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrueferBubble extends StatelessWidget {
  final String text;
  const _PrueferBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: cs.secondary,
          radius: 18,
          child: Icon(Icons.person, color: cs.onSecondary, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prüfer',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: cs.onSecondaryContainer)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NutzerAntwortBubble extends StatelessWidget {
  final String text;
  const _NutzerAntwortBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ihre Antwort',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text.isEmpty ? '(keine Antwort eingegeben)' : text,
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: cs.primary,
          radius: 18,
          child: Icon(Icons.school, color: cs.onPrimary, size: 18),
        ),
      ],
    );
  }
}

/// Eingabefeld mit Diktierknopf.
///
/// Ein Fachgespraech wird gesprochen gefuehrt. Eine Antwort zu formulieren
/// und laut auszusprechen ist eine andere Uebung als sie zu tippen - und
/// naeher an dem, was in der Pruefung verlangt wird. Die Tastatur bleibt
/// gleichberechtigt daneben: Nicht jedes Geraet kann Spracherkennung, und
/// nicht ueberall kann man laut sprechen.
class _AntwortEingabe extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback onBestaetigen;

  const _AntwortEingabe({
    required this.controller,
    required this.onBestaetigen,
  });

  @override
  ConsumerState<_AntwortEingabe> createState() => _AntwortEingabeState();
}

class _AntwortEingabeState extends ConsumerState<_AntwortEingabe> {
  /// In einem Feld gehalten, nicht bei jedem Zugriff neu gelesen: In
  /// dispose() ist `ref` nicht mehr benutzbar, die laufende Aufnahme muss
  /// dort aber noch gestoppt werden.
  late final Spracheingabe _sprache;

  bool _hoert = false;

  /// Was im Feld stand, als die Aufnahme begann.
  ///
  /// Die Erkennung liefert immer den gesamten erkannten Text, nicht nur das
  /// Neue. Ohne diesen Merkpunkt wuerde jede Zwischenmeldung eine bereits
  /// getippte Antwort ueberschreiben.
  String _basis = '';

  @override
  void initState() {
    super.initState();
    _sprache = ref.read(spracheingabeProvider);
  }

  @override
  void dispose() {
    // Ohne das liefe die Aufnahme weiter, wenn man die Frage verlaesst.
    if (_hoert) _sprache.stoppen();
    super.dispose();
  }

  Future<void> _umschalten() async {
    final sprache = _sprache;

    if (_hoert) {
      await sprache.stoppen();
      if (mounted) setState(() => _hoert = false);
      return;
    }

    // Erst hier, nicht beim App-Start: Der Berechtigungsdialog gehoert an
    // die Stelle, an der man das Mikrofon auch benutzen will.
    final bereit = await sprache.vorbereiten();
    if (!mounted) return;
    if (!bereit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Spracheingabe ist auf diesem Gerät nicht verfügbar. '
            'Du kannst deine Antwort tippen.',
          ),
        ),
      );
      return;
    }

    _basis = widget.controller.text.trimRight();
    setState(() => _hoert = true);

    await sprache.starten(
      onText: (text, endgueltig) {
        if (!mounted) return;
        final trenner = _basis.isEmpty ? '' : ' ';
        widget.controller.text = '$_basis$trenner$text';
        widget.controller.selection = TextSelection.collapsed(
          offset: widget.controller.text.length,
        );
      },
      onEnde: () {
        if (mounted) setState(() => _hoert = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final farben = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            hintText: _hoert
                ? 'Sprich jetzt …'
                : 'Ihre Antwort hier eingeben oder diktieren...',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Waehrend der Aufnahme fuellt der Knopf sich farbig - ein
            // laufendes Mikrofon muss man sehen koennen, ohne hinzuhoeren.
            Expanded(
              child: _hoert
                  ? FilledButton.icon(
                      onPressed: _umschalten,
                      style: FilledButton.styleFrom(
                        backgroundColor: farben.error,
                        foregroundColor: farben.onError,
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('Aufnahme beenden'),
                    )
                  : OutlinedButton.icon(
                      onPressed: _umschalten,
                      icon: const Icon(Icons.mic_none),
                      label: const Text('Antwort diktieren'),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _hoert ? null : widget.onBestaetigen,
          icon: const Icon(Icons.send),
          label: const Text('Antwort bestätigen'),
        ),
      ],
    );
  }
}

class _MusterloesungKarte extends StatelessWidget {
  final _FrageErgebnis ergebnis;
  final VoidCallback onWeiter;
  final bool istLetztes;

  const _MusterloesungKarte({
    required this.ergebnis,
    required this.onWeiter,
    required this.istLetztes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gefunden = ergebnis.gefundeneSchluesselbegriffe;
    final alle = ergebnis.frage.schluesselwoerter;

    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Musterlösung', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(ergebnis.frage.musterloesung),
            const Divider(height: 24),
            Text(
              'Schlüsselbegriffe',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: alle.map((k) {
                final ok = gefunden.contains(k);
                return Chip(
                  label: Text(k),
                  avatar: Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: ok ? Colors.green : Colors.orange,
                  ),
                  backgroundColor: ok
                      ? Colors.green.withAlpha(30)
                      : Colors.orange.withAlpha(25),
                );
              }).toList(),
            ),
            if (ergebnis.frage.erklaerung.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Erklärung', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                ergebnis.frage.erklaerung,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onWeiter,
                icon: Icon(istLetztes ? Icons.flag : Icons.arrow_forward),
                label: Text(
                  istLetztes ? 'Fachgespräch beenden' : 'Nächste Frage',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrageErgebnis {
  final FachgespraechFrage frage;
  final String nutzerAntwort;
  final List<String> gefundeneSchluesselbegriffe;

  const _FrageErgebnis({
    required this.frage,
    required this.nutzerAntwort,
    required this.gefundeneSchluesselbegriffe,
  });
}
