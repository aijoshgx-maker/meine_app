import 'package:flutter/material.dart';

import '../../../models/frage.dart';
import '../providers/quiz_providers.dart';

/// Zeigt nach dem Aufdecken, was richtig gewesen wäre - und bei einer
/// falschen Antwort daneben, was man selbst eingetragen hat.
///
/// Vorher stand hier nur der Erklärungstext. Bei Zuordnungen, Lückentexten
/// und Reihenfolgen musste man sich die Lösung daraus zusammenreimen; bei
/// `multi` sah man nicht, welche Option man übersehen hatte. Genau das ist
/// aber der Moment, in dem man es wissen will.
///
/// Die Lösung erscheint auch bei richtiger Antwort: Gerade bei `multi` und
/// `zuordnung` bestätigt sie, dass man aus den richtigen Gründen richtig
/// lag - und nicht mit einem glücklichen Treffer.
class LoesungsAnsicht extends StatelessWidget {
  final Frage frage;
  final AntwortZustand antwort;

  const LoesungsAnsicht({
    super.key,
    required this.frage,
    required this.antwort,
  });

  bool get _korrekt => antwort.korrekt == true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final zeilen = _zeilen(context);
    if (zeilen.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _korrekt
          ? cs.surfaceContainerLow
          : cs.errorContainer.withAlpha(60),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lösung',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            ...zeilen,
          ],
        ),
      ),
    );
  }

  List<Widget> _zeilen(BuildContext context) {
    switch (frageTypVon(frage.typ)) {
      case FrageTyp.single:
      case FrageTyp.multi:
        return _auswahl(context);
      case FrageTyp.wahrfalsch:
        return [_LoesungsZeile(text: _wahrfalschText())];
      case FrageTyp.rechnung:
        return _rechnung(context);
      case FrageTyp.kurzantwort:
        return _kurzantwort(context);
      case FrageTyp.lueckentext:
        return _luecken(context);
      case FrageTyp.zuordnung:
        return _zuordnung(context);
      case FrageTyp.reihenfolge:
        return _reihenfolge(context);
    }
  }

  // --- single / multi -----------------------------------------------------

  List<Widget> _auswahl(BuildContext context) {
    final richtige = frage.richtigeIndizes.toSet();
    final gewaehlt = antwort.ausgewaehlteIndizes;

    return [
      for (var i = 0; i < frage.optionen.length; i++)
        if (richtige.contains(i) || gewaehlt.contains(i))
          _LoesungsZeile(
            text: frage.optionen[i],
            // Falsch angekreuzt: durchgestrichen, damit der Unterschied ohne
            // Farbsehen erkennbar bleibt.
            durchgestrichen: !richtige.contains(i),
            zustand: richtige.contains(i)
                ? _Zustand.richtig
                : _Zustand.falschGewaehlt,
          ),
    ];
  }

  String _wahrfalschText() {
    // Neues Format über frage.wahr, altes über richtigeIndizes mit
    // optionen ["Wahr", "Falsch"] - beide werden weiter unterstützt.
    final wahr =
        frage.wahr ??
        (frage.richtigeIndizes.isNotEmpty && frage.richtigeIndizes.first == 1);
    return wahr ? 'Wahr' : 'Falsch';
  }

  // --- rechnung -----------------------------------------------------------

  List<Widget> _rechnung(BuildContext context) {
    final einheit = frage.einheit == null ? '' : ' ${frage.einheit}';
    final wert = frage.loesungswert;

    return [
      _LoesungsZeile(
        text: wert == null ? '—' : '${_zahl(wert)}$einheit',
        zustand: _Zustand.richtig,
      ),
      if (frage.toleranz != null && frage.toleranz! > 0)
        _Nebenzeile(text: 'zulässige Abweichung ± ${_zahl(frage.toleranz!)}'),
      if (!_korrekt && antwort.freitext.trim().isNotEmpty)
        _LoesungsZeile(
          text: '${antwort.freitext.trim()}$einheit',
          vorsatz: 'deine Eingabe: ',
          zustand: _Zustand.falschGewaehlt,
        ),
    ];
  }

  /// Kommastelle nur wenn nötig - "60" liest sich besser als "60.0".
  String _zahl(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toString();

  // --- kurzantwort --------------------------------------------------------

  List<Widget> _kurzantwort(BuildContext context) {
    final akzeptiert = frage.akzeptierteKurzantworten;
    if (akzeptiert.isEmpty) return const [];

    return [
      _LoesungsZeile(text: akzeptiert.first, zustand: _Zustand.richtig),
      if (akzeptiert.length > 1)
        _Nebenzeile(text: 'auch richtig: ${akzeptiert.skip(1).join(' · ')}'),
      if (!_korrekt && antwort.freitext.trim().isNotEmpty)
        _LoesungsZeile(
          text: antwort.freitext.trim(),
          vorsatz: 'deine Antwort: ',
          zustand: _Zustand.falschGewaehlt,
        ),
    ];
  }

  // --- lueckentext --------------------------------------------------------

  List<Widget> _luecken(BuildContext context) {
    final zeilen = <Widget>[];

    for (var i = 0; i < frage.luecken.length; i++) {
      final erwartet = frage.luecken[i];
      if (erwartet.isEmpty) continue;

      final eigene = (antwort.lueckenAntworten[i] ?? '').trim();
      final passt = erwartet.any(
        (e) => e.toLowerCase() == eigene.toLowerCase(),
      );

      zeilen.add(
        _LoesungsZeile(
          text: erwartet.first,
          vorsatz: 'Lücke ${i + 1}: ',
          zustand: _Zustand.richtig,
        ),
      );
      // Die eigene Eingabe nur dort, wo sie abweicht - sonst wird die
      // Lösung von Wiederholungen zugestellt.
      if (!passt && eigene.isNotEmpty) {
        zeilen.add(_Nebenzeile(text: 'du: $eigene', abweichung: true));
      }
    }
    return zeilen;
  }

  // --- zuordnung ----------------------------------------------------------

  List<Widget> _zuordnung(BuildContext context) {
    if (frage.paare.isEmpty) return const [];

    return [
      for (var i = 0; i < frage.paare.length; i++) ...[
        _LoesungsZeile(
          text: '${frage.paare[i].links}  →  ${frage.paare[i].rechts}',
          zustand: _Zustand.richtig,
        ),
        if (antwort.zuordnungsAuswahl[i] != null &&
            antwort.zuordnungsAuswahl[i] != i)
          _Nebenzeile(
            text: 'du: ${frage.paare[antwort.zuordnungsAuswahl[i]!].rechts}',
            abweichung: true,
          ),
      ],
    ];
  }

  // --- reihenfolge --------------------------------------------------------

  List<Widget> _reihenfolge(BuildContext context) {
    final soll = frage.reihenfolge;
    if (soll.isEmpty) return const [];

    return [
      for (var platz = 0; platz < soll.length; platz++)
        if (soll[platz] < frage.optionen.length)
          _LoesungsZeile(
            text: frage.optionen[soll[platz]],
            vorsatz: '${platz + 1}. ',
            zustand: _Zustand.richtig,
          ),
    ];
  }
}

enum _Zustand { richtig, falschGewaehlt }

class _LoesungsZeile extends StatelessWidget {
  final String text;
  final String? vorsatz;
  final bool durchgestrichen;
  final _Zustand zustand;

  const _LoesungsZeile({
    required this.text,
    this.vorsatz,
    this.durchgestrichen = false,
    this.zustand = _Zustand.richtig,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final falsch = zustand == _Zustand.falschGewaehlt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(
              falsch ? Icons.close : Icons.check,
              size: 16,
              color: falsch ? cs.error : Colors.green,
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (vorsatz != null)
                    TextSpan(
                      text: vorsatz,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontWeight: falsch ? FontWeight.normal : FontWeight.w600,
                      decoration: durchgestrichen
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zusatzangabe unter einer Lösungszeile - Toleranz, weitere Schreibweisen
/// oder die abweichende eigene Eingabe.
class _Nebenzeile extends StatelessWidget {
  final String text;
  final bool abweichung;

  const _Nebenzeile({required this.text, this.abweichung = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: abweichung ? cs.error : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
