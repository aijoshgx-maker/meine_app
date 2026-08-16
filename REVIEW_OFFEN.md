# Offene fachliche Review-Punkte

Diese Datei sammelt Stellen, an denen laut den globalen Arbeitsregeln aus
`CLAUDE_CODE_PROMPTS.md` **nicht geraten**, sondern zur fachlichen Prüfung
markiert wird (`// TODO-FACHPRÜFUNG`-Äquivalent für JSON-Daten).

---

## P3a — `ft-ws-012`: widersprüchliche Taylor-Konstante entfernt

**Datei:** `assets/fragen/fertigungstechnik_werkzeuge_schneidstoffe.json`

Die Frage nannte ursprünglich `C = 380` zusätzlich zu `m = 0,3` und den
Eckdaten `T = 30 min bei vc = 100 m/min`. Das ist intern widersprüchlich:
Mit der Taylor-Geradengleichung `T = (C/vc)^(1/m)` und C = 380, m = 0,3 ergäbe
sich bei vc = 100 m/min eine Standzeit von `(380/100)^(1/0,3) ≈ 85,6 min`,
nicht die in der Frage vorausgesetzten 30 min.

**Entscheidung für diesen Commit:** `C = 380` ersatzlos aus dem Fragetext
gestrichen, da die reine Verhältnisformel `T2 = T1 · (vc1/vc2)^(1/m)` sie
nicht benötigt (P3-Vorgabe: „C und m aus der Frage streichen, die
Verhältnisformel braucht sie nicht"). `loesungswert`/`toleranz` auf
`9.8`/`0.3` korrigiert (nachgerechnet: `30 · (100/140)^(1/0,3) ≈ 9,77 min`).

**Offen:** Ob `C = 380` ursprünglich mit einem *anderen* Vergleichspunkt
konsistent gemeint war (z. B. anderer vc-Wert), lässt sich ohne die
ursprüngliche Quelle der Frage nicht rekonstruieren. Fachliche Prüfung
erwünscht, falls die Konstante an anderer Stelle noch referenziert wird.

---
