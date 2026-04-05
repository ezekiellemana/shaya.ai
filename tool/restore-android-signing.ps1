param(
  [string]$BackupPath,
  [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Join-Path $PSScriptRoot ".."
$root = [System.IO.Path]::GetFullPath($root)
$backupStatePath = Join-Path $root "android\.signing-backup.json"

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

if ([string]::IsNullOrWhiteSpace($BackupPath)) {
  if (-not (Test-Path $backupStatePath)) {
    Write-Error "No backup path was provided and android/.signing-backup.json does not exist."
  }

  $backupState = Get-Content $backupStatePath -Raw | ConvertFrom-Json
  $BackupPath = [string]$backupState.backupDirectory
}

if (-not (Test-Path $BackupPath)) {
  Write-Error "Backup path not found: $BackupPath"
}

$backupKeyPropertiesPath = Join-Path $BackupPath "key.properties"
if (-not (Test-Path $backupKeyPropertiesPath)) {
  Write-Error "Backup key.properties not found in $BackupPath"
}

$keyProperties = Get-KeyProperties -Path $backupKeyPropertiesPath
$storeFile = [string]$keyProperties["storeFile"]
if ([string]::IsNullOrWhiteSpace($storeFile)) {
  Write-Error "Backup key.properties is missing storeFile."
}

$backupKeystorePath = Join-Path $BackupPath $storeFile
if (-not (Test-Path $backupKeystorePath)) {
  Write-Error "Backup keystore not found at $backupKeystorePath"
}

$destinationKeyPropertiesPath = Join-Path $root "android\key.properties"
$destinationKeystorePath = Join-Path $root ("android\" + $storeFile)

if (((Test-Path $destinationKeyPropertiesPath) -or (Test-Path $destinationKeystorePath)) -and -not $Force) {
  Write-Error "Signing files already exist locally. Re-run with -Force if you want to replace them."
}

Copy-Item $backupKeyPropertiesPath $destinationKeyPropertiesPath -Force
Copy-Item $backupKeystorePath $destinationKeystorePath -Force

Write-Host "Restored Android signing files:"
Write-Host "- $destinationKeyPropertiesPath"
Write-Host "- $destinationKeystorePath"
