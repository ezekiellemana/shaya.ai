$ErrorActionPreference = "Stop"

$root = Join-Path $PSScriptRoot ".."
$root = [System.IO.Path]::GetFullPath($root)

function Get-CommandStatus {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

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

  Write-Host "$prefix $Label - $Message"
}

function Test-RequiredValue {
  param(
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [string]$Value,
    [Parameter(Mandatory = $true)]
    [string]$Placeholder
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $false
  }

  return $Value -ne $Placeholder
}

Write-Host "Shaya AI setup check"
Write-Host ""

$hasFlutter = Get-CommandStatus -Name "flutter"
$hasSupabase = Get-CommandStatus -Name "supabase"
$hasDocker = Get-CommandStatus -Name "docker"
$flutterMessage = "Install Flutter before running the app."
$supabaseMessage = "Install Supabase CLI before deploying backend changes."
$dockerMessage = "Optional for hosted Supabase. Required for local Supabase."

if ($hasFlutter) {
  $flutterMessage = "Installed"
}

if ($hasSupabase) {
  $supabaseMessage = "Installed"
}

if ($hasDocker) {
  $dockerMessage = "Installed for local Supabase."
}

Write-Status -Label "Flutter" -Ok $hasFlutter -Message $flutterMessage
Write-Status -Label "Supabase CLI" -Ok $hasSupabase -Message $supabaseMessage
Write-Status -Label "Docker" -Ok $hasDocker -Message $dockerMessage

$dartDefinesPath = Join-Path $root "dart_defines.json"
$functionsEnvPath = Join-Path $root "supabase\.env.local"

if (Test-Path $dartDefinesPath) {
  $dartDefines = Get-Content $dartDefinesPath -Raw | ConvertFrom-Json

  Write-Status -Label "dart_defines.json" -Ok $true -Message "Found."
  Write-Status -Label "App URL" -Ok (Test-RequiredValue -Value $dartDefines.SHAYA_SUPABASE_URL -Placeholder "https://YOUR_PROJECT_REF.supabase.co") -Message "Set SHAYA_SUPABASE_URL."
  Write-Status -Label "Anon key" -Ok (Test-RequiredValue -Value $dartDefines.SHAYA_SUPABASE_ANON_KEY -Placeholder "YOUR_SUPABASE_ANON_KEY") -Message "Set SHAYA_SUPABASE_ANON_KEY."
  Write-Status -Label "OAuth redirect" -Ok (-not [string]::IsNullOrWhiteSpace($dartDefines.SHAYA_OAUTH_REDIRECT_URL)) -Message "Set SHAYA_OAUTH_REDIRECT_URL."
  Write-Status -Label "Reset redirect" -Ok (-not [string]::IsNullOrWhiteSpace($dartDefines.SHAYA_PASSWORD_RESET_REDIRECT_URL)) -Message "Set SHAYA_PASSWORD_RESET_REDIRECT_URL."
} else {
  Write-Status -Label "dart_defines.json" -Ok $false -Message "Copy dart_defines.example.json to dart_defines.json and fill it in."
}

if (Test-Path $functionsEnvPath) {
  $envLines = Get-Content $functionsEnvPath
  $envMap = @{}

  foreach ($line in $envLines) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#") -or -not $line.Contains("=")) {
      continue
    }

    $pair = $line -split "=", 2
    $envMap[$pair[0]] = $pair[1]
  }

  Write-Status -Label "supabase/.env.local" -Ok $true -Message "Found."
  Write-Status -Label "Service role key" -Ok (Test-RequiredValue -Value ([string]$envMap["SUPABASE_SERVICE_ROLE_KEY"]) -Placeholder "YOUR_SERVICE_ROLE_KEY") -Message "Set SUPABASE_SERVICE_ROLE_KEY."
  Write-Status -Label "Anthropic key" -Ok (Test-RequiredValue -Value ([string]$envMap["ANTHROPIC_API_KEY"]) -Placeholder "YOUR_ANTHROPIC_KEY") -Prefix "[LATER]" -Message "Needed when you start testing lyrics or prompt refinement."
  Write-Status -Label "Udio key" -Ok (Test-RequiredValue -Value ([string]$envMap["UDIO_API_KEY"]) -Placeholder "YOUR_UDIO_KEY") -Prefix "[LATER]" -Message "Needed when you start testing music generation."
  Write-Status -Label "Kling key" -Ok (Test-RequiredValue -Value ([string]$envMap["KLING_API_KEY"]) -Placeholder "YOUR_KLING_KEY") -Prefix "[LATER]" -Message "Needed when you start testing video generation."
  Write-Status -Label "Apple shared secret" -Ok (Test-RequiredValue -Value ([string]$envMap["APPLE_SHARED_SECRET"]) -Placeholder "YOUR_APPLE_SHARED_SECRET") -Prefix "[LATER]" -Message "Needed when you start testing Apple subscription verification."
  Write-Status -Label "Google Play access token" -Ok (Test-RequiredValue -Value ([string]$envMap["GOOGLE_PLAY_ACCESS_TOKEN"]) -Placeholder "YOUR_GOOGLE_PLAY_ACCESS_TOKEN") -Prefix "[LATER]" -Message "Needed when you start testing Google Play subscription verification."
} else {
  Write-Status -Label "supabase/.env.local" -Ok $false -Message "Copy supabase/.env.example to supabase/.env.local and fill it in."
}

Write-Host ""
Write-Host "Next steps"
Write-Host "1. Fix any [TODO] items above."
Write-Host "2. Run .\\tool\\run-dev.ps1 for the app."
Write-Host "3. Use .\\tool\\deploy-hosted.ps1 -ProjectRef <your-project-ref> for hosted Supabase."
