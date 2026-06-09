# ════════════════════════════════════════════════════════════════════
#  Flutter Pipeline - Komplett-Setup fuer Windows 11
#  ----------------------------------------------------------------
#  Dieses Skript installiert ALLE benoetigten Werkzeuge fuer die
#  Flutter-App-Pipeline und fuehrt dich Schritt fuer Schritt durch
#  die wenigen manuellen Aktionen.
#
#  Vor dem Start:
#    1. PowerShell ALS ADMINISTRATOR oeffnen
#       (Win + X  ->  "Terminal (Administrator)")
#    2. Einmalig Skriptausfuehrung erlauben:
#       Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#    3. In den Ordner wechseln, in dem dieses Skript liegt, z.B.:
#       cd C:\Users\DEINNAME\pipeline-scripts\pipeline\scripts
#    4. Skript starten:
#       .\00-full-setup.ps1
# ════════════════════════════════════════════════════════════════════

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Fortschrittsbalken abschalten -> macht den grossen Flutter-Download
# um ein Vielfaches schneller.
$ProgressPreference = "SilentlyContinue"


# ─── Hilfsfunktion: PATH der laufenden Sitzung neu laden ───────────────
# Liest System- UND Benutzer-PATH frisch aus der Registry und setzt
# beide zusammen. So werden frisch installierte Tools (Node, VS Code,
# Flutter ...) sofort in DIESER Sitzung gefunden, ohne Neustart.
function Update-PathInSession {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = ($machinePath, $userPath | Where-Object { $_ }) -join ";"
}


# ─── Hilfsfunktion: Pause fuer manuelle Aktionen ───────────────────────
# Zeigt eine deutlich sichtbare Anweisung an und wartet, bis du ENTER
# druckst. So weisst du immer genau, was zu tun ist.
function Wait-ManualStep {
    param([string]$Nachricht)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "  >>> MANUELLE AKTION ERFORDERLICH <<<" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host $Nachricht -ForegroundColor White
    Write-Host ""
    Write-Host "  Wenn du ALLES oben erledigt hast: ENTER druecken." -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Read-Host | Out-Null
}


# ═══════════════════════════════════════════════════════════════
#  Begruessung
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   FLUTTER PIPELINE - KOMPLETT-SETUP                   " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Das Skript installiert alle Werkzeuge automatisch.  " -ForegroundColor Gray
Write-Host "   An 2 Stellen musst du kurz selbst etwas tun -       " -ForegroundColor Gray
Write-Host "   dabei haelt das Skript an und sagt dir genau, was.  " -ForegroundColor Gray
Write-Host "   Geplante Dauer: ca. 20-40 Minuten.                  " -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""


# ───────────────────────────────────────────────────────────────
# [1/7] winget pruefen (Windows-Paketmanager, fuer Installationen noetig)
# ───────────────────────────────────────────────────────────────
Write-Host "[1/7] Pruefe winget (Windows-Paketmanager)..." -ForegroundColor Cyan

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "      FEHLER: winget wurde nicht gefunden." -ForegroundColor Red
    Wait-ManualStep @"
  winget fehlt auf diesem PC und muss zuerst installiert werden:

  1. Oeffne den 'Microsoft Store'
  2. Suche nach:  App Installer
  3. Klicke auf 'Installieren' bzw. 'Aktualisieren'
  4. Schliesse danach PowerShell und starte dieses Skript neu
"@
    throw "winget nicht gefunden. Bitte Skript nach der Installation neu starten."
}

Write-Host "      OK - winget ist vorhanden." -ForegroundColor Green


# ───────────────────────────────────────────────────────────────
# [2/7] Basiswerkzeuge installieren (Git, VS Code, Android Studio, Node.js)
#       Laeuft vollautomatisch.
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/7] Installiere Basiswerkzeuge via winget..." -ForegroundColor Cyan
Write-Host "      Git, VS Code, Android Studio, Google Chrome, Node.js LTS, Notepad++" -ForegroundColor Gray
Write-Host "      Das kann 5-15 Minuten dauern - bitte warten." -ForegroundColor Gray

