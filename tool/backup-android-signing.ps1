param(
  [string]$DestinationRoot = (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "ShayaAI-Backups")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Join-Path $PSScriptRoot ".."
$root = [System.IO.Path]::GetFullPath($root)

function Get-KeyProperties {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $map = @{}
  foreach ($line in Get-Content $Path) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#") -or -not $line.Contains("=")) {
      continue
    }

    $pair = $line -split "=", 2
    $map[$pair[0].Trim()] = $pair[1].Trim()
  }

  return $map
}

$keyPropertiesPath = Join-Path $root "android\key.properties"
if (-not (Test-Path $keyPropertiesPath)) {
  Write-Error "Missing android/key.properties. Run .\tool\bootstrap-android-signing.ps1 or create your signing config first."
}

$keyProperties = Get-KeyProperties -Path $keyPropertiesPath
$storeFile = [string]$keyProperties["storeFile"]
$keyAlias = [string]$keyProperties["keyAlias"]
$storePassword = [string]$keyProperties["storePassword"]

if ([string]::IsNullOrWhiteSpace($storeFile)) {
  Write-Error "android/key.properties is missing storeFile."
}

$keystorePath = Join-Path $root ("android\" + $storeFile)
if (-not (Test-Path $keystorePath)) {
  Write-Error "Keystore file not found at $keystorePath"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDirectory = Join-Path $DestinationRoot ("AndroidSigning-" + $timestamp)
New-Item -ItemType Directory -Force -Path $backupDirectory | Out-Null

$backupKeyPropertiesPath = Join-Path $backupDirectory "key.properties"
$backupKeystorePath = Join-Path $backupDirectory $storeFile
$fingerprintPath = Join-Path $backupDirectory "keystore-fingerprint.txt"
$readmePath = Join-Path $backupDirectory "README.txt"
$backupStatePath = Join-Path $root "android\.signing-backup.json"

Copy-Item $keyPropertiesPath $backupKeyPropertiesPath -Force
Copy-Item $keystorePath $backupKeystorePath -Force

@"
Keystore fingerprint helper

This backup script does not extract the certificate fingerprint automatically.

If you want to inspect it later, run:
keytool -list -v -keystore "$keystorePath" -alias "$keyAlias"
"@ | Set-Content $fingerprintPath

@"
Shaya AI Android signing backup

Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
Backup directory: $backupDirectory
Store file: $storeFile
Key alias: $keyAlias

Restore on another machine:
1. Copy this whole folder to the new machine.
2. Run:
   .\tool\restore-android-signing.ps1 -BackupPath "$backupDirectory"
3. Build again with:
   flutter build appbundle --release --dart-define-from-file=dart_defines.json

Keep this backup in a safe place. Anyone with these files can publish Android updates for this app.
"@ | Set-Content $readmePath

$backupState = [ordered]@{
  createdAt = (Get-Date).ToString("o")
  backupDirectory = $backupDirectory
  storeFile = $storeFile
  keyAlias = $keyAlias
}
$backupState | ConvertTo-Json | Set-Content $backupStatePath

Write-Host "Created Android signing backup:"
Write-Host "- $backupDirectory"
Write-Host ""
Write-Host "Repo marker updated:"
Write-Host "- $backupStatePath"
