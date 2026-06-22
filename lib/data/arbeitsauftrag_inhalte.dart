// Statische Inhalte für den Arbeitsauftrag-Screen (Checkliste + Fachgespräch).
// Generisch/IHK-Stil verfasst, keine offizielle Quelle – frei editierbar.

enum ArbeitsauftragPhase { information, planung, durchfuehrung, kontrolle }

class ChecklistenEintrag {
  final String id;
  final ArbeitsauftragPhase phase;
  final String text;

  const ChecklistenEintrag({
    required this.id,
    required this.phase,
    required this.text,
  });
}

const checklistenEintraege = [
  ChecklistenEintrag(
    id: 'info-1',
    phase: ArbeitsauftragPhase.information,
    text: 'Arbeitsauftrag vollständig gelesen',
  ),
  ChecklistenEintrag(
    id: 'info-2',
    phase: ArbeitsauftragPhase.information,
    text: 'Zeichnungen/Stücklisten/Datenblätter beschafft',
  ),
  ChecklistenEintrag(
    id: 'info-3',
    phase: ArbeitsauftragPhase.information,
    text: 'Benötigte Werkzeuge/Maschinen identifiziert',
  ),
  ChecklistenEintrag(
    id: 'info-4',
    phase: ArbeitsauftragPhase.information,
    text: 'Arbeitsschutz-/Sicherheitsanforderungen geprüft',
  ),
  ChecklistenEintrag(
    id: 'info-5',
    phase: ArbeitsauftragPhase.information,
    text: 'Kundenwunsch/Zielzustand geklärt',
  ),
  ChecklistenEintrag(
    id: 'plan-1',
    phase: ArbeitsauftragPhase.planung,
    text: 'Arbeitsschritte in sinnvoller Reihenfolge geplant',
  ),
  ChecklistenEintrag(
    id: 'plan-2',
    phase: ArbeitsauftragPhase.planung,
    text: 'Zeitbedarf geschätzt',
  ),
  ChecklistenEintrag(
    id: 'plan-3',
    phase: ArbeitsauftragPhase.planung,
    text: 'Material-/Werkzeugbedarf festgelegt',
  ),
  ChecklistenEintrag(
    id: 'plan-4',
    phase: ArbeitsauftragPhase.planung,
    text: 'Qualitätskriterien/Toleranzen definiert',
  ),
  ChecklistenEintrag(
    id: 'plan-5',
    phase: ArbeitsauftragPhase.planung,
    text: 'Risiken/mögliche Probleme identifiziert',
  ),
  ChecklistenEintrag(
    id: 'durch-1',
    phase: ArbeitsauftragPhase.durchfuehrung,
    text: 'Arbeitsschritte gemäß Plan umgesetzt',
  ),
  ChecklistenEintrag(
    id: 'durch-2',
    phase: ArbeitsauftragPhase.durchfuehrung,
    text: 'Zwischenkontrollen während der Bearbeitung durchgeführt',
  ),
  ChecklistenEintrag(
    id: 'durch-3',
    phase: ArbeitsauftragPhase.durchfuehrung,
    text: 'Abweichungen vom Plan dokumentiert',
  ),
  ChecklistenEintrag(
    id: 'durch-4',
    phase: ArbeitsauftragPhase.durchfuehrung,
    text: 'Arbeitsschutz eingehalten',
  ),
  ChecklistenEintrag(
    id: 'durch-5',
    phase: ArbeitsauftragPhase.durchfuehrung,
    text: 'Maschinen/Werkzeuge korrekt eingesetzt',
  ),
  ChecklistenEintrag(
    id: 'kontroll-1',
    phase: ArbeitsauftragPhase.kontrolle,
    text: 'Ergebnis gegen Vorgaben/Zeichnung geprüft',
  ),
  ChecklistenEintrag(
    id: 'kontroll-2',
    phase: ArbeitsauftragPhase.kontrolle,
    text: 'Maße/Funktionen kontrolliert',
  ),
  ChecklistenEintrag(
    id: 'kontroll-3',
    phase: ArbeitsauftragPhase.kontrolle,
    text: 'Mängel dokumentiert und behoben',
  ),
  ChecklistenEintrag(
    id: 'kontroll-4',
    phase: ArbeitsauftragPhase.kontrolle,
    text: 'Arbeitsplatz aufgeräumt/Werkzeuge zurückgegeben',
  ),
  ChecklistenEintrag(
    id: 'kontroll-5',
    phase: ArbeitsauftragPhase.kontrolle,
    text: 'Auftrag als abgeschlossen dokumentiert',
  ),
];

const dokumentationsFelder = [
  ('auftragsbeschreibung', 'Auftragsbeschreibung'),
  ('zielsetzung', 'Zielsetzung'),
  ('vorgehensweise', 'Vorgehensweise / Lösungsweg'),
  ('werkzeugeMaterialien', 'Eingesetzte Werkzeuge/Materialien'),
  ('ergebnis', 'Ergebnis'),
  ('reflexion', 'Reflexion'),
];

const fachgespraechFragen = [
  (
    'fg-1',
    'Warum haben Sie sich für dieses Verfahren/diese Vorgehensweise entschieden?',
  ),
  ('fg-2', 'Welche Alternativen gab es, und warum wurden sie verworfen?'),
  (
    'fg-3',
    'Welche Werkzeuge/Maschinen haben Sie eingesetzt und warum genau diese?',
  ),
  ('fg-4', 'Wie haben Sie die Maßhaltigkeit/Qualität sichergestellt?'),
  ('fg-5', 'Welche Probleme sind aufgetreten, und wie haben Sie diese gelöst?'),
  (
    'fg-6',
    'Welche Sicherheitsvorkehrungen waren bei diesem Auftrag zu beachten?',
  ),
  (
    'fg-7',
    'Wie lange haben die einzelnen Arbeitsschritte gedauert, und war das wie geplant?',
  ),
  ('fg-8', 'Was würden Sie beim nächsten Mal anders machen?'),
  ('fg-9', 'Welche Kosten (Material/Zeit) sind bei diesem Auftrag entstanden?'),
  (
    'fg-10',
    'Wie hätten Sie reagiert, wenn das Ergebnis nicht den Vorgaben entsprochen hätte?',
  ),
];
