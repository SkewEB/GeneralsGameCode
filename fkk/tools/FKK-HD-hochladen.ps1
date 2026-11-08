# FKK Edition: laedt das HD-Texturpaket (fkk-hd-*.zip) auf den privaten Download-Server.
# Einmalig von Kewe auszufuehren, im Ordner mit den fkk-hd-*.zip:
#
#   powershell -ExecutionPolicy Bypass -File FKK-HD-hochladen.ps1
#
# Ergebnis: FKK-HD.txt auf dem Desktop (Pruefsummen fuer den Installer).

param(
    [string]$UploadUrl = "http://generals.kewekordes.com:8090/upload/"
)
$ErrorActionPreference = "Stop"

$parts = Get-ChildItem -Path $PSScriptRoot -Filter "fkk-hd-*.zip" | Sort-Object Name
if ($parts.Count -eq 0) { throw "Keine fkk-hd-*.zip neben diesem Skript gefunden ($PSScriptRoot)" }

$secure = Read-Host "Upload-Passwort (UPLOAD_PASSWORD aus Coolify)" -AsSecureString
$uploadPw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

$results = @()
$total = 0
foreach ($zip in $parts) {
    $hash = (Get-FileHash -Algorithm SHA256 $zip.FullName).Hash.ToLower()
    $total += $zip.Length
    Write-Host "Lade $($zip.Name) hoch ($([math]::Round($zip.Length / 1MB)) MB) ..."
    # curl schreibt den Fortschritt auf stderr; Erfolg ueber den Exit-Code pruefen
    $ErrorActionPreference = "Continue"
    & curl.exe --fail --show-error --progress-bar -u "upload:$uploadPw" -T $zip.FullName "$UploadUrl$($zip.Name)"
    if ($LASTEXITCODE -ne 0) { throw "Upload fehlgeschlagen fuer $($zip.Name) (curl Code $LASTEXITCODE)" }
    $ErrorActionPreference = "Stop"
    $results += "$($zip.Name) $hash $($zip.Length)"
}

$out = Join-Path ([Environment]::GetFolderPath("Desktop")) "FKK-HD.txt"
@("FKK HD-Texturen $(Get-Date -Format s)", "Gesamt $([math]::Round($total / 1MB)) MB") + $results | Set-Content -Encoding UTF8 $out

Write-Host ""
Get-Content $out
Write-Host ""
Write-Host "Fertig. Bitte den Inhalt von $out an Claude schicken."
