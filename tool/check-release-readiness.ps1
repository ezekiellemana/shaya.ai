$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Join-Path $PSScriptRoot ".."
$root = [System.IO.Path]::GetFullPath($root)

function Write-Status {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [Parameter(Mandatory = $true)]
    [bool]$Ok,
    [string]$Prefix = "",
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if ($Ok) {
    $Prefix = "[OK]"
  } elseif ([string]::IsNullOrWhiteSpace($Prefix)) {
    $Prefix = "[TODO]"
  }

  Write-Host "$Prefix $Label - $Message"
}

function Get-FileText {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    return ""
  }

  return Get-Content $Path -Raw
}

function Get-PubspecVersion {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    return $null
  }

  $match = Select-String -Path $Path -Pattern '^version:\s*(.+)$'
  if ($null -eq $match) {
    return $null
  }

  return $match.Matches[0].Groups[1].Value.Trim()
}

function Get-KeyProperties {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $map = @{}
  if (-not (Test-Path $Path)) {
    return $map
  }

  foreach ($line in Get-Content $Path) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#") -or -not $line.Contains("=")) {
      continue
    }

    $pair = $line -split "=", 2
    $map[$pair[0].Trim()] = $pair[1].Trim()
  }

  return $map
}

function Get-BackupState {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    return $null
  }

  try {
    return Get-Content $Path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

Write-Host "Shaya AI release readiness check"
Write-Host ""

$pubspecPath = Join-Path $root "pubspec.yaml"
$androidGradlePath = Join-Path $root "android\app\build.gradle.kts"
$androidManifestPath = Join-Path $root "android\app\src\main\AndroidManifest.xml"
$iosPbxprojPath = Join-Path $root "ios\Runner.xcodeproj\project.pbxproj"
$iosInfoPlistPath = Join-Path $root "ios\Runner\Info.plist"
$keyPropertiesExamplePath = Join-Path $root "android\key.properties.example"
$keyPropertiesPath = Join-Path $root "android\key.properties"
$backupStatePath = Join-Path $root "android\.signing-backup.json"
$releaseApkPath = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
$adaptiveIconPath = Join-Path $root "android\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml"
$adaptiveRoundIconPath = Join-Path $root "android\app\src\main\res\mipmap-anydpi-v26\ic_launcher_round.xml"
$photoUsageKey = "<key>NSPhotoLibraryUsageDescription</key>"

$pubspecVersion = Get-PubspecVersion -Path $pubspecPath
$androidGradle = Get-FileText -Path $androidGradlePath
$androidManifest = Get-FileText -Path $androidManifestPath
$iosPbxproj = Get-FileText -Path $iosPbxprojPath
$iosInfoPlist = Get-FileText -Path $iosInfoPlistPath

$androidPackageOk =
  $androidGradle.Contains('namespace = "com.shayaai.app"') -and
  $androidGradle.Contains('applicationId = "com.shayaai.app"')
$iosBundleOk =
  $iosPbxproj.Contains("PRODUCT_BUNDLE_IDENTIFIER = com.shayaai.app;")
$iosPhotoUsageOk = $iosInfoPlist.Contains($photoUsageKey)
$adaptiveIconsOk = (Test-Path $adaptiveIconPath) -and (Test-Path $adaptiveRoundIconPath)
$roundIconManifestOk = $androidManifest.Contains('android:roundIcon="@mipmap/ic_launcher_round"')
$releaseApkOk = Test-Path $releaseApkPath
$versionReady = -not [string]::IsNullOrWhiteSpace($pubspecVersion) -and -not $pubspecVersion.StartsWith("0.")

Write-Status -Label "Pubspec version" -Ok $versionReady -Message "Current version: $pubspecVersion. Move off 0.x before public store submission."
Write-Status -Label "Android package" -Ok $androidPackageOk -Message "Expect namespace and applicationId to use com.shayaai.app."
Write-Status -Label "Android adaptive icons" -Ok ($adaptiveIconsOk -and $roundIconManifestOk) -Message "Adaptive icon XML and round icon manifest entry are in place."
Write-Status -Label "iOS bundle identifier" -Ok $iosBundleOk -Message "Expect iOS bundle IDs to use com.shayaai.app."
Write-Status -Label "iOS photo usage text" -Ok $iosPhotoUsageOk -Message "Profile photo picking requires NSPhotoLibraryUsageDescription."
Write-Status -Label "Release APK" -Ok $releaseApkOk -Message "Run flutter build apk --release --dart-define-from-file=dart_defines.json at least once before handoff."

$hasKeyPropertiesExample = Test-Path $keyPropertiesExamplePath
Write-Status -Label "Android signing template" -Ok $hasKeyPropertiesExample -Message "android/key.properties.example should exist for keystore setup."

if (Test-Path $keyPropertiesPath) {
  $keyProperties = Get-KeyProperties -Path $keyPropertiesPath
  $storeFileValue = [string]$keyProperties["storeFile"]
  $storeFilePath = if ([string]::IsNullOrWhiteSpace($storeFileValue)) {
    $null
  } else {
    Join-Path $root ("android\" + $storeFileValue)
  }
  $hasSigningValues =
    -not [string]::IsNullOrWhiteSpace([string]$keyProperties["storePassword"]) -and
    -not [string]::IsNullOrWhiteSpace([string]$keyProperties["keyPassword"]) -and
    -not [string]::IsNullOrWhiteSpace([string]$keyProperties["keyAlias"]) -and
    -not [string]::IsNullOrWhiteSpace($storeFileValue)
  $hasKeystoreFile = $null -ne $storeFilePath -and (Test-Path $storeFilePath)

  Write-Status -Label "Android signing config" -Ok $hasSigningValues -Message "android/key.properties is present."
  Write-Status -Label "Android keystore file" -Ok $hasKeystoreFile -Message "Expected keystore path: $storeFileValue"
} else {
  Write-Status -Label "Android signing config" -Ok $false -Message "Copy android/key.properties.example to android/key.properties before store submission."
}

$backupState = Get-BackupState -Path $backupStatePath
if ($null -ne $backupState) {
  $backupDirectory = [string]$backupState.backupDirectory
  $backupCreatedAt = [string]$backupState.createdAt
  $backupStoreFile = [string]$backupState.storeFile
  $backupConfigExists = -not [string]::IsNullOrWhiteSpace($backupDirectory) -and (Test-Path (Join-Path $backupDirectory "key.properties"))
  $backupStoreExists = -not [string]::IsNullOrWhiteSpace($backupDirectory) -and -not [string]::IsNullOrWhiteSpace($backupStoreFile) -and (Test-Path (Join-Path $backupDirectory $backupStoreFile))
  Write-Status -Label "Android signing backup" -Ok ($backupConfigExists -and $backupStoreExists) -Message "Latest backup: $backupCreatedAt"
} else {
  Write-Status -Label "Android signing backup" -Ok $false -Message "Run .\tool\backup-android-signing.ps1 after generating your keystore."
}

Write-Host "[INFO] Google platform files - Not required for the current Supabase OAuth flow. Only add GoogleService-Info.plist or google-services.json if you later switch to native Google/Firebase setup."
Write-Status -Label "Apple signing" -Ok $false -Prefix "[LATER]" -Message "Needs Xcode team provisioning and archive validation on macOS."

Write-Host ""
Write-Host "Next steps"
Write-Host "1. Run docs/02-release-prep.md."
Write-Host "2. Use .\tool\backup-android-signing.ps1 after generating or replacing Android signing files."
Write-Host "3. Verify iOS signing and archive on a Mac."
