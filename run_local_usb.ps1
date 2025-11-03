<#
run_local_usb.ps1

Automatiza los pasos para pruebas locales por USB:
- Añade adb (platform-tools) al PATH de la sesión
- Reinicia adb, lista dispositivos
- Crea adb reverse tcp:8000 -> tcp:8000
- Muestra el estado y sugiere el siguiente paso (abrir 127.0.0.1:8000 en el móvil)
- Opcionalmente ejecuta `flutter run --dart-define=BASE_URL="http://127.0.0.1:8000"`

Uso:
  # Solo comprobar/crear reverse
  .\run_local_usb.ps1

  # Ejecutar y lanzar flutter automáticamente
  .\run_local_usb.ps1 -RunFlutter

Parámetros:
  -AdbPath   Ruta a adb.exe (por defecto se usa la ruta detectada en %LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe)
  -RunFlutter  Si se indica, el script lanzará `flutter run --dart-define=BASE_URL="http://127.0.0.1:8000"` al final.
#>

param(
    [string]$AdbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe",
    [switch]$RunFlutter
)

function Write-Ok($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERR] $msg" -ForegroundColor Red }

Write-Host "== run_local_usb.ps1: preparar adb reverse y opcionalmente ejecutar flutter =="

# 1) Ensure adb exists
if (Test-Path $AdbPath) {
    $adb = $AdbPath
    Write-Ok "Found adb at: $adb"
} else {
    $adb = 'adb'
    Write-Warn "adb not found at default path ($AdbPath). Using 'adb' from PATH. If this fails, set -AdbPath explicitly."
}

# Add platform-tools to PATH for this session if it's the default location
try {
    $pt = Split-Path $AdbPath -Parent
    if (Test-Path $pt) { $env:PATH = "$env:PATH;$pt" }
} catch {}

# 2) Restart adb server and list devices
Write-Host "Restarting adb server..."
& $adb kill-server 2>$null
Start-Sleep -Milliseconds 300
& $adb start-server 2>&1 | ForEach-Object { Write-Host $_ }
Start-Sleep -Milliseconds 300

$devices = & $adb devices 2>&1 | Out-String
Write-Host "\n== adb devices =="
Write-Host $devices

if ($devices -match 'unauthorized') {
    Write-Warn "Device is 'unauthorized'. Please accept the RSA prompt on the phone and re-run this script."
}

if ($devices -notmatch '\bdevice\b') {
    Write-Warn "No device shown as 'device'. Check cable, USB port, and enable USB debugging."
}

# 3) Create reverse
Write-Host "\nRemoving any existing reverse mappings..."
& $adb reverse --remove-all 2>&1 | ForEach-Object { Write-Host $_ }
Start-Sleep -Milliseconds 200
Write-Host "Creating reverse tcp:8000 -> tcp:8000..."
$revOut = & $adb reverse tcp:8000 tcp:8000 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $revOut -match 'error') {
    Write-Err "Failed to create adb reverse. Output:"
    Write-Host $revOut
    Write-Warn "Common causes: device not connected/authorized, cable is charge-only, or adb bug. Try: adb kill-server; adb start-server; check cable."
} else {
    Write-Ok "adb reverse created."
}

Start-Sleep -Milliseconds 200
$revList = & $adb reverse --list 2>&1 | Out-String
Write-Host "\n== adb reverse --list =="
Write-Host $revList

if ($revList -match 'tcp:8000') {
    Write-Ok "Reverse for tcp:8000 present. Open http://127.0.0.1:8000/api/paquetes/ on your phone's browser to verify."
} else {
    Write-Warn "Reverse for tcp:8000 not listed. The device may not be reachable via reverse."
}

# 4) Optional: run flutter
if ($RunFlutter) {
    Write-Host "\nRunning flutter run with BASE_URL=http://127.0.0.1:8000 ..."
    Write-Host "(If you want to stop, press Ctrl+C)" 
    flutter run --dart-define=BASE_URL="http://127.0.0.1:8000"
}

Write-Host "\nDone. If the phone can reach http://127.0.0.1:8000 in the browser, the app should also be able to after launching with that BASE_URL." 
