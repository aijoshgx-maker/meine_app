# Release-Checkliste

## Vor jedem Build

- [ ] Version in `pubspec.yaml` erhöht (`versionCode` kommt daraus — Play
      lehnt einen bereits benutzten `versionCode` ab)
- [ ] `dart format lib test` ausgeführt
- [ ] `flutter analyze` ohne Befund
- [ ] `flutter test` grün
- [ ] `dart run tool/validate_fragen.dart` ohne Fehler
- [ ] CHANGELOG ergänzt

## Signatur — der Punkt, an dem es still schiefgeht

`android/app/build.gradle.kts` liest `android/key.properties`. **Fehlt die
Datei, fällt der Build stillschweigend auf den Debug-Key zurück** — damit
`flutter run --release` lokal funktioniert. Ein so gebautes Paket weist Play
zurück, und man sieht es dem AAB nicht an.

- [ ] `android/key.properties` vorhanden
- [ ] Keystore unter dem dort eingetragenen `storeFile` vorhanden
- [ ] Nach dem Build die Signatur **wirklich geprüft**:

```bash
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
AS="$LOCALAPPDATA/Android/Sdk/build-tools/37.0.0/apksigner.bat"
"$AS" verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

Im Zertifikat muss der Inhaber deines Upload-Keystores stehen —
**nicht** `CN=Android Debug`.

> `keytool -printcert -jarfile` meldet hier „Keine signierte JAR-Datei". Das
> ist kein Fehler: Moderne APKs nutzen Signaturschema v2/v3, das keytool
> nicht liest. `apksigner` ist das richtige Werkzeug.

## Release-Build prüfen

- [ ] `flutter build apk --release` erfolgreich
- [ ] **Release-APK auf einem echten Gerät installiert und durchgespielt**
      — R8 entfernt Code, den es für unerreichbar hält; Fehler durch
      Reflexion zeigen sich ausschließlich hier, nie im Debug-Build.
      Mindestens: Quiz mit allen Fragetypen, Kursimport, Backup-Export,
      Erinnerung einschalten
- [ ] Launcher-Icon korrekt, auch im runden Launcher-Stil
- [ ] `flutter build appbundle --release` erfolgreich
- [ ] `flutter build web --release --base-href /meine_app/` erfolgreich
      (in Git Bash `MSYS_NO_PATHCONV=1` voranstellen, sonst wird
      `--base-href` zu einem Windows-Pfad verbogen)

## Vor dem allerersten Upload — einmalig und unwiderruflich

- [ ] **Application-ID festgelegt** und ersetzt in:
      `android/app/build.gradle.kts` (`namespace` + `applicationId`) ·
      `android/app/src/main/kotlin/.../MainActivity.kt` (Ordner **und**
      `package`-Zeile) · `ios/Runner.xcodeproj/project.pbxproj`
      (`PRODUCT_BUNDLE_IDENTIFIER`) · `pubspec.yaml` (`name`)
- [ ] **App-Label** in `android/app/src/main/AndroidManifest.xml` gesetzt
- [ ] Keystore an einem zweiten Ort gesichert — **geht er verloren, lässt
      sich die App nie wieder aktualisieren**
- [ ] Keystore-Zertifikat geprüft (aktuell steht dort `C=49`; korrekt wäre
      ein zweistelliger ISO-Ländercode wie `DE`)

## Play Console

- [ ] Datenschutzerklärung öffentlich erreichbar — sie liegt als
      `web/datenschutz.html` im Repo und geht mit dem Web-Deploy live:
      https://aijoshgx-maker.github.io/meine_app/datenschutz.html
      Diese URL kommt in die Play Console.
- [ ] Data-Safety-Formular ausgefüllt (Antworten in
      `docs/store/store-eintrag.md`)
- [ ] Inhaltsbewertung beantwortet
- [ ] Zielgruppe und Altersfreigabe gesetzt
- [ ] Kurz- und Vollbeschreibung eingetragen
- [ ] Icon 512×512 und Feature-Grafik 1024×500 hochgeladen
      (`assets/branding/`)
- [ ] Mindestens 2 Screenshots je Formfaktor
- [ ] Testkanal bedient — für neue persönliche Entwicklerkonten verlangt
      Google einen geschlossenen Test über mehrere Wochen, bevor die
      Produktion freigegeben wird. Aktuelle Bedingungen im Console prüfen.

## Nach dem Upload

- [ ] `git tag` auf den veröffentlichten Stand gesetzt
- [ ] Keystore-Sicherung noch einmal verifiziert
