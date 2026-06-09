# Flutter Pipeline - Setup-Anleitung

Dieses Repository enthält alle Skripte für die Flutter-App-Pipeline unter Windows 11 mit Git, VS Code, Android Studio, Firebase und GitHub Actions.

---

## Schnellstart auf einem neuen PC

### 1. PowerShell als Administrator öffnen

**Win + X** → "Terminal (Administrator)" auswählen.

### 2. Skriptausführung einmalig erlauben

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Mit `J` oder `Y` bestätigen.

### 3. In den Scripts-Ordner wechseln

```powershell
cd C:\Projects\app-pipe\scripts
```

### 4. Komplett-Setup starten

```powershell
.\00-full-setup.ps1
```

Das Skript installiert automatisch:

- Git
- VS Code
- Android Studio
- Google Chrome
- Node.js LTS
- Notepad++
- Flutter SDK
- Firebase CLI

An **2 Stellen** wird das Skript pausieren und dich zu einer kurzen manuellen Aktion auffordern (Android Studio einrichten + Lizenzen akzeptieren). Folge einfach den Anweisungen auf dem Bildschirm.

---

## Projekt anlegen (nach dem Setup)

PowerShell neu öffnen (als Administrator), dann:

```powershell
cd C:\Projects\app-pipe\scripts

.\02-setup-project-root.ps1   -ProjectName app-pipe
.\03-create-flutter-project.ps1 -ProjectName app-pipe -Org de.joshgx
.\04-init-git-and-open-vscode.ps1 -ProjectName app-pipe
.\05-flutter-doctor.ps1         -ProjectName app-pipe
.\06-local-quality-checks.ps1   -ProjectName app-pipe
.\07-build-debug-apk.ps1        -ProjectName app-pipe
```

---

## Release bauen

```powershell
.\08-generate-upload-keystore.ps1  -ProjectName app-pipe
.\09-configure-android-signing.ps1 -ProjectName app-pipe
.\10-build-release-apk.ps1         -ProjectName app-pipe
.\11-build-release-aab.ps1         -ProjectName app-pipe
```

> ⚠️ Die Datei `upload-keystore.jks` niemals in Git committen und sicher sichern (z.B. USB-Stick oder OneDrive).

---

## Firebase Testbuild verteilen

```powershell
.\13-firebase-login.ps1
.\14-firebase-distribute-apk.ps1 -ProjectName app-pipe -FirebaseAppId "DEINE_APP_ID" -Groups "tester"
```

---

## GitHub Actions (CI/CD)

Die Workflows liegen unter `.github/workflows/`:

| Datei | Auslöser | Was passiert |
|---|---|---|
| `android-ci.yml` | Push / Pull Request auf `main`, `develop` | Format, Analyze, Test, Debug APK |
| `android-beta.yml` | Tag `v*.*.*` oder manuell | Release APK signiert bauen |
| `android-play-aab.yml` | Manuell | AAB für Google Play bauen |

### GitHub Secrets einrichten

Im GitHub-Repository unter **Settings → Secrets → Actions** folgende Secrets anlegen:

| Secret | Inhalt |
|---|---|
| `KEYSTORE_BASE64` | Inhalt von `keystore_base64.txt` |
| `KEY_PROPERTIES` | Inhalt von `android/key.properties` |
| `FIREBASE_APP_ID` | Firebase App ID |
| `FIREBASE_TOKEN` | Firebase CI Token |

Keystore als Base64 erzeugen:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Content -Encoding ASCII keystore_base64.txt
```

---

## Release-Tag erstellen (löst Beta-Workflow aus)

```powershell
.\scripts\16-create-release-tag.ps1 -ProjectName app-pipe -Version v1.0.0
```

---

## Was niemals in Git darf

```
*.jks
*.keystore
android/key.properties
keystore_base64.txt
.env
```

Vor jedem Commit prüfen:

```powershell
git status
```

---

## Häufige Befehle

```powershell
flutter doctor          # Umgebung prüfen
flutter pub get         # Abhängigkeiten laden
flutter run             # App starten
dart format .           # Code formatieren
flutter analyze         # Code analysieren
flutter test            # Tests ausführen
flutter build apk --debug     # Debug APK
flutter build apk --release   # Release APK
flutter build appbundle --release  # AAB für Play Store
```

---

## Nächste Ausbaustufen

- Firebase Crashlytics einbinden
- App Icons automatisieren
- Flavor-Struktur für dev / staging / prod
- Automatische Versionierung
- Automatischer Upload zu Google Play
- Integration Tests auf Emulatoren
- Code Coverage
- Branch Protection in GitHub
