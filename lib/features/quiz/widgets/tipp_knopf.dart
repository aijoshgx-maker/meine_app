import 'package:flutter/material.dart';

import '../../../models/glossar.dart';

/// Erklärt Formelzeichen und schwierige Begriffe aus dem Fragetext.
///
/// Wer an einer Aufgabe hängt, weil ihm `ω` nichts sagt, hat keine
/// Wissenslücke im Thema — er kann die Frage nur nicht lesen. Das eine löst
/// Üben, das andere ein Nachschlagewerk.
///
/// Bewusst ein Knopf und keine unterstrichenen Wörter im Fragetext:
/// Markierungen mitten im Satz lenken beim Lesen ab, und bei Lückentexten
/// kollidieren sie mit den `___`-Markierungen.
///
/// Auch im Testlauf verfügbar — in der echten AP2 ist ein Tabellenbuch
/// zugelassen, ein Nachschlagewerk auszublenden wäre also unrealistischer.
class TippKnopf extends StatelessWidget {
  final List<GlossarEintrag> eintraege;

  const TippKnopf({super.key, required this.eintraege});

  @override
  Widget build(BuildContext context) {
    if (eintraege.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _oeffnen(context),
        icon: const Icon(Icons.lightbulb_outline, size: 18),
        label: Text(
          eintraege.length == 1
              ? 'Tipp'
              : 'Tipp (${eintraege.length} Begriffe)',
        ),
        style: TextButton.styleFrom(
          foregroundColor: cs.secondary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  void _oeffnen(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (blatt) => _TippBlatt(eintraege: eintraege),
    );
  }
}

class _TippBlatt extends StatelessWidget {
  final List<GlossarEintrag> eintraege;

  const _TippBlatt({required this.eintraege});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'In dieser Frage',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Erklärt, was gemeint ist — nicht die Antwort.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Divider(height: 1),
        // Flexible statt fester Höhe: Bei einem Begriff bleibt das Blatt
        // niedrig, bei vielen wird es scrollbar statt überzulaufen.
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: eintraege.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 20),
            itemBuilder: (_, i) => _TippEintrag(eintrag: eintraege[i]),
          ),
        ),
      ],
    );
  }
}

class _TippEintrag extends StatelessWidget {
  final GlossarEintrag eintrag;

  const _TippEintrag({required this.eintrag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mehr = eintrag.mehr;

    final kopf = Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eintrag.begriff,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(eintrag.kurz),
        ],
      ),
    );

    if (mehr == null || mehr.trim().isEmpty) {
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: kopf);
    }

    return Theme(
      // Ohne das zieht ExpansionTile eigene Trennlinien ein, die hier mit
      // den Trennern zwischen den Einträgen kollidieren.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: kopf,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        controlAffinity: ListTileControlAffinity.trailing,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(mehr, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