# Hinweis: winget meldet bei bereits aktuellen Paketen evtl. eine
# rote Zeile ("No applicable update found"). Das ist KEIN Fehler -
# das Skript laeuft normal weiter.
$packages = @(
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Google.AndroidStudio",
    "Google.Chrome",
    "OpenJS.NodeJS.LTS",
    "Notepad++.Notepad++"
)

foreach ($pkg in $packages) {
    Write-Host "      -> $pkg" -ForegroundColor Gray
    # 2>$null unterdrueckt harmlose winget-Fehlermeldungen
    winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements 2>$null
}

# PATH neu laden, damit z.B. 'npm' gleich gefunden wird.
Update-PathInSession
Write-Host "      OK - Basiswerkzeuge installiert." -ForegroundColor Green


# ───────────────────────────────────────────────────────────────
# MANUELLE AKTION 1: Android Studio einrichten
# (Das laedt das Android SDK herunter - laesst sich nicht automatisieren.)
# ───────────────────────────────────────────────────────────────
Wait-ManualStep @"
  Android Studio wurde installiert und muss EINMALIG eingerichtet
  werden, damit das Android SDK heruntergeladen wird:

  1. Oeffne 'Android Studio' (im Startmenue danach suchen)
  2. Klicke dich durch den Setup-Wizard ('Next')
  3. Waehle als Installationstyp:  Standard
  4. Bestaetige und lass alles herunterladen + installieren
  5. Warte, bis das Hauptfenster (Welcome to Android Studio) erscheint
  6. Schliesse Android Studio wieder
"@


# ───────────────────────────────────────────────────────────────
# [3/7] Flutter SDK herunterladen und entpacken
#       Laeuft vollautomatisch nach C:\Users\DEINNAME\sdk\flutter
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/7] Lade Flutter SDK herunter und entpacke es..." -ForegroundColor Cyan
Write-Host "      Download ist ca. 1 GB gross - das dauert ein paar Minuten." -ForegroundColor Gray

$flutterDir = "C:\Users\$env:USERNAME\sdk"
$flutterBin = "$flutterDir\flutter\bin"

if (-not (Test-Path $flutterBin)) {
    try {
        New-Item -ItemType Directory -Force -Path $flutterDir | Out-Null
        $zipPath    = "$flutterDir\flutter.zip"
        $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_stable.zip"

        Write-Host "      -> Lade flutter_windows_stable.zip ..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $flutterUrl -OutFile $zipPath

        Write-Host "      -> Entpacke (kann 1-2 Minuten dauern) ..." -ForegroundColor Gray
        Expand-Archive -Path $zipPath -DestinationPath $flutterDir -Force
        Remove-Item $zipPath

        Write-Host "      OK - Flutter SDK liegt unter: $flutterDir\flutter" -ForegroundColor Green
    } catch {
        Write-Host "      FEHLER beim Flutter-Download: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "      Pruefe deine Internetverbindung und starte das Skript neu." -ForegroundColor Yellow
        throw
    }
} else {
    Write-Host "      Flutter ist bereits vorhanden - Download wird uebersprungen." -ForegroundColor Yellow
}


# ───────────────────────────────────────────────────────────────
# [4/7] PATH-Eintraege dauerhaft setzen
#       Damit flutter, dart, adb, java und keytool ueberall erkannt werden.
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/7] Setze PATH-Eintraege (dauerhaft im Benutzerprofil)..." -ForegroundColor Cyan

$pathsToAdd = @(
    $flutterBin,                                                              # flutter, dart
    "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools",        # adb
    "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\cmdline-tools\latest\bin", # sdkmanager
    "C:\Program Files\Android\Android Studio\jbr\bin"                         # java, keytool
)

# Bestehenden Benutzer-PATH laden (leeren PATH als "" behandeln).
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }

foreach ($p in $pathsToAdd) {
    if ($userPath -notmatch [regex]::Escape($p)) {
        if ($userPath -and -not $userPath.EndsWith(";")) { $userPath += ";" }
        $userPath += $p
        Write-Host "      + Hinzugefuegt: $p" -ForegroundColor Gray
    } else {
        Write-Host "      = Bereits vorhanden: $p" -ForegroundColor DarkGray
    }
}

