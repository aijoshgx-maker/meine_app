// Metadaten zu jeder hochgeladenen schriftlichen IHK-Theorieprüfung.
//
// zeichnungsPfade / zeichnungsLabels: echte Bilddateien aus den
// Zeichnungsbeilagen der Prüfungen (PNG/JPG, in assets/zeichnungen/<id>/).
// Solange eine Datei noch nicht hinterlegt ist, zeigt der Viewer einen
// Platzhalter. DiagrammKeys (CustomPainter) dienen als Ergänzung/Fallback.
class PruefungsInfo {
  final String id;
  final String bezeichnung;
  final String pruefungsJahr;
  final int zeitlimitMinuten;
  final List<String> zeichnungsPfade;
  final List<String> zeichnungsLabels;
  final List<String> diagrammKeys;
  final String beschreibung;

  const PruefungsInfo({
    required this.id,
    required this.bezeichnung,
    required this.pruefungsJahr,
    required this.zeitlimitMinuten,
    required this.zeichnungsPfade,
    required this.zeichnungsLabels,
    required this.diagrammKeys,
    required this.beschreibung,
  });
}

class PruefungsMetadaten {
  static const List<PruefungsInfo> alle = [
    PruefungsInfo(
      id: 'W22',
      bezeichnung: 'AP2 Winter 2022/23',
      pruefungsJahr: 'Winter 2022/23',
      zeitlimitMinuten: 120,
      zeichnungsPfade: [
        'assets/zeichnungen/W22/zeichnung_1.png',
        'assets/zeichnungen/W22/zeichnung_2.png',
        'assets/zeichnungen/W22/zeichnung_3.png',
        'assets/zeichnungen/W22/zeichnung_4.png',
      ],
      zeichnungsLabels: [
        'AKP-250 – Längsschnitt Axialkolbenpumpe',
        'Steuerblock – Hydraulikplan',
        'Verzinkungsanlage – GRAFCET-Steuerung',
        'Maßzeichnung / Toleranzangaben',
      ],
      diagrammKeys: [
        'hydraulik_kolben',
        'grafcet_basis',
        'pneumatik_52_ventil',
        'passungsdiagramm',
        'schnittdaten',
      ],
      beschreibung:
          'Axialkolbenpumpe (AKP-250), automatische Verzinkungsanlage. '
          'Themen: Hydraulik, GRAFCET, Lagerung, Fertigungstechnik, WiSo.',
    ),
    PruefungsInfo(
      id: 'S17',
      bezeichnung: 'AP2 Sommer 2017',
      pruefungsJahr: 'Sommer 2017',
      zeitlimitMinuten: 120,
      zeichnungsPfade: [
        'assets/zeichnungen/S17/zeichnung_1.png',
        'assets/zeichnungen/S17/zeichnung_2.png',
        'assets/zeichnungen/S17/zeichnung_3.png',
      ],
      zeichnungsLabels: [
        'Einstellantrieb Stanzanlage – Schnittdarstellung',
        'Kegelradgetriebe – Bemaßung (m=2, z=26)',
        'Bogenzahnkupplung / Gelenkwelle',
      ],
      diagrammKeys: [
        'zahnrad_geometrie',
        'werkzeugwinkel',
        'toleranzfeld',
        'kraeftedreieck',
        'passungsdiagramm',
      ],
      beschreibung:
          'Einstellantrieb Stanzanlage, Kegelradgetriebe (m=2, z=26), '
          'Bogenzahnkupplung, Gelenkwelle. Themen: Maschinenelemente, '
          'Berechnung, Instandhaltung, WiSo.',
    ),
    PruefungsInfo(
      id: 'S19',
      bezeichnung: 'AP2 Sommer 2019',
      pruefungsJahr: 'Sommer 2019',
      zeitlimitMinuten: 120,
      zeichnungsPfade: [
        'assets/zeichnungen/S19/zeichnung_1.png',
        'assets/zeichnungen/S19/zeichnung_2.png',
        'assets/zeichnungen/S19/zeichnung_3.png',
        'assets/zeichnungen/S19/zeichnung_4.png',
      ],
      zeichnungsLabels: [
        'Mehrspindel-Bohrstation – Gesamtansicht',
        'Schieberadgetriebe – Schnittbild (Stufe 1: z=66/18, Stufe 2: z=33/33)',
        'Kegelrollenlager – O-Anordnung Spindellagerung',
        'Spannzylinder (Ø80mm) – Hydraulikschaltplan',
      ],
      diagrammKeys: [
        'zahnrad_geometrie',
        'hydraulik_kolben',
        'passungsdiagramm',
        'schnittdaten',
        'toleranzfeld',
      ],
      beschreibung:
          'Mehrspindel-Bohrstation, 2-stufiges Schieberadgetriebe '
          '(z=66/18, z=33/33), Kegelrollenlager O-Anordnung, '
          'Spannzylinder (Ø80mm). Themen: Getriebe, Lagerung, Hydraulik, WiSo.',
    ),
    PruefungsInfo(
      id: 'S18',
      bezeichnung: 'AP2 Sommer 2018',
      pruefungsJahr: 'Sommer 2018',
      zeitlimitMinuten: 120,
      zeichnungsPfade: [
        'assets/zeichnungen/S18/zeichnung_1.png',
        'assets/zeichnungen/S18/zeichnung_2.png',
        'assets/zeichnungen/S18/zeichnung_3.png',
      ],
      zeichnungsLabels: [
        'Schaltvorrichtung – Schnittdarstellung (Kolben CuSnB, Ø80mm)',
        'Verladeanlage – Übersichtsschema mit Bauteilbeschriftung',
        'Schaltvorrichtung – Zahnräder (Primär m=3/z=57, Sekundär m=3/z=82)',
      ],
      diagrammKeys: [
        'hydraulik_kolben',
        'zahnrad_geometrie',
        'grafcet_basis',
        'toleranzfeld',
        'werkzeugwinkel',
      ],
      beschreibung:
          'Hydraulische Schaltvorrichtung, Verladeanlage für Betonteile. '
          'Primärrad (m=3, z=57), Sekundärrad (m=3, z=82), Kolben (CuSnB, '
          'Ø80mm, p=6bar). Themen: Hydraulik, Zahnräder, Werkstoff, WiSo.',
    ),
  ];

  static PruefungsInfo fuerId(String id) =>
      alle.firstWhere((p) => p.id == id);
}
