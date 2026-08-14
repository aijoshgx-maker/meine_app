import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../quiz/providers/quiz_modus.dart';

// Auswahlscreen: alle 34 Lernfeld-Kategorien, gruppiert nach Bereich.
// Antippen startet eine Quiz-Session nur mit Fragen dieses Themas.
class ThemenAuswahlScreen extends StatelessWidget {
  const ThemenAuswahlScreen({super.key});

  static const _bereiche = [
    _Bereich(
      id: 'auftragsanalyse',
      titel: 'Auftrags- & Funktionsanalyse',
      icon: Icons.engineering,
      kategorien: [
        'Technisches Zeichnen',
        'Toleranzen & Passungen',
        'Form- & Lagetoleranzen',
        'Funktionsanalyse',
        'Maschinenelemente',
        'Antriebstechnik (mechanisch)',
        'Pneumatik',
        'Hydraulik',
        'Steuerung & Regelung',
        'Elektrotechnik & Sensorik',
        'Werkstoffkunde',
        'Instandhaltung',
        'Technische Berechnungen',
      ],
    ),
    _Bereich(
      id: 'fertigungstechnik',
      titel: 'Fertigungstechnik',
      icon: Icons.precision_manufacturing,
      kategorien: [
        'Zerspanung Grundlagen',
        'Schnittdaten',
        'Werkzeuge & Schneidstoffe',
        'CNC-Grundlagen',
        'Fertigungs- und Arbeitsplanung',
        'Fügeverfahren',
        'Umformen & Trennen',
        'Mess- & Prüftechnik',
        'Qualitätssicherung',
        'Werkstoffe und Wärmebehandlung',
        'Wirtschaftliche Fertigung',
      ],
    ),
    _Bereich(
      id: 'wiso',
      titel: 'Wirtschafts- & Sozialkunde',
      icon: Icons.account_balance,
      kategorien: [
        'Berufsausbildung & BBiG',
        'Arbeitsvertrag, Rechte & Pflichten',
        'Tarifrecht',
        'Sozialversicherung',
        'Entgelt',
        'Betriebsorganisation',
        'Markt und Preisbildung',
        'Kaufvertrag',
        'Wirtschaftskreislauf',
        'Verbraucherschutz',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thema vertiefen'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final bereich in _bereiche) ...[
            _BereichHeader(bereich: bereich),
            const SizedBox(height: 4),
            for (final kategorie in bereich.kategorien)
              _KategorieKarte(
                kategorie: kategorie,
                bereichTitel: bereich.titel,
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Bereich {
  final String id;
  final String titel;
  final IconData icon;
  final List<String> kategorien;
  const _Bereich({
    required this.id,
    required this.titel,
    required this.icon,
    required this.kategorien,
  });
}

class _BereichHeader extends StatelessWidget {
  final _Bereich bereich;
  const _BereichHeader({required this.bereich});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(bereich.icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            bereich.titel,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _KategorieKarte extends StatelessWidget {
  final String kategorie;
  final String bereichTitel;
  const _KategorieKarte({required this.kategorie, required this.bereichTitel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        title: Text(kategorie),
        trailing: const Icon(Icons.play_arrow_rounded, size: 20),
        onTap: () => context.go(
          '/quiz',
          extra: QuizModus.themenVertiefung(kategorie: kategorie),
        ),
      ),
    );
  }
}