# Dauerhaft speichern ...
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")
# ... und sofort in dieser Sitzung verfuegbar machen.
Update-PathInSession
Write-Host "      OK - PATH gesetzt." -ForegroundColor Green


# ───────────────────────────────────────────────────────────────
# [5/7] Firebase CLI installieren (ueber npm)
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/7] Installiere Firebase CLI (npm install -g firebase-tools)..." -ForegroundColor Cyan

if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g firebase-tools
    Update-PathInSession
    Write-Host "      OK - Firebase CLI installiert." -ForegroundColor Green
} else {
    Write-Host "      WARNUNG: npm wurde nicht gefunden." -ForegroundColor Yellow
    Write-Host "      Node.js wurde evtl. gerade erst installiert. Loesung:" -ForegroundColor Yellow
    Write-Host "      PowerShell schliessen, neu oeffnen, dann ausfuehren:" -ForegroundColor Yellow
    Write-Host "        npm install -g firebase-tools" -ForegroundColor Yellow
}


# ───────────────────────────────────────────────────────────────
# MANUELLE AKTION 2: Android-Lizenzen akzeptieren
# (Laeuft im SELBEN Fenster, direkt nach dem ENTER.)
# ───────────────────────────────────────────────────────────────
Wait-ManualStep @"
  Gleich werden die Android-SDK-Lizenzen abgefragt. Das passiert
  HIER IM SELBEN FENSTER, direkt nachdem du ENTER druckst.

  Wenn die Frage erscheint
  'Review licenses that have not been accepted (y/N)?'
  -> Tippe:  y   und druecke ENTER
  -> Wiederhole das fuer jede einzelne Lizenz (ca. 5-7 Mal)
  -> Fertig, sobald 'All SDK package licenses accepted.' erscheint
"@

Write-Host ""
Write-Host "[6/7] Akzeptiere Android-Lizenzen..." -ForegroundColor Cyan
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter doctor --android-licenses
} else {
    Write-Host "      WARNUNG: 'flutter' noch nicht im PATH dieser Sitzung." -ForegroundColor Yellow
    Write-Host "      PowerShell neu oeffnen und ausfuehren:" -ForegroundColor Yellow
    Write-Host "        flutter doctor --android-licenses" -ForegroundColor Yellow
}


# ───────────────────────────────────────────────────────────────
# [7/7] Abschlusspruefung - sind alle Werkzeuge da?
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[7/7] Pruefe alle Werkzeuge..." -ForegroundColor Cyan
Write-Host ""

$tools = @("git", "code", "flutter", "dart", "adb", "java", "keytool", "node", "npm", "firebase")
$allOk = $true

foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "      OK    : $tool" -ForegroundColor Green
    } else {
        Write-Host "      FEHLT : $tool" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($allOk) {
    Write-Host "  FERTIG! Alle Werkzeuge sind installiert." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Naechster Schritt - PowerShell EINMAL schliessen und" -ForegroundColor White
    Write-Host "  neu als Administrator oeffnen, dann das Projekt anlegen:" -ForegroundColor White
    Write-Host ""
    Write-Host "    .\02-setup-project-root.ps1   -ProjectName meine_app" -ForegroundColor Yellow
    Write-Host "    .\03-create-flutter-project.ps1 -ProjectName meine_app -Org de.deinname" -ForegroundColor Yellow
    Write-Host "    .\04-init-git-and-open-vscode.ps1 -ProjectName meine_app" -ForegroundColor Yellow
} else {
    Write-Host "  Einige Werkzeuge fehlen noch." -ForegroundColor Red
    Write-Host "  Das ist oft normal: einige Tools brauchen einen Neustart" -ForegroundColor Yellow
    Write-Host "  der PowerShell, um im PATH zu erscheinen." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -> PowerShell schliessen, neu als Administrator oeffnen," -ForegroundColor Yellow
    Write-Host "     und dieses Skript einfach nochmal ausfuehren." -ForegroundColor Yellow
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
