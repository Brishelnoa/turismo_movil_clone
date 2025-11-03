<#
backend_mobile_check.ps1

Ejecuta comprobaciones básicas contra el backend Django y verifica adb.
Guarda los resultados en backend_mobile_check_results.txt en el directorio actual.

Uso:
  .\backend_mobile_check.ps1 -BaseUrl 'http://192.168.0.6:8000' -Email 'juan@mail.com' -Password 'miClaveSegura123'

#>

param(
    [string]$BaseUrl = 'http://192.168.0.6:8000',
    [string]$AdbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe",
    [string]$Email = 'juan@mail.com',
    [string]$Password = 'miClaveSegura123',
    [string]$OutFile = 'backend_mobile_check_results.txt'
)

function Log { param($title, $content)
    Add-Content -Path $global:OutPath -Value "=== $title ==="
    if ($null -ne $content) { Add-Content -Path $global:OutPath -Value $content }
    Add-Content -Path $global:OutPath -Value "`n"
}

$global:OutPath = Join-Path -Path (Get-Location) -ChildPath $OutFile
Remove-Item -Path $global:OutPath -ErrorAction SilentlyContinue
Log "Run" "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log "Config" "BaseUrl=$BaseUrl`nAdbPath=$AdbPath`nEmail=$Email"

## 1) Root
try {
    $r = Invoke-WebRequest -Uri $BaseUrl -Method Get -UseBasicParsing -ErrorAction Stop
    Log "Root Status" "$($r.StatusCode)"
    Log "Root Body" ($r.Content.Substring(0, [Math]::Min(1000, $r.Content.Length)))
} catch {
    Log "Root Error" $_.Exception.Message
}

## 2) GET /api/paquetes/
$urlPaquetes = "$BaseUrl/api/paquetes/"
try {
    $r = Invoke-WebRequest -Uri $urlPaquetes -Method Get -UseBasicParsing -ErrorAction Stop
    Log "Paquetes Status" "$($r.StatusCode)"
    Log "Paquetes Body (truncated 2000)" ($r.Content.Substring(0, [Math]::Min(2000, $r.Content.Length)))
} catch {
    Log "Paquetes Error" $_.Exception.Message
}

## 3) POST /api/login/ (obtener token)
$loginUrl = "$BaseUrl/api/login/"
$body = @{ email = $Email; password = $Password } | ConvertTo-Json
try {
    $resp = Invoke-RestMethod -Uri $loginUrl -Method Post -Body $body -ContentType 'application/json' -ErrorAction Stop
    Log "Login Response JSON" ($resp | ConvertTo-Json -Depth 5)
    if ($resp.token) { $token = $resp.token; Log "Login Token" $token } else { Log "Login Token" "(no token field in response)" }
} catch {
    # Mostrar detalles de error si es posible
    Log "Login Error" $_.Exception.Message
    if ($_.Exception.Response -ne $null) {
        try { $text = $_.Exception.Response.GetResponseStream(); $sr = New-Object System.IO.StreamReader($text); $bodyText = $sr.ReadToEnd(); Log "Login Error Body" $bodyText } catch {} }
}

## 4) GET protegido /api/users/me/ usando token
if ($null -ne $token) {
    $meUrl = "$BaseUrl/api/users/me/"
    try {
        $h = @{ Authorization = "Token $token" }
        $r = Invoke-RestMethod -Uri $meUrl -Method Get -Headers $h -ErrorAction Stop
        Log "Users Me Response" ($r | ConvertTo-Json -Depth 5)
    } catch {
        Log "Users Me Error" $_.Exception.Message
    }
} else {
    Log "Users Me" "Skipped because no token was obtained from login."
}

## 5) OPTIONS preflight CORS
try {
    $opts = Invoke-WebRequest -Uri $urlPaquetes -Method Options -Headers @{ Origin = 'http://localhost:8080'; 'Access-Control-Request-Method' = 'GET' } -UseBasicParsing -ErrorAction Stop
    # Mostrar cabeceras relevantes
    $allowOrigin = $opts.Headers['Access-Control-Allow-Origin']
    $allowMethods = $opts.Headers['Access-Control-Allow-Methods']
    Log "CORS Headers" "Access-Control-Allow-Origin: $allowOrigin`nAccess-Control-Allow-Methods: $allowMethods`nFull-Headers: $($opts.Headers | Out-String)"
} catch {
    Log "CORS Error" $_.Exception.Message
}

## 6) ADB checks
try {
    if (Test-Path $AdbPath) { $adb = $AdbPath } else { $adb = 'adb' }
    Log "ADB Used" $adb
    try {
        $devices = & $adb devices 2>&1 | Out-String
        Log "ADB devices" $devices
    } catch { Log "ADB devices error" $_.Exception.Message }

    try {
        $rev = & $adb reverse --list 2>&1 | Out-String
        Log "ADB reverse --list" $rev
    } catch { Log "ADB reverse list error" $_.Exception.Message }
} catch {
    Log "ADB Error" $_.Exception.Message
}

## Final notes
Log "Next Steps" "Si usas adb reverse y está activo, abre en el teléfono: http://127.0.0.1:8000/api/paquetes/ o ejecuta la app con --dart-define=BASE_URL=\"http://127.0.0.1:8000\""

Write-Output "Comprobación completada. Resultado guardado en: $global:OutPath"
