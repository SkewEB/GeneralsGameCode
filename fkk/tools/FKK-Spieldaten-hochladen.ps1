# FKK Edition: packt die Spieldaten (Zero Hour + Generals) von diesem PC und
# laedt sie auf den privaten Download-Server. Einmalig von Kewe auszufuehren.
#
#   powershell -ExecutionPolicy Bypass -File FKK-Spieldaten-hochladen.ps1
#
# Ergebnis: FKK-Spieldaten.txt auf dem Desktop (Pruefsummen fuer den Installer).

param(
    [string]$UploadUrl = "http://generals.kewekordes.com:8090/upload/"
)
$ErrorActionPreference = "Stop"

function Get-RegValue($path, $name) {
    try { return (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name } catch { return $null }
}

$zhKey  = "HKLM:\SOFTWARE\WOW6432Node\Electronic Arts\EA Games\Command and Conquer Generals Zero Hour"
$genKey = "HKLM:\SOFTWARE\WOW6432Node\Electronic Arts\EA Games\Generals"

$zhDir  = Get-RegValue $zhKey "InstallPath"
$genDir = Get-RegValue $genKey "InstallPath"
if (-not $zhDir  -or -not (Test-Path (Join-Path $zhDir "INIZH.big"))) { $zhDir  = Read-Host "Zero-Hour-Ordner (mit INIZH.big)" }
if (-not $genDir -or -not (Test-Path (Join-Path $genDir "INI.big")))  { $genDir = Read-Host "Generals-Ordner (mit INI.big)" }
if (-not (Test-Path (Join-Path $zhDir "INIZH.big"))) { throw "INIZH.big nicht gefunden in $zhDir" }
if (-not (Test-Path (Join-Path $genDir "INI.big")))  { throw "INI.big nicht gefunden in $genDir" }

$language = Get-RegValue $zhKey "Language"; if (-not $language) { $language = "german" }
$version  = Get-RegValue $zhKey "Version";  if (-not $version)  { $version = 65540 }

$secure = Read-Host "Upload-Passwort (UPLOAD_PASSWORD aus Coolify)" -AsSecureString
$uploadPw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

$work = Join-Path $env:TEMP "fkk-spieldaten"
New-Item -ItemType Directory -Force $work | Out-Null

# FKK-Dateien und Installer-Reste nicht mitpacken (kommen aus dem Installer)
$exclude = @("generalszh.exe", "generalszh.exe.original", "FKK-Starter.exe", "fkk-version.txt", "fkk.ico",
             "fkk-uninstall", "*.pdb", "unins*", "FKKLogo.tga")
$excludeArgs = @(); foreach ($e in $exclude) { $excludeArgs += "--exclude"; $excludeArgs += $e }

$tar = "$env:WINDIR\System32\tar.exe"
$results = @()
foreach ($item in @(@{ Name = "fkk-zh.zip"; Dir = $zhDir }, @{ Name = "fkk-generals.zip"; Dir = $genDir })) {
    $zip = Join-Path $work $item.Name
    # Windows PowerShell wertet jede Ausgabe von tar/curl auf stderr (Fortschritt)
    # sonst als Fehler; Erfolg pruefen wir ueber den Exit-Code.
    $ErrorActionPreference = "Continue"
    if (Test-Path $zip) {
        Write-Host "$($item.Name) ist schon gepackt, nehme das vorhandene Archiv."
    } else {
        Write-Host "Packe $($item.Dir) -> $($item.Name) ..."
        & $tar -a -c -f "$zip.part" @excludeArgs -C $item.Dir .
        if ($LASTEXITCODE -ne 0) { throw "tar fehlgeschlagen fuer $($item.Name)" }
        Move-Item "$zip.part" $zip
    }

    $hash = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower()
    $size = (Get-Item $zip).Length

    Write-Host "Lade $($item.Name) hoch ($([math]::Round($size / 1MB)) MB) ..."
    & curl.exe --fail --show-error --progress-bar -u "upload:$uploadPw" -T $zip "$UploadUrl$($item.Name)"
    if ($LASTEXITCODE -ne 0) { throw "Upload fehlgeschlagen fuer $($item.Name) (curl Code $LASTEXITCODE)" }
    $ErrorActionPreference = "Stop"

    $results += "$($item.Name) $hash $size"
}

$out = Join-Path ([Environment]::GetFolderPath("Desktop")) "FKK-Spieldaten.txt"
@("FKK Spieldaten $(Get-Date -Format s)", "Language $language", "Version $version") + $results | Set-Content -Encoding UTF8 $out
Remove-Item -Recurse -Force $work

Write-Host ""
Get-Content $out
Write-Host ""
Write-Host "Fertig. Bitte den Inhalt von $out an Claude schicken."
