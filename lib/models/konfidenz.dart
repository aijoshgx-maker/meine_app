// Selbsteinschätzung der Sicherheit, abgefragt vor dem Aufdecken einer
// Antwort (Prinzip: Metakognition & Konfidenz-Kalibrierung). Eigenes Modell
// statt Teil der Quiz-Feature-Schicht, da auch die Datenschicht
// (AttemptHistoryStore) darauf angewiesen ist.
enum Konfidenz { sicher, unsicher, geraten }
