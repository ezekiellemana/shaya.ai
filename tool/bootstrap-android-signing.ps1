param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Join-Path $PSScriptRoot ".."
$root = [System.IO.Path]::GetFullPath($root)

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if ($null -eq $keytool) {
  Write-Error "keytool is not installed or not on PATH. Install a JDK before bootstrapping Android signing."
}

$keystorePath = Join-Path $root "android\upload-keystore.jks"
$keyPropertiesPath = Join-Path $root "android\key.properties"
$alias = "upload"

if (((Test-Path $keystorePath) -or (Test-Path $keyPropertiesPath)) -and -not $Force) {
  Write-Error "Android signing files already exist. Re-run with -Force if you intentionally want to replace them."
}

if ($Force) {
  if (Test-Path $keystorePath) {
    Remove-Item $keystorePath -Force
  }
  if (Test-Path $keyPropertiesPath) {
    Remove-Item $keyPropertiesPath -Force
  }
}

function New-Password {
  param(
    [int]$Length = 24
  )

  $alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@$%*_-+="
  $chars = for ($i = 0; $i -lt $Length; $i++) {
    $alphabet[(Get-Random -Minimum 0 -Maximum $alphabet.Length)]
  }
  return -join $chars
}

$storePassword = New-Password
$keyPassword = New-Password
$dname = "CN=Shaya AI, OU=Mobile, O=Shaya AI, L=Dar es Salaam, ST=Dar es Salaam, C=TZ"

& $keytool.Source `
  -genkeypair `
  -v `
  -keystore $keystorePath `
  -storetype JKS `
  -storepass $storePassword `
  -keypass $keyPassword `
  -alias $alias `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -dname $dname | Out-Null

@"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$alias
storeFile=upload-keystore.jks
"@ | Set-Content $keyPropertiesPath -NoNewline

Write-Host "Created android signing files:"
Write-Host "- $keystorePath"
Write-Host "- $keyPropertiesPath"
Write-Host ""
Write-Host "These files are gitignored. Keep them safe."
